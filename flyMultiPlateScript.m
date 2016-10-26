%% experiment parameters
experimentLength = 259200;           % Length of the trial in seconds
refStackSize = 11;                   % Number of reference images
refStackUpdateTiming = 10;           % How often to update a ref image, in secs
writeToFileTiming = 60;              % How often to write out data
wellToWellSpacing_mm = 8;            % distance between wells in mm
probableDeathTime_sec = 30;          % time to mark NaNs as probable death evnt
pauseBetweenAcquisitions_sec = 0.01; % pause between subsequent images
%fly position extraction parameters
trackingThreshold = 5;               % higher # = smaller regs detected as diff
lastTrashDay = 0;
trashDayTiming = 86400;              % Collect the trash once a day

%% initialization
[user sys]    = memory;
initialMemory = user.MemUsedMATLAB;
usageTiming   = 60;
lastUsageTime = 0;

close all;
clear refStack;
clear refImage;

[fileName, pathName]     = uiputfile([datestr(now,'yyyymmdd-HHMMSS'),'.csv']);
fileNameCentroidPosition = strrep(fileName,'.csv','centroidPos.csv');
fileNameCentroidSize     = strrep(fileName,'.csv','centroidSize.csv');
fileNameInstantSpeed     = strrep(fileName,'.csv','instantSpeed.csv');
fileNameDispTravel       = strrep(fileName,'.csv','displacementTravel.csv');
fileNameTotalDistTravel  = strrep(fileName,'.csv','totalDistTravel.csv');
fileNameProbableDeath    = strrep(fileName,'.csv','probableDeath.csv');
fileNameMemUsage         = strrep(fileName,'.csv','memUsage.log');

%% Select the camera to use
selectedCam = 1;
camsInfo = imaqhwinfo('pointgrey');
cams = camsInfo.DeviceIDs;
if numel(cams) > 1
    ok = 0;
    while ok == 0
        [selection ok] = listdlg('PromptString','Select a PointGrey camera',...
                                 'SelectionMode','single',...
                                 'InitialValue',selectedCam,...
                                 'ListString',cellfun(@num2str,cams));
    end
    selectedCam = cams(selection);
end

%% Prepare the camera
imaqreset;
pause(1);
% Video inputs; depends on the type of camera used
vid = imaq.VideoDevice('pointgrey', selectedCam, 'F7_BayerRG8_664x524_Mode1');
pause(1);
src = vid.DeviceProperties;
set(vid,'ReturnedColorSpace','rgb');

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

tic;
counter  = 1;
tElapsed = 0;
tc       = 1;

%% start by previewing the image to adjust alignment and focus
fig1 = figure();

while ishghandle(fig1)
    im = step(vid);
    im = rgb2gray(im);
    imshow(im,[],'i','f');
    drawnow;
    title('preview: adjust contrast/focus/brightness');
    pause(0.01);
end

close(gcf);


%% find the circular features and establish where the wells are
im = step(vid);
im = rgb2gray(im);
[x2,positionParameters] = findwells_3(im);
% include a little more than half the interwell spacing in each "well" 
% this is a little more forgiving when it comes to the placement of the
% well in the GUI

nPlates = numel(positionParameters);

wellSpacingPix = 0;
for iiPlate = 1:nPlates
    wellSpacingPix=wellSpacingPix+ abs((positionParameters{iiPlate}(4)));
end
wellSpacingPix = wellSpacingPix/nPlates;
ROISize        = round(wellSpacingPix/1.8);

refStack=double(im);

%% move well coordinates into the proper shape
x2 = (x2');
wellCoordinates = round(x2);

%% get file ready for writing
fidA = fopen(fullfile(pathName,fileNameCentroidPosition),'w'); % done
fidB = fopen(fullfile(pathName,fileNameCentroidSize),'w');     % needs testing
fidC = fopen(fullfile(pathName,fileNameInstantSpeed),'w');     % needs testing
fidD = fopen(fullfile(pathName,fileNameDispTravel),'w');       % needs testing
fidE = fopen(fullfile(pathName,fileNameTotalDistTravel),'w');  % needs testing
fidF = fopen(fullfile(pathName,fileNameProbableDeath),'w');    % needs thought
fidG = fopen(fullfile(pathName,fileNameMemUsage),'w');

fprintf(fidA,'time_sec,');
fprintf(fidB,'time_sec,');
fprintf(fidC,'time_sec,');
fprintf(fidD,'time_sec,');
fprintf(fidE,'time_sec,');
fprintf(fidF,'time_sec,');

for jjPlate = 1:nPlates
    for jjRow = 1:8
        for jjCol = 1:12
            wellName = ['plate:',num2str(jjPlate),'_well:',char(64+jjRow),...
                        num2str(jjCol)];
            fprintf(fidA,[wellName, '_x,', wellName, '_y,']);
            fprintf(fidB,[wellName, '_size,']);
            fprintf(fidC,[wellName, '_speed(mm/s),']);
            fprintf(fidD,[wellName, '_displacement(mm),']);
            fprintf(fidE,[wellName, '_distance(mm),']);
            fprintf(fidF,[wellName, '_nantime(s),']);
        end
    end
end
fprintf(fidA,'\r\n');
fprintf(fidB,'\r\n');
fprintf(fidC,'\r\n');
fprintf(fidD,'\r\n');
fprintf(fidE,'\r\n');
fprintf(fidF,'\r\n');

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

outCentroids     = [];
outDisplacements = [];

while tElapsed < experimentLength           % main experimental loop
    % grab the most recent frame and convert it into a grayscale image
    im = step(vid);
    im = round(rgb2gray(im)*256);
    im = double(im);

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
        % if current size of ref images reaches the refstacksize defined above
        if size(refStack,3) == refStackSize
            % update ref stack by replacing the last ref image by the new one
            refStack=cat(3,refStack(:,:,2:end),im);
        else
            refStack=cat(3,refStack,im);
        end
        % the actual ref image displayed is the median image of the refstack
        refImage=median(refStack,3);
    end
    
    %calculate fly positions every frame
    if exist('refImage','var')
        tempIm=zeros((ROISize*2+2)*9,(ROISize*2+2)*13,3)+255;
        centroidsTemp=zeros(size(wellCoordinates,1),2);
        
        diffIm=(refImage-double(im));
        
        for iiWell=1:size(wellCoordinates,1)
            diffImSmall = diffIm(wellCoordinates(iiWell,2)+(-ROISize:ROISize),...
                                 wellCoordinates(iiWell,1)+(-ROISize:ROISize));
                                
            diffImSmall=255*(diffImSmall>trackingThreshold);
            
            bkImSmall=im(   wellCoordinates(iiWell,2)+(-ROISize:ROISize),...
                            wellCoordinates(iiWell,1)+(-ROISize:ROISize));
           
                        % build up an image for display purposes
            tempIm( (mod(iiWell-1,8))*(ROISize*2+2)+(ROISize:3*ROISize),...
                    (((iiWell-1)-mod(iiWell-1,8))/8)*(ROISize*2+2)+(ROISize:3*ROISize),...
                    2) = ...
                    fliplr(flipud(bkImSmall));
            
            tempIm( (mod(iiWell-1,8))*(ROISize*2+2)+(ROISize:3*ROISize),...
                    (((iiWell-1)-mod(iiWell-1,8))/8)*(ROISize*2+2)+(ROISize:3*ROISize),...
                    3) = ...
                    fliplr(flipud(bkImSmall));
                
            tempIm( (mod(iiWell-1,8))*(ROISize*2+2)+(ROISize:3*ROISize),...
                    (((iiWell-1)-mod(iiWell-1,8))/8)*(ROISize*2+2)+(ROISize:3*ROISize),...
                    1) = ...
                    fliplr(flipud(diffImSmall));
            
                % calculate the center of mass of the thresholded
                % difference map
            xCentroid=sum(diffImSmall,1);
            xCentroid=sum(xCentroid.*(1:2*ROISize+1))/sum(xCentroid);
            yCentroid=sum(diffImSmall,2);
            yCentroid=sum(yCentroid'.*(1:2*ROISize+1))/sum(yCentroid);
            centroidsTemp(iiWell,:)=[xCentroid yCentroid];
            centroidsSizeTemp(iiWell)=[nnz(diffImSmall)];
        end
     
        % saturate the image slightly for display purposes;
        tempIm2             = tempIm./255;
        tempIm2             = tempIm2-0.02;
        tempIm2(tempIm2>.2) = 0.1;
        tempIm2(tempIm2<0)  = 0;
        tempIm2             = tempIm2./0.2;

        % display the image
        if not(ishghandle(imshowHand))
        imshowHand = imshow(tempIm2,[],'initialMag','fit');
        else
            set(imshowHand,'Cdata',tempIm2);
        end
        pause(pauseBetweenAcquisitions_sec);
        % store the centroids
        outCentroids(counter,:)=[tElapsed reshape(centroidsTemp',1,...
                                                  size(wellCoordinates,1)*2)];
        outCentroidsSizeTemp(counter,:) = [tElapsed, centroidsSizeTemp * ((wellToWellSpacing_mm/wellSpacingPix)*(wellToWellSpacing_mm/wellSpacingPix))];

        if size(outDisplacements,1)>1
            %displacementsTemp = outCentroids(end-1,2:end)-outCentroids(end,2:end);
            displacementsTemp = outCentroids(counter-1,2:end)-outCentroids(counter,2:end);
            displacementsTemp = reshape(displacementsTemp,2,[]);
            displacementsTemp = sqrt(nansum(displacementsTemp.^2))*(wellToWellSpacing_mm/wellSpacingPix);
            outDisplacements(counter,:) = [tElapsed, nansum([displacementsTemp;outDisplacements(counter-1,2:end)])];
        else
            %displacementsTemp = outCentroids(end,2:end)-outCentroids(end,2:end);
            displacementsTemp = outCentroids(counter,2:end)-outCentroids(counter,2:end);
            displacementsTemp = reshape(displacementsTemp,2,[]);
            displacementsTemp = sqrt(nansum(displacementsTemp.^2))*(wellToWellSpacing_mm/wellSpacingPix);
            outDisplacements(counter,:) = [tElapsed, displacementsTemp];
        end
        
        if exist('prevCentroids','var')
            % decide if these coordinates should be written to file or not
            if tc == 1 && tElapsed>writeToFileTiming
                dlmwrite(fullfile(pathName,fileNameCentroidPosition),outCentroids(counter,:),'-append','delimiter',',','precision',6);
                dlmwrite(fullfile(pathName,fileNameTotalDistTravel),outDisplacements(counter,:),'-append','delimiter',',','precision',6);
                % displacement since last time data was written to file
                dispTravel = outDisplacements(counter,:)-outDisplacements(counter,:);
                dispTravel(1) = outDisplacements(counter,1);
                dlmwrite(fullfile(pathName,fileNameDispTravel),...
                    dispTravel,...
                    '-append','delimiter',',','precision',6);
                % speed since last time data was written to file
                instantSpeed = dispTravel./nan();
                instantSpeed(1) = outDisplacements(counter,1);
                dlmwrite(fullfile(pathName,fileNameInstantSpeed),...
                    instantSpeed,...
                    '-append','delimiter',',','precision',6);
                % average centroid area since last time data was written to file
                avgCentroidSize = nanmean(outCentroidsSizeTemp(counter:counter,:));
                avgCentroidSize(1) = outDisplacements(counter,1);
                dlmwrite(fullfile(pathName,fileNameCentroidSize),...
                    avgCentroidSize,...
                    '-append','delimiter',',','precision',6);


                %Restarting these variables at position 1 - every prior row is
                %no longer needed.
		outCentroids(1,:)         = outCentroids(counter,:);
		outCentroidsSizeTemp(1,:) = outCentroidsSizeTemp(counter,:);
                outDisplacements(1,:)     = outDisplacements(counter,:);

		counter = 1;
       
                
                tc = 2;
            elseif tElapsed>tc*writeToFileTiming && tElapsed<(tc+1)*writeToFileTiming           
                dlmwrite(fullfile(pathName,fileNameCentroidPosition),outCentroids(counter,:),'-append','delimiter',',','precision',6);
                dlmwrite(fullfile(pathName,fileNameTotalDistTravel),outDisplacements(counter,:),'-append','delimiter',',','precision',6);
                % displacement since last time data was written to file
                dispTravel = outDisplacements(counter,:)-outDisplacements(1,:);
                dispTravel(1) = outDisplacements(counter,1);
                dlmwrite(fullfile(pathName,fileNameDispTravel),...
                    dispTravel,...
                    '-append','delimiter',',','precision',6);
                % speed since last time data was written to file
                instantSpeed = dispTravel./(outDisplacements(counter,1)-outDisplacements(1,1));
                instantSpeed(1) = outDisplacements(counter,1);
                dlmwrite(fullfile(pathName,fileNameInstantSpeed),...
                    instantSpeed,...
                    '-append','delimiter',',','precision',6);
                % average centroid area since last time data was written
                avgCentroidSize = nanmean(outCentroidsSizeTemp(1:counter,:));
                avgCentroidSize(1) = outDisplacements(counter,1);
                dlmwrite(fullfile(pathName,fileNameCentroidSize),...
                    avgCentroidSize,...
                    '-append','delimiter',',','precision',6);


                %Restarting these variables at position 1 - every prior row is
                %no longer needed.
		outCentroids(1,:)         = outCentroids(counter,:);
		outCentroidsSizeTemp(1,:) = outCentroidsSizeTemp(counter,:);
                outDisplacements(1,:)     = outDisplacements(counter,:);

		counter = 1;

                tc=tc+1;
            end

        end
        
        
        
        prevCentroids=centroidsTemp;
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
fclose(fidA);
fclose(fidB);
fclose(fidC);
fclose(fidD);
fclose(fidE);
fclose(fidF);
fclose(fidG);
