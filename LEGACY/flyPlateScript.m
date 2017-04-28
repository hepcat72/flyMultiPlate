% experiment parameters
experimentLength = 259200;             % Length of the trial in seconds
refStackSize = 11;                     % Number of reference images
refStackUpdateTiming = 10;              % How often to update a ref image
writeToFileTiming = 60;                % How often to update the image on screen

%fly position extraction parameters
trackingThreshold = 12; % higher numbers means smaller regions detected as different
%% initialization

close all;
clear refStack;
clear refImage;

[fileName, pathName] = uiputfile([datestr(now,'yyyymmdd-HHMMSS'),'.csv']);

imaqreset;
pause(1);
vid = videoinput('pointgrey', 1, 'F7_BayerRG8_664x524_Mode1');     % Video inputs; depends on the type of camera used
pause(1);
src = getselectedsource(vid);
triggerconfig(vid,'manual');    
set(vid,'ReturnedColorSpace','rgb');

% Set all parameters to manual and define the best set
src.Brightness=0;
src.ExposureMode = 'Manual';
src.Exposure = 1;
src.FrameRatePercentageMode = 'Manual';
src.FrameRatePercentage = 100;
src.GainMode = 'Manual';
src.Gain = 0;
src.ShutterMode = 'Manual';
src.Shutter = 8;
src.WhiteBalanceRBMode = 'Off';

start(vid);

disp(src.Shutter)
disp(src.Brightness)
disp(src.Gain)




tic;
counter=1;
tElapsed=0;
tc = 1;
%% start by previewing the image to adjust alignment and focus
fig1 = figure();
try % start the camera if it is not already started
    start(vid);
catch ME
end

while ishghandle(fig1)
im = (peekdata(vid,1));
im = rgb2gray(im);
imshow(im,[],'i','f');
drawnow;
title('preview: adjust contrast/focus/brightness');
    pause(0.01);
end

close(gcf);


%% find the circular features and establish where the wells are
try % start the camera if it is not already started
    start(vid);
catch ME
end
im = (peekdata(vid,1));
im = rgb2gray(im);
[x2,positionParameters] = findWells_2(im);
% include a little more than half the interwell spacing in each "well" 
% this is a little more forgiving when it comes to the placement of the
% well in the GUI
ROISize=abs(round(positionParameters(4)/1.8)); 

refStack=double(im);

%% move well coordinates into the proper shape
x2 = (x2');
wellCoordinates = round(x2);
%% get file ready for writing
fidA = fopen(fullfile(pathName,fileName),'w');
fprintf(fidA,'time_sec,');
for jjRow = 1:8
    for jjCol = 1:12
        wellName = [char(64+jjRow),num2str(jjCol)];
        fprintf(fidA,[wellName, '_x,', wellName, '_y,']);
    end
end
fprintf(fidA,'\r\n');

%% run experiment
imshowHand = nan; % for faster updating of the images, display images using Cdata instead of a full call to imshow or image
% timed loop counters and timers
tc = 1;
ticA = tic;
tElapsed = toc(ticA);

while tElapsed < experimentLength           % main experimental loop
    % grab the most recent frame and convert it into a grayscale image
    im = (peekdata(vid,1));
    im = rgb2gray(im);
    im = double(im);
    
    % check to see if the reference stack requires updating
    if mod(tElapsed,refStackUpdateTiming) > mod(toc,refStackUpdateTiming) % detect every ref frame update
        if size(refStack,3) == refStackSize      % if the current size of ref images reaches the refstacksize defined above
            refStack=cat(3,refStack(:,:,2:end),im); % update the ref stack by replacing the last ref image by the new ref image
        else
            refStack=cat(3,refStack,im);
        end
        refImage=median(refStack,3); % the actual ref image displayed is the median image of the refstack
   
    end
    
    %calculate fly positions every frame
    if exist('refImage','var')
        tempIm=zeros((ROISize*2+2)*9,(ROISize*2+2)*13,3)+255;
        centroidsTemp=zeros(96,2);
        
        diffIm=(refImage-double(im));
        
        for i=1:96 % BPB WARNS: USES HARDCODED SET OF 96 wells, or a single plate
            diffImSmall=diffIm(wellCoordinates(i,2)+(-ROISize:ROISize),wellCoordinates(i,1)+(-ROISize:ROISize));
            diffImSmall=255*(diffImSmall>trackingThreshold);
            bkImSmall=im(wellCoordinates(i,2)+(-ROISize:ROISize),wellCoordinates(i,1)+(-ROISize:ROISize));
            tempIm((mod(i-1,8))*(ROISize*2+2)+(ROISize:3*ROISize),(((i-1)-mod(i-1,8))/8)*(ROISize*2+2)+(ROISize:3*ROISize),2)=fliplr(flipud(bkImSmall));
            tempIm((mod(i-1,8))*(ROISize*2+2)+(ROISize:3*ROISize),(((i-1)-mod(i-1,8))/8)*(ROISize*2+2)+(ROISize:3*ROISize),3)=fliplr(flipud(bkImSmall));
            tempIm((mod(i-1,8))*(ROISize*2+2)+(ROISize:3*ROISize),(((i-1)-mod(i-1,8))/8)*(ROISize*2+2)+(ROISize:3*ROISize),1)=fliplr(flipud(diffImSmall));
            xCentroid=sum(diffImSmall,1);
            xCentroid=sum(xCentroid.*(1:2*ROISize+1))/sum(xCentroid);
            yCentroid=sum(diffImSmall,2);
            yCentroid=sum(yCentroid'.*(1:2*ROISize+1))/sum(yCentroid);
            centroidsTemp(i,:)=[xCentroid yCentroid];
        end
     
        % saturate the image slightly for display purposes;
        tempIm2 = tempIm./255;
        tempIm2 = tempIm2-0.02;
        tempIm2(tempIm2>.2) = 0.1;
        tempIm2(tempIm2<0) = 0;
        tempIm2 = tempIm2./0.2;
        % display the image
        if not(ishghandle(imshowHand))
        imshowHand = imshow(tempIm2,[],'initialMag','fit');
        else
            set(imshowHand,'Cdata',tempIm2);
        end
        pause(0.01);
        % store the centroids
        out(counter,:)=[tElapsed reshape(centroidsTemp',1,96*2)];
        
        if exist('prevCentroids','var')
            % decide if these coordinates should be written to file or not
            if tc == 1 && tElapsed>writeToFileTiming
                dlmwrite(fullfile(pathName,fileName),out(counter,:),'-append','delimiter',',','precision',6);
               tc = 2;
            elseif tElapsed>tc*writeToFileTiming && tElapsed<(tc+1)*writeToFileTiming           
                dlmwrite(fullfile(pathName,fileName),out(counter,:),'-append','delimiter',',','precision',6);
                tc=tc+1;
            end

        end
        
        
        
        prevCentroids=centroidsTemp;
    end
    
   if mod(counter,100)==0
       cla;
   end
    
    counter=counter+1;
    tElapsed=toc(ticA);
end

%%
fclose(fidA);