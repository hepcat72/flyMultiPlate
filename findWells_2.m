function [x2, positionParameters] = findWells_2(im3);
%% if there is not input image and this is being called as a function, load up an example image
if nargin<1
   load('im_testCapture2.mat'); 
end

imshow(im3,[]);
title('Please select well A1');
[A1_X,A1_Y] = ginput(1);

title('Please select well A8');
[A8_X,A8_Y] = ginput(1);
close(gcf);

% distance between these two wells
estimatedAngle = mod(atan2d(A1_X-A8_X,A1_Y-A8_Y),360)-180;
estimateOfScale = sqrt((A1_Y-A8_Y)^2+(A1_X-A8_X)^2)/7; % seven interwell spacings between A1 and A8

distX0 = size(im3,2)/2;
distY0 = size(im3,1)/2;
estimatedK1 = 0;
%%
disp([A1_X,A1_Y,estimatedAngle,estimateOfScale,estimatedK1,distX0,distY0]);
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
positionParameters = multiPlateTrackerGUI(im3,[A1_X,A1_Y,estimatedAngle,estimateOfScale,estimatedK1,distX0,distY0]);
x2 = xyPositionsOfWells(positionParameters);

%

