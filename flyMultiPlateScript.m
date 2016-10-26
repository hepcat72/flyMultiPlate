choice = questdlg('Clearing workspace. Are you sure you want to do this?','Warning',...
                  'Yes','No','No');
if strcmp(choice, 'No')
    return;
end
clear;

%% experiment parameters
experimentLength             = 259200; % Length of the trial in seconds
refStackSize                 = 11;     % Number of reference images
refStackUpdateTiming         = 10;     % How often to update a ref image, in secs
writeToFileTiming            = 60;     % How often to write out data
wellToWellSpacing_mm         = 8;      % distance between wells in mm
probableDeathTime_sec        = 30;     % time to mark NaNs as probable death evnt
pauseBetweenAcquisitions_sec = 0.01;   % pause between subsequent images

%fly position extraction parameters
trackingThreshold = 5;                 % higher # = smaller regs detected as diff

%% initialization
[user sys]     = memory;
initialMemory  = user.MemUsedMATLAB;
usageTiming    = 60;
lastUsageTime  = 0;
lastTrashDay   = 0;
trashDayTiming = 86400;                % Collect the trash once a day

close all;
%clear refStack;
%clear refImage;
%clear outCentroids;
%clear outCentroidsSizeTemp;
%clear outDisplacements;
%clear tElapsed;

%% Select the camera(s) to use
nCamsToUse  = 1;
selectedCam = 1;
numImCols   = 1;
camsInfo    = imaqhwinfo('pointgrey');
cams        = camsInfo.DeviceIDs;
camsToUse   = [selectedCam];
if numel(cams) > 1
    nCamsToUse = getNumListDialog('How many cameras in this experiment?',...
                                  1:numel(cams));
    if nCamsToUse < numel(cams)
        camsToUse   = [];
        for nextCam = 1:nCamsToUse
            ok = 0;
            while ok == 0
                [selection ok] = listdlg('PromptString','Select a PointGrey camera',...
                                         'SelectionMode','single',...
                                         'InitialValue',selectedCam,...
                                         'ListString',cellfun(@num2str,cams)');
            end
            selectedCam = cams{1,selection}; %I think this is correct - Sudarshan has the version that is definitely correct.  This was from memory.
            camsToUse = [camsToUse selectedCam];
        end
    else
        camsToUse = 1:nCamsToUse;
    end
end

%% Prepare the camera
imaqreset;

tic;
counter  = 1;
tElapsed = 0;
tc       = 1;
    
[fileName, pathName] = uiputfile([datestr(now,'yyyymmdd-HHMMSS'),'.csv']);
for camIdx = 1:nCamsToUse
    fileNameCentroidPosition{camIdx} = strrep(fileName,'.csv',['-cam',num2str(camsToUse(camIdx)),'centroidPos.csv']);
    fileNameCentroidSize{camIdx}     = strrep(fileName,'.csv',['-cam',num2str(camsToUse(camIdx)),'centroidSize.csv']);
    fileNameInstantSpeed{camIdx}     = strrep(fileName,'.csv',['-cam',num2str(camsToUse(camIdx)),'instantSpeed.csv']);
    fileNameDispTravel{camIdx}       = strrep(fileName,'.csv',['-cam',num2str(camsToUse(camIdx)),'displacementTravel.csv']);
    fileNameTotalDistTravel{camIdx}  = strrep(fileName,'.csv',['-cam',num2str(camsToUse(camIdx)),'totalDistTravel.csv']);
    fileNameProbableDeath{camIdx}    = strrep(fileName,'.csv',['-cam',num2str(camsToUse(camIdx)),'probableDeath.csv']);

    %% get file ready for writing
    fidA{camIdx} = fopen(fullfile(pathName,fileNameCentroidPosition{camIdx}),'w'); % done
    fidB{camIdx} = fopen(fullfile(pathName,fileNameCentroidSize{camIdx}),    'w'); % needs testing
    fidC{camIdx} = fopen(fullfile(pathName,fileNameInstantSpeed{camIdx}),    'w'); % needs testing
    fidD{camIdx} = fopen(fullfile(pathName,fileNameDispTravel{camIdx}),      'w'); % needs testing
    fidE{camIdx} = fopen(fullfile(pathName,fileNameTotalDistTravel{camIdx}), 'w'); % needs testing
    fidF{camIdx} = fopen(fullfile(pathName,fileNameProbableDeath{camIdx}),   'w'); % needs thought
    
    fprintf(fidA{camIdx},'time_sec,');
    fprintf(fidB{camIdx},'time_sec,');
    fprintf(fidC{camIdx},'time_sec,');
    fprintf(fidD{camIdx},'time_sec,');
    fprintf(fidE{camIdx},'time_sec,');
    fprintf(fidF{camIdx},'time_sec,');
end
fileNameMemUsage = strrep(fileName,'.csv','memUsage.log');
fidG = fopen(fullfile(pathName,fileNameMemUsage),        'w');

vids    = []; % Matrix of camera video connections
ims     = []; % Matrix of images
%stims   = []; % Stitched images 3xN grid
%nPlates = 0;
for camIdx = 1:nCamsToUse
    nPlates{camIdx} = 0;
    selectedCam = camsToUse(camIdx);
    pause(1);
    % Video inputs; depends on the type of camera used
    vids{camIdx} = imaq.VideoDevice('pointgrey', selectedCam, 'F7_BayerRG8_664x524_Mode1');
    pause(1);
    src = vids{camIdx}.DeviceProperties;
    set(vids{camIdx},'ReturnedColorSpace','rgb');

    % Set all parameters to manual and define the best set
    src.Brightness              = 0;
    src.ExposureMode            = 'Manual';
    src.Exposure                = 1;
    src.FrameRatePercentageMode = 'Manual';
    src.FrameRatePercentage     = 100;
    src.GainMode                = 'Manual';
    src.Gain                    = 0;
    src.ShutterMode             = 'Manual';
    src.Shutter                 = 8;
    src.WhiteBalanceRBMode      = 'Off';
    
    
    disp(src.Shutter)
    disp(src.Brightness)
    disp(src.Gain)
    
    %% start by previewing the image to adjust alignment and focus
    fig1 = figure();
    
    while ishghandle(fig1)
        im = step(vids{camIdx});
        im = rgb2gray(im);
        imshow(im,[],'i','f');
        drawnow;
        title(['preview cam ' num2str(selectedCam) ': adjust contrast/focus/brightness']);
        pause(0.01);
    end
    close(gcf); % Closes the plot/image

    ims{camIdx} = step(vids{camIdx});
    ims{camIdx} = rgb2gray(ims{camIdx});
    %tim = step(vids{camIdx});
    %tim = rgb2gray(tim);

    %% Create a grid of images from the camera
    %if mod(camIdx,numImCols) == 0
    %    stims = [stims;ims{camIdx}];
    %    %stims = [stims;tim];
    %else
    %    stims = [stims ims{camIdx}];
    %    %stims = [stims tim];
    %end
end

%% find the circular features and establish where the wells are
%[x2,positionParameters] = findwells_3(stims);
%[x2,positionParameters] = findwells_4(camsToUse,ims);
for camIdx=1:nCamsToUse
    [x2{camIdx},positionParameters{camIdx}] = findwells_5(camsToUse(camIdx),ims{camIdx});
    % include a little more than half the interwell spacing in each "well" 
    % this is a little more forgiving when it comes to the placement of the
    % well in the GUI

    nPlates{camIdx} = numel(positionParameters{camIdx});

    wellSpacingPix{camIdx} = 0;
    for iiPlate = 1:nPlates{camIdx}
        wellSpacingPix{camIdx}=wellSpacingPix{camIdx}+ abs((positionParameters{camIdx}{iiPlate}(4)));
    end
    wellSpacingPix{camIdx} = wellSpacingPix{camIdx}/nPlates{camIdx};
    ROISize{camIdx}        = round(wellSpacingPix{camIdx}/1.8);

    refStacks{camIdx}=double(ims{camIdx});

    %% move well coordinates into the proper shape
    x2{camIdx} = (x2{camIdx}');
    wellCoordinates{camIdx} = round(x2{camIdx});

    for jjPlate = 1:nPlates{camIdx}
        for jjRow = 1:8
            for jjCol = 1:12
                wellName = ['cam:',num2str(camsToUse(camIdx)),'plate:',num2str(jjPlate),'_well:',...
                            char(64+jjRow),num2str(jjCol)];
                fprintf(fidA{camIdx},[wellName, '_x,', wellName, '_y,']);
                fprintf(fidB{camIdx},[wellName, '_size,']);
                fprintf(fidC{camIdx},[wellName, '_speed(mm/s),']);
                fprintf(fidD{camIdx},[wellName, '_displacement(mm),']);
                fprintf(fidE{camIdx},[wellName, '_distance(mm),']);
                fprintf(fidF{camIdx},[wellName, '_nantime(s),']);
            end
        end
    end

    fprintf(fidA{camIdx},'\r\n');
    fprintf(fidB{camIdx},'\r\n');
    fprintf(fidC{camIdx},'\r\n');
    fprintf(fidD{camIdx},'\r\n');
    fprintf(fidE{camIdx},'\r\n');
    fprintf(fidF{camIdx},'\r\n');
end

%Print column headers for memory usage output
msg = ['Secs',char(9),'Mb Added Since Start'];
disp(msg)
fprintf(fidG, '%s\n', msg);

%% run experiment
% for faster updating of the images, display images using Cdata instead of a
% full call to imshow or image
imshowHand = nan;
% timed loop counters and timers
tc       = 1;
ticA     = tic;
tElapsed = toc(ticA);

for camIdx=1:nCamsToUse
    outCentroids{camIdx}     = [];
    outDisplacements{camIdx} = [];
end

while tElapsed < experimentLength           % main experimental loop
    % grab the most recent frames from the cameras and convert it into a single grayscale image
    %stims = [];
    for camIdx=1:nCamsToUse
        ims{camIdx} = step(vids{camIdx});
        ims{camIdx} = round(rgb2gray(ims{camIdx})*256);
        ims{camIdx} = double(ims{camIdx});
        %tim = step(vids{camIdx});
        %tim = round(rgb2gray(tim)*256);
        %tim = double(tim);
    
        %% Create a grid of images from the camera
        %if mod(camIdx,numImCols) == 0
        %    stims = [stims;tim];
        %else
        %    stims = [stims tim];
        %end
    end

    %Log the memory usage once every "usageTiming" seconds (accounts for loop
    %taking too long & an interval is skipped)
    if lastUsageTime == 0 || tElapsed >= (lastUsageTime + usageTiming)
        [user sys] = memory;
        memoryAddedSinceStartMB = (user.MemUsedMATLAB - initialMemory)/1000000;
        msg = sprintf('%i%s%i', round(tElapsed), char(9),...
                      round(memoryAddedSinceStartMB));
        disp(msg)
        fprintf(fidG, '%s\n', msg);
        lastUsageTime = tElapsed;
    end

    % check to see if the reference stack requires updating
    % detect every ref frame update
    if mod(tElapsed,refStackUpdateTiming) > mod(toc,refStackUpdateTiming)
        for camIdx = 1:nCamsToUse
            refStack = refStacks{camIdx};
            % if current size of ref images reaches the refstacksize defined above
            if size(refStacks{camIdx},3) == refStackSize
                % update ref stack by replacing the last ref image by the new one
                %refStack=cat(3,refStack(:,:,2:end),stims);
                refStacks{camIdx}=cat(3,refStack(:,:,2:end),ims{camIdx});
            else
                %refStack=cat(3,refStack,stims);
                refStacks{camIdx}=cat(3,refStack,ims{camIdx});
            end
            % the actual ref image displayed is the median image of the refstack
            %refImage=median(refStack,3);
            refImages{camIdx}=median(refStack,3);
        end
    end
    
    %calculate fly positions every frame
    %if exist('refImage','var')
    if exist('refImages','var')
        displayIm = [];
        for camIdx = 1:nCamsToUse
            zs = zeros((ROISize{camIdx}*2+2)*9,(ROISize{camIdx}*2+2)*13,3);
            tempIms{camIdx}=zeros((ROISize{camIdx}*2+2)*9,(ROISize{camIdx}*2+2)*13,3)+255;
            ts = size(wellCoordinates{camIdx},1);
            centroidsTemp{camIdx}=zeros(size(wellCoordinates{camIdx},1),2);
        
            %diffIm=(refImage-double(stims));
            diffIms{camIdx}=(refImages{camIdx}-double(ims{camIdx}));
        
            for iiWell=1:size(wellCoordinates{camIdx},1)
                %wellCoordinates{camIdx}(iiWell,2)
                %ROISize{camIdx}
                diffImsSmall{camIdx} = diffIms{camIdx}(wellCoordinates{camIdx}(iiWell,2)+(-ROISize{camIdx}:ROISize{camIdx}),...
                                                       wellCoordinates{camIdx}(iiWell,1)+(-ROISize{camIdx}:ROISize{camIdx}));
                                    
                diffImsSmall{camIdx}=255*(diffImsSmall{camIdx}>trackingThreshold);
                
                bkImsSmall{camIdx}=ims{camIdx}(wellCoordinates{camIdx}(iiWell,2)+(-ROISize{camIdx}:ROISize{camIdx}),...
                                               wellCoordinates{camIdx}(iiWell,1)+(-ROISize{camIdx}:ROISize{camIdx}));
               
                % build up an image for display purposes
                tempIms{camIdx}( (mod(iiWell-1,8))*(ROISize{camIdx}*2+2)+(ROISize{camIdx}:3*ROISize{camIdx}),...
                        (((iiWell-1)-mod(iiWell-1,8))/8)*(ROISize{camIdx}*2+2)+(ROISize{camIdx}:3*ROISize{camIdx}),...
                        2) = ...
                        fliplr(flipud(bkImsSmall{camIdx}));
                
                tempIms{camIdx}( (mod(iiWell-1,8))*(ROISize{camIdx}*2+2)+(ROISize{camIdx}:3*ROISize{camIdx}),...
                        (((iiWell-1)-mod(iiWell-1,8))/8)*(ROISize{camIdx}*2+2)+(ROISize{camIdx}:3*ROISize{camIdx}),...
                        3) = ...
                        fliplr(flipud(bkImsSmall{camIdx}));
                    
                tempIms{camIdx}( (mod(iiWell-1,8))*(ROISize{camIdx}*2+2)+(ROISize{camIdx}:3*ROISize{camIdx}),...
                        (((iiWell-1)-mod(iiWell-1,8))/8)*(ROISize{camIdx}*2+2)+(ROISize{camIdx}:3*ROISize{camIdx}),...
                        1) = ...
                        fliplr(flipud(diffImsSmall{camIdx}));
                
                % calculate the center of mass of the thresholded
                % difference map
                xCentroid=sum(diffImsSmall{camIdx},1);
                xCentroid=sum(xCentroid.*(1:2*ROISize{camIdx}+1))/sum(xCentroid);
                yCentroid=sum(diffImsSmall{camIdx},2);
                yCentroid=sum(yCentroid'.*(1:2*ROISize{camIdx}+1))/sum(yCentroid);
                centroidsTemp{camIdx}(iiWell,:)=[xCentroid yCentroid];
                centroidsSizeTemp{camIdx}(iiWell)=[nnz(diffImsSmall{camIdx})];
            end
      
            % saturate the image slightly for display purposes;
            tempIms2{camIdx}                      = tempIms{camIdx}./255;
            tempIms2{camIdx}                      = tempIms2{camIdx}-0.02;
            tempIms2{camIdx}(tempIms2{camIdx}>.2) = 0.1;
            tempIms2{camIdx}(tempIms2{camIdx}<0)  = 0;
            tempIms2{camIdx}                      = tempIms2{camIdx}./0.2;

            %Create an image to display
            if camIdx == 1
                displayIm = [displayIm;tempIms2{camIdx}];
            else
                %The following takes tempIms2{camIdx}, which is a series of plate
                %images displayed horizontally (for a specific camera 'camIdx')
                %and tacks on a row of plates for each camera.  Any odd width
                %differences in the camer images are handled by filling in zeros.
                [h1 w1 ~] = size(displayIm);
                [h2 w2 ~] = size(tempIms2{camIdx});
                tDisplayIm = displayIm;
                tNewIm = tempIms2{camIdx};
                if w1 > w2
                    tNewIm = [tNewIm zeros(h2,w1-w2,3)];
                elseif w2 > w1
                    tDisplayIm = [tDisplayIm zeros(h1,w2-w1,3)];
                    displayIm = tDisplayIm;
                end
                displayIm = [displayIm;tNewIm];
            end
        end

        % display the image
        if not(ishghandle(imshowHand))
            imshowHand = imshow(displayIm,[],'initialMag','fit','Border','tight');
        else
            set(imshowHand,'Cdata',displayIm);
        end
        pause(pauseBetweenAcquisitions_sec);

        for camIdx = 1:nCamsToUse
            outCentroids{camIdx}(counter,:)=[tElapsed reshape(centroidsTemp{camIdx}',1,...
                                                              size(wellCoordinates{camIdx},1)*2)];
            outCentroidsSizeTemp{camIdx}(counter,:) = [tElapsed, centroidsSizeTemp{camIdx} * ((wellToWellSpacing_mm/wellSpacingPix{camIdx})*(wellToWellSpacing_mm/wellSpacingPix{camIdx}))];
    
            if size(outDisplacements{camIdx},1)>1
                displacementsTemp{camIdx} = outCentroids{camIdx}(counter-1,2:end)-outCentroids{camIdx}(counter,2:end);
                displacementsTemp{camIdx} = reshape(displacementsTemp{camIdx},2,[]);
                displacementsTemp{camIdx} = sqrt(nansum(displacementsTemp{camIdx}.^2))*(wellToWellSpacing_mm/wellSpacingPix{camIdx});
                outDisplacements{camIdx}(counter,:) = [tElapsed, nansum([displacementsTemp{camIdx};outDisplacements{camIdx}(counter-1,2:end)])];
            else
                displacementsTemp{camIdx} = outCentroids{camIdx}(counter,2:end)-outCentroids{camIdx}(counter,2:end);
                displacementsTemp{camIdx} = reshape(displacementsTemp{camIdx},2,[]);
                displacementsTemp{camIdx} = sqrt(nansum(displacementsTemp{camIdx}.^2))*(wellToWellSpacing_mm/wellSpacingPix{camIdx});
                outDisplacements{camIdx}(counter,:) = [tElapsed, displacementsTemp{camIdx}];
            end
            
            if exist('prevCentroids','var')
                % decide if these coordinates should be written to file or not
                if tc == 1 && tElapsed>writeToFileTiming

                    dlmwrite(fullfile(pathName,fileNameCentroidPosition{camIdx}),outCentroids{camIdx}(counter,:),'-append','delimiter',',','precision',6);
                    dlmwrite(fullfile(pathName,fileNameTotalDistTravel{camIdx}),outDisplacements{camIdx}(counter,:),'-append','delimiter',',','precision',6);

                    % displacement since last time data was written to file
                    dispTravel = outDisplacements{camIdx}(counter,:)-outDisplacements{camIdx}(counter,:);
                    dispTravel(1) = outDisplacements{camIdx}(counter,1);
                    dlmwrite(fullfile(pathName,fileNameDispTravel{camIdx}),...
                             dispTravel,...
                             '-append','delimiter',',','precision',6);

                    % speed since last time data was written to file
                    instantSpeed = dispTravel./nan();
                    instantSpeed(1) = outDisplacements{camIdx}(counter,1);
                    dlmwrite(fullfile(pathName,fileNameInstantSpeed{camIdx}),...
                             instantSpeed,...
                             '-append','delimiter',',','precision',6);

                    % average centroid area since last time data was written to file
                    avgCentroidSize = nanmean(outCentroidsSizeTemp{camIdx}(counter:counter,:));
                    avgCentroidSize(1) = outDisplacements{camIdx}(counter,1);
                    dlmwrite(fullfile(pathName,fileNameCentroidSize{camIdx}),...
                             avgCentroidSize,...
                             '-append','delimiter',',','precision',6);
    
                elseif tElapsed>tc*writeToFileTiming && tElapsed<(tc+1)*writeToFileTiming 
          
                    dlmwrite(fullfile(pathName,fileNameCentroidPosition{camIdx}),outCentroids{camIdx}(counter,:),'-append','delimiter',',','precision',6);
                    dlmwrite(fullfile(pathName,fileNameTotalDistTravel{camIdx}),outDisplacements{camIdx}(counter,:),'-append','delimiter',',','precision',6);

                    % displacement since last time data was written to file
                    dispTravel = outDisplacements{camIdx}(counter,:)-outDisplacements{camIdx}(1,:);
                    dispTravel(1) = outDisplacements{camIdx}(counter,1);
                    dlmwrite(fullfile(pathName,fileNameDispTravel{camIdx}),...
                             dispTravel,...
                             '-append','delimiter',',','precision',6);
    
                    % speed since last time data was written to file
                    instantSpeed = dispTravel./(outDisplacements{camIdx}(counter,1)-outDisplacements{camIdx}(1,1));
                    instantSpeed(1) = outDisplacements{camIdx}(counter,1);
                    dlmwrite(fullfile(pathName,fileNameInstantSpeed{camIdx}),...
                             instantSpeed,...
                             '-append','delimiter',',','precision',6);
    
                    % average centroid area since last time data was written
                    avgCentroidSize = nanmean(outCentroidsSizeTemp{camIdx}(1:counter,:));
                    avgCentroidSize(1) = outDisplacements{camIdx}(counter,1);
                    dlmwrite(fullfile(pathName,fileNameCentroidSize{camIdx}),...
                             avgCentroidSize,...
                             '-append','delimiter',',','precision',6);
    
                end

            end
        
        
        
            prevCentroids{camIdx}=centroidsTemp{camIdx};
        end

        % Update the counter and the tc for all the cams - copied from above so the same thing would be done for each cam's image
        if exist('prevCentroids','var')
            % decide if these coordinates should be written to file or not
            if ((tc == 1 && tElapsed>writeToFileTiming) || (tElapsed>tc*writeToFileTiming && tElapsed<(tc+1)*writeToFileTiming))

                %Restarting these variables at position 1 - every prior row is
                %no longer needed.
                outCentroids{camIdx}(1,:)         = outCentroids{camIdx}(counter,:);
                outCentroidsSizeTemp{camIdx}(1,:) = outCentroidsSizeTemp{camIdx}(counter,:);
                outDisplacements{camIdx}(1,:)     = outDisplacements{camIdx}(counter,:);

                counter = 1;
                tc=tc+1;
            end
        end
    end
    
    if mod(counter,100)==0
        cla;
    end

    %Garbage collect once a day
    if tElapsed >= (lastTrashDay + trashDayTiming)
        pack; %Garbage collection (takes a few seconds)
        lastTrashDay = tElapsed;
    end

    counter=counter+1;
    tElapsed=toc(ticA);
end



%%
for camIdx=1:nCamsToUse
    fclose(fidA{camIdx});
    fclose(fidB{camIdx});
    fclose(fidC{camIdx});
    fclose(fidD{camIdx});
    fclose(fidE{camIdx});
    fclose(fidF{camIdx});
end
fclose(fidG);
