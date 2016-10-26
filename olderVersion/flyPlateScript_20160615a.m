% experiment parameters
experimentLength = 259200;               % Length of the trial in seconds
% imageWidth = 1320;                              % Dimensions of the image in Width & Height
% imageHeight = 1048;
refStackSize = 11;                     % Number of reference images
refStackUpdateTiming = 5;              % How often to update a ref image
% screenUpdateTiming = 60;                % How often to update the image on screen
writeToFileTiming = 10;                   % How often to update the image on screen
%% initialization

close all;
clear refStack;
clear refImage;

[fileName, pathName] = uiputfile([datestr(now,'yyyymmdd-HHMMSS'),'.csv']);

imaqreset;
pause(1);
vid = videoinput('pointgrey', 1, 'F7_BayerRG8_664x524_Mode1');     % Video inputs; depends on the type of camera used
% vid = videoinput('pointgrey',1,'F7_BayerRG8_1328x1048_Mode0');
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

%fly position extraction parameters
% fakeBright = 110;
% ROIScale = 0.9 /2;
trackingThreshold = 12;
% slidingWindow = 2;

tic;
counter=1;
tElapsed=0;
% added by Bomyi
tc = 1;

% figure;
% % hold on;
% subplot(1,3,1);
% 
% im=peekdata(vid,1);                     % acquire image from camera
% im=squeeze(im(:,:,imagingLayer));                  % Extracting the red channel (works the best)
% refStack=double(im);
% out=[];
%% start by previewing the image to adjust alignment and focus
fig1 = figure();
try % start the camera if it is not already started
    start(vid);
catch ME
end

while ishghandle(fig1)
    pause(0.01);
im = (peekdata(vid,1));
im = rgb2gray(im);
imshow(im,[],'i','f');
drawnow;
title('preview: adjust contrast/focus/brightness');
end

% preview(vid);


%% find the circular features and establish where the wells are
try % start the camera if it is not already started
    start(vid);
catch ME
end
im = (peekdata(vid,1));
im = rgb2gray(im);
[x2,positionParameters] = findWells_1(im);
ROISize=abs(round(positionParameters(4)/2));

refStack=double(im);

%%
x2 = (x2');
wellCoordinates = round(x2);
%% get file ready for writing
fidA = fopen(fullfile(pathName,fileName),'w');
fprintf(fidA,'time_sec,');
for jjCol = 1:12
    for jjRow = 1:8
        wellName = [char(73-jjRow),num2str(jjCol)];
        fprintf(fidA,[wellName, '_x,', wellName, '_y,']);
    end
end
fprintf(fidA,'\r\n');
%
%% run experiment
imshowHand = nan;
while tElapsed < experimentLength           % main experimental loop
    wellCoordinates = round(x2);
    im = (peekdata(vid,1));
    im = rgb2gray(im);
    im = double(im);
    
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
        
        for i=1:96
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
        %         clf;
%         subplot(1,3,1:2);
        % saturate the image slightly for display purposes;
        tempIm2 = tempIm./255;
        tempIm2 = tempIm2-0.02;
        tempIm2(tempIm2>.2) = 0.1;
        tempIm2(tempIm2<0) = 0;
        tempIm2 = tempIm2./0.2;
        if not(ishghandle(imshowHand))
        imshowHand = imshow(tempIm2,[],'initialMag','fit');
        else
            set(imshowHand,'Cdata',tempIm2);
        end
        pause(0.01);
        out(counter,:)=[tElapsed reshape(centroidsTemp',1,96*2)];
        if exist('prevCentroids','var')
%             speeds=sqrt((centroidsTemp(:,1)-prevCentroids(:,1)).^2+(centroidsTemp(:,2)-prevCentroids(:,2)).^2);
%             speeds=speeds/(tElapsed-out(counter-1,1));
%             speeds=speeds*8.6/(colScale/7); %convert pixel speeds to mm/s
%             out(counter,2)=nanmean(speeds);
%             out(counter,3)=nanstd(speeds);
%             out(counter,4)=mean(out(max([1 counter-slidingWindow*13]):counter,2));
%             subplot(1,3,3);
%             hold on;
%             scatter(out(:,1),out(:,2),'k.');
%             plot(out(:,1),out(:,4),'r-');
%             hold off;
%             ylim([0 10]);
%             xlim([0 max([60 tElapsed])]);
%             drawnow;
            
            if tElapsed < 5.1 
                dlmwrite(fullfile(pathName,fileName),out(counter,:),'-append','delimiter',',','precision',6);
            elseif tElapsed>tc*writeToFileTiming && tElapsed<tc*writeToFileTiming+1            
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
    tElapsed=toc;
end
