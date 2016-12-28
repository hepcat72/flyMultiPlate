%This isn't really necessary
%choice = questdlg('Clearing workspace. Are you sure you want to do this?',...
%                  'Warning','Yes','No','No');
%if strcmp(choice, 'No')
%    return;
%end
clear;

fileMode = 0; %If no cam is plugged in, offer to process a saved video file
choice = questdlg('Would you like to process a video file or live camera?',...
                  'Warning','File','Camera','Camera');
if strcmp(choice, 'File')
    fileMode = 1;
end


%% experiment parameters
experimentLength             = 604800; % Length of the trial in seconds
refStackSize                 = 11;     % Number of reference images
refStackUpdateTiming         = 10;     % How often to update a ref image (secs)
writeToFileTiming            = 60;     % How often to write out data
wellToWellSpacing_mm         = 8;      % distance between wells in mm
probableDeathTime_sec        = 30;     % time to mark NaNs as probable death
pauseBetweenAcquisitions_sec = 0.01;   % pause between subsequent images

%fly position extraction parameters
trackingThreshold = 10;                % higher = smaller regs detected as diff

%% initialization
[user sys]     = memory;
initialMemory  = user.MemUsedMATLAB;
usageTiming    = 60;
lastUsageTime  = 0;
lastTrashDay   = 0;
trashDayTiming = 86400;                % Collect the trash once a day
datetimeSpec   = '%{dd-MMM-uuuu HH:mm:ss.SSSSSSSSS}D'; %For reading timestamps
lastRefStackUpdateTime = 0;

close all;

%% Select the camera(s) to use
nCamsToUse  = 1;
selectedCam = 1;
numImCols   = 1;
camsInfo    = imaqhwinfo('pointgrey');
cams        = camsInfo.DeviceIDs;
camsToUse   = [selectedCam];
if fileMode == 0
    if numel(cams) > 1
        nCamsToUse = getNumListDialog('How many cameras?',...
                                      1:numel(cams));
        if nCamsToUse < numel(cams)
            camsToUse   = [];
            for nextCam = 1:nCamsToUse
                ok = 0;
                while ok == 0
                    [selection ok] = listdlg('PromptString',...
                                             'Select a PointGrey camera',...
                                             'SelectionMode','single',...
                                             'InitialValue',selectedCam,...
                                             'ListString',...
                                             cellfun(@num2str,cams)');
                end
                selectedCam = cams{1,selection};
                camsToUse = [camsToUse selectedCam];
            end
        else
            camsToUse = 1:nCamsToUse;
        end
    elseif numel(cams) == 0
        choice = questdlg('No camera detected.  Read video from file?',...
                          'Warning','Yes','No','No');
        if strcmp(choice, 'No')
            return;
        end
        fileMode = 1;
    end
end

%% Prepare the camera
imaqreset;

counter  = 1;
tElapsed = 0;
tc       = 1;
vids     = []; % Matrix of camera video connections
ims      = []; % Matrix of images


if fileMode == 1

    %Going to use nCamsToUse, selectedCam, and camsToUse as number of vids to
    %use, vid num, and vids to use
    %HOWEVER - Only going to support processing 1 vid at a time (in case they
    %are different lengths or frames per sec)

    %% Open the video file

    %Prompt the user to open a video file
    [fileName,pathName] = uigetfile({'*.mj2';'*.avi';'*.mp4';'*.m4v'},...
                                    'Process previously saved video');

    vidObj = VideoReader([pathName,'\',fileName]);

    %Determine the length of the experiment in seconds (since that was
    %predetermined and may be different from what this script sets as default
    %above).
    experimentLength = vidObj.Duration;

    %vidHeight = vidObj.Height;
    %vidWidth = vidObj.Width;

    %Put the video object in the 'Matrix of camera video connections' since
    %that's how we obtain frames
    camIdx = 1;
    vids{camIdx} = vidObj;

    %Create a MATLAB� movie structure array
    %ims{camIdx} = struct('cdata',zeros(vidHeight,vidWidth,3,'uint8'),...
    %                     'colormap',[]);

    %% Open the timestamp file

    %Get the timestamp file - do all the possible replacements to brute-force
    %finding the filename
    timestampFileName = strrep(fileName,'.mj2','-timestamps.csv');
    timestampFileName = strrep(timestampFileName,'.avi','-timestamps.csv');
    timestampFileName = strrep(timestampFileName,'.mp4','-timestamps.csv');
    timestampFileName = strrep(timestampFileName,'.m4v','-timestamps.csv');

    %Check the existence of the associated timstamp file
    curFolder = pwd;
    cd(pathName);
    if not(exist(timestampFileName,'file') == 2)
        [timestampFileName,timestampPathName] = uigetfile({'*.mj2';'*.avi';'*.mp4';'*.m4v'},strcat('Select the timestamp file associated with: ',fileName));
    else
        timestampPathName = pathName;
    end
    cd(curFolder);

    disp(strcat('Opening timestamp file: ',fullfile(timestampPathName,...
                                                    timestampFileName)))
    timestampTable = readtable(fullfile(timestampPathName,...
                                        timestampFileName),...
                               'Delimiter',',','Format',datetimeSpec);
    [numTimestamps junk] = size(timestampTable);

    %Create a filename stub for all the output files
    fileName = strrep(timestampFileName,'-timestamps.csv','');
else
    tic;

    %Prompt the user to create a base outfile name
    [fileName, pathName] = uiputfile([datestr(now,'yyyymmdd-HHMMSS')],...
                                     'Create a base output file name');
end


%% Prepare the output data files

for camIdx = 1:nCamsToUse
    fileNameCentroidPosition{camIdx} = strcat(fileName,'-cam',num2str(camsToUse(camIdx)),'centroidPos.csv');
    fileNameCentroidSize{camIdx}     = strcat(fileName,'-cam',num2str(camsToUse(camIdx)),'centroidSize.csv');
    fileNameInstantSpeed{camIdx}     = strcat(fileName,'-cam',num2str(camsToUse(camIdx)),'instantSpeed.csv');
    fileNameDispTravel{camIdx}       = strcat(fileName,'-cam',num2str(camsToUse(camIdx)),'displacementTravel.csv');
    fileNameTotalDistTravel{camIdx}  = strcat(fileName,'-cam',num2str(camsToUse(camIdx)),'totalDistTravel.csv');

    %% get file ready for writing
    fidA{camIdx} = fopen(fullfile(pathName,fileNameCentroidPosition{camIdx}),'w'); % done
    fidB{camIdx} = fopen(fullfile(pathName,fileNameCentroidSize{camIdx}),    'w'); % needs testing
    fidC{camIdx} = fopen(fullfile(pathName,fileNameInstantSpeed{camIdx}),    'w'); % needs testing
    fidD{camIdx} = fopen(fullfile(pathName,fileNameDispTravel{camIdx}),      'w'); % needs testing
    fidE{camIdx} = fopen(fullfile(pathName,fileNameTotalDistTravel{camIdx}), 'w'); % needs testing
    
    fprintf(fidA{camIdx},'time_sec,');
    fprintf(fidB{camIdx},'time_sec,');
    fprintf(fidC{camIdx},'time_sec,');
    fprintf(fidD{camIdx},'time_sec,');
    fprintf(fidE{camIdx},'time_sec,');
end
fileNameMemUsage = strcat(fileName,'memUsage.log');
fidG = fopen(fullfile(pathName,fileNameMemUsage),'w');


%% Adjust the brightness, contrast, focus, & alignment of the cameras

if fileMode == 0
    loadedvids = 0;
    while loadedvids == 0
        for camIdx = 1:nCamsToUse
            nPlates{camIdx} = 0;
            selectedCam = camsToUse(camIdx);
            pause(1);
            % Video inputs; depends on the type of camera used

            try

                % The following was commented because this method of video capture
                % might be what is causing the random crashing, so I am replacing it
                % with the old method to test out that hypothesis
                %vids{camIdx} = imaq.VideoDevice('pointgrey', selectedCam,...
                %                                'F7_BayerRG8_664x524_Mode1');
                vids{camIdx} = videoinput('pointgrey', selectedCam);
                %Leaving out the 3rd arg (format) gets the default format for that
                %camera (i.e. 'F7_BayerRG8_664x524_Mode1')

                loadedvids = 1;
            catch ME
                loadedvids = 0;
                choice = questdlg(['Camera ' num2str(camIdx) 'is in use.  Would you like to reset all cameras and continue?'],...
                                   'Warning','Yes','No','No');
                if strcmp(choice, 'No')
                    return;
                end
                break;
            end
            pause(1);

        end
    end

    for camIdx = 1:nCamsToUse
        % The following was commented because this method of video capture
        % might be what is causing the random crashing, so I am replacing it
        % with the old method to test out that hypothesis
        %src = vids{camIdx}.DeviceProperties;
        src = getselectedsource(vids{camIdx});
        triggerconfig(vids{camIdx},'manual');

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
    
        disp(['Shutter: ' num2str(src.Shutter)])
        disp(['Brightness: ' num2str(src.Brightness)])
        disp(['Gain: ' num2str(src.Gain)])

        %% start by previewing the image to adjust alignment and focus

        % The following was added because the prev method of video capture
        % might be what is causing the random crashing, so I am replacing it
        % with the old method to test out that hypothesis
        try
            start(vids{camIdx});
        catch ME
        end

        fig1 = figure();
        while ishghandle(fig1)

            % The following was commented because this method of video capture
            % might be what is causing the random crashing, so I am replacing
            % it with the old method to test out that hypothesis
            %im = step(vids{camIdx});
            pause(0.01);
            im = (peekdata(vids{camIdx},1));

            im = rgb2gray(im);
            imshow(im,[],'i','f');
            drawnow;
            title(['preview cam ' num2str(selectedCam) ': adjust contrast/focus/brightness']);
            pause(0.01);
        end
        close(gcf); % Closes the plot/image

        %Save a frame so we can use it to find the well positions

        % The following was commented because this method of video capture
        % might be what is causing the random crashing, so I am replacing
        % it with the old method to test out that hypothesis
        %ims{camIdx} = step(vids{camIdx});
        ims{camIdx} = (peekdata(vids{camIdx},1));

        ims{camIdx} = rgb2gray(ims{camIdx});
    end
else
    %Can only process 1 video file at a time
    camIdx = 1;
    if(hasFrame(vids{camIdx}))
        ims{camIdx} = double(readFrame(vids{camIdx})) / 255.0;
        ims{camIdx} = rgb2gray(ims{camIdx});

        timestampIndex = 1;
        curTimestamp = timestampTable{timestampIndex,1};
        initialTime = curTimestamp;
    end
end

%% find the circular features and establish where the wells are
%[x2,positionParameters] = findwells_4(camsToUse,ims);
for camIdx=1:nCamsToUse

    [x2{camIdx},positionParameters{camIdx}] = findwells_5(camsToUse(camIdx),...
                                                          ims{camIdx});
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
    refImages{camIdx}=median(refStacks{camIdx},3);

    %% move well coordinates into the proper shape
    x2{camIdx} = (x2{camIdx}');    
    wellCoordinates{camIdx} = round(x2{camIdx});
    
    %% Allow the user to move specific wells after the gross positioning
    wellCoordinates{camIdx} = repositionCrosses(ims{camIdx},...
                                                wellCoordinates{camIdx});
    %% write out positions and header information
    for jjPlate = 1:nPlates{camIdx}
        for jjCol = 1:12
            for jjRow = 1:8
                wellName = ['cam:',num2str(camsToUse(camIdx)),'_plate:',num2str(jjPlate),'_well:',...
                            char(64+jjRow),num2str(jjCol)];
                fprintf(fidA{camIdx},[wellName, '_x,', wellName, '_y,']);
                fprintf(fidB{camIdx},[wellName, '_size,']);
                fprintf(fidC{camIdx},[wellName, '_speed(mm/s),']);
                fprintf(fidD{camIdx},[wellName, '_displacement(mm),']);
                fprintf(fidE{camIdx},[wellName, '_distance(mm),']);
            end
        end
    end

    fprintf(fidA{camIdx},'\r\n');
    fprintf(fidB{camIdx},'\r\n');
    fprintf(fidC{camIdx},'\r\n');
    fprintf(fidD{camIdx},'\r\n');
    fprintf(fidE{camIdx},'\r\n');
    
    % start the camera if it is not already started
    try
        start(vid);
    catch ME
    end

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
tc = 1;

if fileMode == 0
    ticA     = tic;
    tElapsed = toc(ticA);
else
    tElapsed = etime(datevec(curTimestamp),datevec(initialTime));
end

for camIdx=1:nCamsToUse
    outCentroids{camIdx}     = [];
    outDisplacements{camIdx} = [];
end

while tElapsed < experimentLength
    % grab the most recent frame from the cameras and convert to a single
    %grayscale image
    for camIdx=1:nCamsToUse
        if fileMode == 0

            % The following was commented because this method of video capture
            % might be what is causing the random crashing, so I am replacing
            % it with the old method to test out that hypothesis.  Note, the
            % values returned by step are between 0 and 1 whereas the values
            % returned by peekdata are between 0 and 255.  The method to
            % convert to grayscale expects values between 0 and 1.
            %ims{camIdx} = step(vids{camIdx});
            ims{camIdx} = (double(peekdata(vids{camIdx},1))/255.0);

            ims{camIdx} = round(rgb2gray(ims{camIdx})*255);
            ims{camIdx} = double(ims{camIdx});
        else
            ims{camIdx} = round(ims{camIdx}*255);
            ims{camIdx} = double(ims{camIdx});
        end
        %In fileMode, we already have an image to process at the beginning
        %of the loop and it's the one corresponding to the current tElapsed
        %Therefor, the next frame is retrieved at the end of the loop
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
    %if mod(tElapsed,refStackUpdateTiming) > mod(toc,refStackUpdateTiming)
    if tElapsed >= (lastRefStackUpdateTime + refStackUpdateTiming)
        disp(['Updating refStack at time ' num2str(tElapsed)])
        for camIdx = 1:nCamsToUse
            refStack = refStacks{camIdx};
            % if current ref images size reaches the refstacksize defined above
            if size(refStacks{camIdx},3) == refStackSize
                % Replace the last ref image with the new one
                refStacks{camIdx}=cat(3,refStack(:,:,2:end),ims{camIdx});
            else
                refStacks{camIdx}=cat(3,refStack,ims{camIdx});
            end
            % the ref image displayed is the median image of the refstack
            refImages{camIdx}=median(refStack,3);
        end
        lastRefStackUpdateTime = tElapsed;
    end
    
    %calculate fly positions every frame
    if exist('refImages','var')
        displayIm = [];
        for camIdx = 1:nCamsToUse
            zs = zeros((ROISize{camIdx}*2+2)*9,(ROISize{camIdx}*2+2)*13,3);
            tempIms{camIdx}=zeros((ROISize{camIdx}*2+2)*9,(ROISize{camIdx}*2+2)*13,3)+255;
            ts = size(wellCoordinates{camIdx},1);
            centroidsTemp{camIdx}=zeros(size(wellCoordinates{camIdx},1),2);
        
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
                %The following takes tempIms2{camIdx}, which is a series of
                %plate images displayed horizontally (for a specific camera)
                %'camIdx' and tacks on a row of plates for each camera.  Any
                %odd width differences in the camera images are handled by
                %filling in zeros.
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
            imshowHand = imshow(displayIm,[],'initialMag','fit','Border',...
                                'tight');
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
                % Write out to file when the first time interval has passed
                %(must do a couple special things)
                if tc == 1 && tElapsed>writeToFileTiming

                    % average centroid position since last time data was
                    %written to file
                    avgCentroidPos = nanmean(outCentroids{camIdx}(1:counter,:));
                    avgCentroidPos(1) = outDisplacements{camIdx}(counter,1);
                    dlmwrite(fullfile(pathName,...
                                      fileNameCentroidPosition{camIdx}),...
                             avgCentroidPos,'-append','delimiter',',',...
                             'precision',6);
                    %This is a temporary test to see whether I get any NaNs
                    %from a camera running on an empty plate
                    %The test shows numerous NaNs for an empty plate, but
                    %many actual values. The nanmean above on the other
                    %hand shows zeros where there had been NaNs, which is
                    %unexpected.
                    disp('Averages:')
                    avgCentroidPos
                    disp('Current centroid positions:')
                    outCentroids{camIdx}(counter,:)
                    %dlmwrite(fullfile(pathName,...
                    %                  fileNameCentroidPosition{camIdx}),...
                    %         outCentroids{camIdx}(counter,:),...
                    %         '-append','delimiter',',','precision',6);
                    dlmwrite(fullfile(pathName,...
                                      fileNameTotalDistTravel{camIdx}),...
                             outDisplacements{camIdx}(counter,:),'-append',...
                             'delimiter',',','precision',6);

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

                    % average centroid area since data was last written to file
                    avgCentroidSize = nanmean(outCentroidsSizeTemp{camIdx}(1:counter,:));
                    avgCentroidSize(1) = outDisplacements{camIdx}(counter,1);
                    dlmwrite(fullfile(pathName,...
                             fileNameCentroidSize{camIdx}),avgCentroidSize,...
                             '-append','delimiter',',','precision',6);

                % Write out to file at every time interval
                elseif tElapsed>tc*writeToFileTiming && tElapsed<(tc+1)*writeToFileTiming 
          
                    % average centroid position since data was last written
                    avgCentroidPos = nanmean(outCentroids{camIdx}(1:counter,:));
                    avgCentroidPos(1) = outDisplacements{camIdx}(counter,1);
                    dlmwrite(fullfile(pathName,...
                                      fileNameCentroidPosition{camIdx}),...
                             avgCentroidPos,'-append','delimiter',',',...
                             'precision',6);
                    %This is a temporary test to see whether I get any NaNs
                    %from a camera running on an empty plate The nanmean above on the other
                    %hand shows zeros where there had been NaNs, which is
                    %unexpected.
                    disp('Averages:')
                    avgCentroidPos
                    disp('Current centroid positions:')
                    outCentroids{camIdx}(counter,:)
                    dlmwrite(fullfile(pathName,...
                                      fileNameCentroidPosition{camIdx}),...
                             outCentroids{camIdx}(counter,:),...
                             '-append','delimiter',',','precision',6);
                    dlmwrite(fullfile(pathName,...
                                      fileNameTotalDistTravel{camIdx}),...
                             outDisplacements{camIdx}(counter,:),'-append',...
                             'delimiter',',','precision',6);

                    % displacement since last time data was written to file
                    dispTravel = outDisplacements{camIdx}(counter,:)-outDisplacements{camIdx}(1,:);
                    dispTravel(1) = outDisplacements{camIdx}(counter,1);
                    dlmwrite(fullfile(pathName,fileNameDispTravel{camIdx}),...
                             dispTravel,...
                             '-append','delimiter',',','precision',6);
    
                    % speed since last time data was written to file
                    instantSpeed = dispTravel./(outDisplacements{camIdx}(counter,1)-outDisplacements{camIdx}(1,1));
                    instantSpeed(1) = outDisplacements{camIdx}(counter,1);
                    dlmwrite(fullfile(pathName,...
                                      fileNameInstantSpeed{camIdx}),...
                             instantSpeed,'-append','delimiter',',',...
                             'precision',6);
    
                    % average centroid area since last time data was written
                    avgCentroidSize = nanmean(outCentroidsSizeTemp{camIdx}(1:counter,:));
                    avgCentroidSize(1) = outDisplacements{camIdx}(counter,1);
                    dlmwrite(fullfile(pathName,...
                                      fileNameCentroidSize{camIdx}),...
                             avgCentroidSize,...
                             '-append','delimiter',',','precision',6);
    
                end

            end
        
        
        
            prevCentroids{camIdx}=centroidsTemp{camIdx};
        end

        % Update the counter and the tc for all the cams - copied from above so
        % the same thing would be done for each cam's image
        if exist('prevCentroids','var')
            % decide if these coordinates should be written to file or not
            if ((tc == 1 && tElapsed>writeToFileTiming) || (tElapsed>tc*writeToFileTiming && tElapsed<(tc+1)*writeToFileTiming))

                %Restarting these variables at position 1 - every prior row is
                %no longer needed.
                outCentroids{camIdx}(1,:) = outCentroids{camIdx}(counter,:);
                outCentroidsSizeTemp{camIdx}(1,:) = outCentroidsSizeTemp{camIdx}(counter,:);
                outDisplacements{camIdx}(1,:) = outDisplacements{camIdx}(counter,:);

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
    if fileMode == 0
        tElapsed = toc(ticA);
    else
        if(hasFrame(vids{camIdx}))
            ims{camIdx} = double(readFrame(vids{camIdx})) / 255.0;
            ims{camIdx} = rgb2gray(ims{camIdx});

            timestampIndex = timestampIndex + 1;
            if timestampIndex > numTimestamps
                %PRINT ERROR
                msg = 'ERROR: There are not as many timestamps as there were frames in the video. Unable to proceed.';
                disp(msg)
                break;
            end
            curTimestamp = timestampTable{timestampIndex,1};
        %If the elapsed time is less than the exp. length (minus 1 sec
        %leeway)
        elseif tElapsed < (experimentLength - 1)
            %PRINT WARNING
            msg = sprintf('WARNING: The video file seems to have ended (at %d) before the duration it claimed it was at the beginning (%d).  This is OK, if the time processed thus far seems to be adequate.',tElapsed,experimentLength);
            disp(msg)
            break;
        else
            break;
        end

        tElapsed = etime(datevec(curTimestamp),datevec(initialTime));
    end
end


%Stop the videos
if fileMode == 0
    for camIdx=1:nCamsToUse
        stop(vids{camIdx});
    end
end
%Close the plot
close(gcf);
%% Close the file handles
for camIdx=1:nCamsToUse
    fclose(fidA{camIdx});
    fclose(fidB{camIdx});
    fclose(fidC{camIdx});
    fclose(fidD{camIdx});
    fclose(fidE{camIdx});
end
fclose(fidG);
disp(['Done. Elapsed time: ' num2str(tElapsed)]);