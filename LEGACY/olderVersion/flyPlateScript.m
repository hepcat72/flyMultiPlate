close all;
clear refStack;
clear refImage;

experimentLength = 259200;               % Length of the trial in seconds
W = 664;                              % Dimensions of the image in Width & Height
H = 524;
refStackSize = 11;                     % Number of reference images
% refStack=zeros(H,W,refStackSize);   % Initialize the ref stack
refStackUpdateTiming = 5;              % How often to update a ref image
screenUpdateTiming = 60;                % How often to update the image on screen
%refStackoutputTiming=refStackUpdateTiming+20;
imagingLayer = 1;

fileName = uiputfile;

imaqreset;
pause(1);
vid = videoinput('pointgrey', 1, 'F7_BayerRG8_664x524_Mode1');     % Video inputs; depends on the type of camera used
pause(1);
src = getselectedsource(vid);
triggerconfig(vid,'manual');                                       % Set all parameters to manual and define the best set
set(vid,'ReturnedColorSpace','rgb');
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

% % well automatic position extraction parameters
% % not necessary if final96WellPlate function works
% wellExtractionThreshold = 250;
% knobSizeMin = 500;
% knobSizeMax = 760;
% wellLeftStart = 0.19;
% wellRightEnd = 0.835;
% wellYCorrection = 0.965;

%fly position extraction parameters
fakeBright = 110;
ROIScale = 0.9 /2;
trackingThreshold = 27;
slidingWindow = 2;

tic;
counter=1;
tElapsed=0;
% added by Bomyi
tc = 1;

figure;
% hold on;
subplot(1,3,1);

im=peekdata(vid,1);                     % acquire image from camera
im=squeeze(im(:,:,imagingLayer));                  % Extracting the red channel (works the best)
refStack=double(im);
out=[];
%%
while tElapsed < experimentLength           % main experimental loop
    im=peekdata(vid,1);                     % acquire image from camera
    im=squeeze(im(:,:,imagingLayer));                  % extract red channel
    im=double(im);
    
    if mod(tElapsed,refStackUpdateTiming) > mod(toc,refStackUpdateTiming) % detect every ref frame update
        if size(refStack,3) == refStackSize      % if the current size of ref images reaches the refstacksize defined above
            refStack=cat(3,refStack(:,:,2:end),im); % update the ref stack by replacing the last ref image by the new ref image
        else
            refStack=cat(3,refStack,im);
        end
        refImage=median(refStack,3); % the actual ref image displayed is the median image of the refstack
        disp(['mean refImage brightness is ' num2str(mean(mean(refImage)))]);
        if size(refStack,3)==2
            foundWells=find96WellPlate(im,1);
            %subplot(1,3,1);
            plot image(foundWells.wellImage);
        else
            foundWells=find96WellPlate(im,0);
        end

        wellCoordinates=round(foundWells.coords);
        colScale=foundWells.colScale;
        ROISize=round((colScale/7)*ROIScale);
        
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
            tempIm((mod(i-1,8))*(ROISize*2+2)+(ROISize:3*ROISize),(((i-1)-mod(i-1,8))/8)*(ROISize*2+2)+(ROISize:3*ROISize),2)=bkImSmall;
            tempIm((mod(i-1,8))*(ROISize*2+2)+(ROISize:3*ROISize),(((i-1)-mod(i-1,8))/8)*(ROISize*2+2)+(ROISize:3*ROISize),3)=bkImSmall;
            tempIm((mod(i-1,8))*(ROISize*2+2)+(ROISize:3*ROISize),(((i-1)-mod(i-1,8))/8)*(ROISize*2+2)+(ROISize:3*ROISize),1)=diffImSmall;
            xCentroid=sum(diffImSmall,1);
            xCentroid=sum(xCentroid.*(1:2*ROISize+1))/sum(xCentroid);
            yCentroid=sum(diffImSmall,2);
            yCentroid=sum(yCentroid'.*(1:2*ROISize+1))/sum(yCentroid);
            centroidsTemp(i,:)=[xCentroid yCentroid];
        end
        %         clf;
        subplot(1,3,2);
        image(tempIm/255)
        pause(0.01);
        out(counter,:)=[tElapsed NaN NaN NaN reshape(centroidsTemp',1,96*2)];
        if exist('prevCentroids','var')
            speeds=sqrt((centroidsTemp(:,1)-prevCentroids(:,1)).^2+(centroidsTemp(:,2)-prevCentroids(:,2)).^2);
            speeds=speeds/(tElapsed-out(counter-1,1));
            speeds=speeds*8.6/(colScale/7); %convert pixel speeds to mm/s
            out(counter,2)=nanmean(speeds);
            out(counter,3)=nanstd(speeds);
%             out(counter,4)=mean(out(max([1 counter-slidingWindow*13]):counter,2));
            subplot(1,3,3);
            hold on;
            scatter(out(:,1),out(:,2),'k.');
%             plot(out(:,1),out(:,4),'r-');
            hold off;
            ylim([0 10]);
            xlim([0 max([60 tElapsed])]);
            drawnow;
            
            if tElapsed < 5.1 
                dlmwrite(fileName,out(counter,:),'-append','delimiter','\t','precision',6);
            elseif tElapsed>tc*60 && tElapsed<tc*60+1            
                dlmwrite(fileName,out(counter,:),'-append','delimiter','\t','precision',6);
                tc=tc+1;
            end
        end
        
        
        
        prevCentroids=centroidsTemp;
    end
    
   if mod(counter,100)==0
       clf;
   end
    
    counter=counter+1;
    tElapsed=toc;
end