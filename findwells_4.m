function [x2, positionParameters] = findWells_4(camsToUse,ims)
%% This version of the function handles multiple cameras - Rob

%% if there is not input image and this is being called as a function, load up an example image
if nargin<2
   load('im_testCapture2.mat'); 
end

x2 = [];
globalPlateNum = 0;
for camIdx = 1:numel(camsToUse)
    nPlatesString = newid(['How many plates for cam ' num2str(camsToUse{camIdx}) '?'],['Number of plates for cam ' num2str(camsToUse{camIdx})],1,{'1'});
    im4 = ims{camIdx};
    for iiPlate = 1:str2double(nPlatesString{1})

        globalPlateNum = globalPlateNum + 1;
        imshow(im4,[]);
        title(['Please select plate ',num2str(iiPlate), ': well A1']);
        [A1_X,A1_Y] = ginput(1);
        
        title(['Please select plate ',num2str(iiPlate), ': well A8']);
        [A8_X,A8_Y] = ginput(1);
        close(gcf);
        
        % distance between these two wells
        estimatedAngle = mod(atan2d(A1_X-A8_X,A1_Y-A8_Y),360)-180;
        estimateOfScale = sqrt((A1_Y-A8_Y)^2+(A1_X-A8_X)^2)/7; % seven interwell spacings between A1 and A8
        
        distX0 = size(im4,2)/2;
        distY0 = size(im4,1)/2;
        estimatedK1 = 0;
        %%
        if str2double(nPlatesString{1})>1
        else
            disp([A1_X,A1_Y,estimatedAngle,estimateOfScale,estimatedK1,distX0,distY0]);
        end

        %%
        % manually modify parameters
        % A1_X = 599.5000 ;
        % A1_Y = 235.5000;
        % estimatedAngle = 91;
        % estimateOfScale = -58;
        % estimatedK1 = -0.0002;
        % distX0 = 664.0000;
        % distY0 = 524.0000;
        
        %
        
        %%
        positionParameters{globalPlateNum} = multiPlateTrackerGUI(im4,[A1_X,A1_Y,estimatedAngle,estimateOfScale,estimatedK1,distX0,distY0]);
        x2 = cat(2,x2,xyPositionsOfWells(positionParameters{globalPlateNum}));
    end
end

%

