function [x2, positionParameters] = findwells(camID,im3)

% Note: 'im3' is a variable name that is saved inside multiPlateTrackerGUI.mat,
% so if it is changed, the example image will not load and an error will be
% generated.

%% if there is no input image and this is being called as a function, load up
%% an example image
if nargin<1
    load('multiPlateTrackerGUI.mat');
    camID = 1;
elseif nargin<2
    load('multiPlateTrackerGUI.mat');
end

nPlatesString = inputdlg(['How many plates for cam ' num2str(camID) '?'],...
                         ['Number of plates for cam ' num2str(camID)],1,{'1'});
x2 = [];

for iiPlate = 1:str2double(nPlatesString{1})

    imshow(im3,[],'initialMag','fit','Border','tight');
    title(['Please select plate ',num2str(iiPlate), ': well A1']);
    [A1_X,A1_Y] = ginput(1);

    title(['Please select plate ',num2str(iiPlate), ': well A8']);
    [A8_X,A8_Y] = ginput(1);
    close(gcf);

    % distance between these two wells
    estimatedAngle = mod(atan2d(A1_X-A8_X,A1_Y-A8_Y),360)-180;
    % 7 interwell spacings between A1 and A8
    estimateOfScale = sqrt((A1_Y-A8_Y)^2+(A1_X-A8_X)^2)/7;

    distX0 = size(im3,2)/2;
    distY0 = size(im3,1)/2;
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

    %%
    positionParameters{iiPlate} = multiPlateTrackerGUI(im3,[A1_X,A1_Y,estimatedAngle,estimateOfScale,estimatedK1,distX0,distY0]);
    x2 = cat(2,x2,xyPositionsOfWells(positionParameters{iiPlate}));
end

%

