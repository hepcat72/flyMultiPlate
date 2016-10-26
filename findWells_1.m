function [x2, positionParameters] = findWells_1(im3);
%% if there is not input image and this is being called as a function, load up an example image
if nargin<1
   load('im_testCapture2.mat'); 
end
%% adjustable parameters
% size scale of features in the image, for smoothing pixel to pixel noise
% and background subtraction
BLUR_SIZE = 60;
SMOOTH_SIZE = 3;
% saturate a small fraction of pixels to suppress outliers
SATURATE_LOW = 0.01;
SATURATE_HIGH = 0.999;

% find circles within a certain size range
WELLSIZE_SMALL = 10;
WELLSIZE_LARGE = 22;

%% display / output switches
% display four images: raw, background subtracted, smoothed, segmented
IS_DISPLAY_A = false; 

% display coordinates of wells on top of image
IS_DISPLAY_B = true;

%% deprecated parameters

%% setup two different blurring functions
hsmall = fspecial('gaussian',SMOOTH_SIZE*5,SMOOTH_SIZE); % 'smoothed'
hbig = fspecial('gaussian',BLUR_SIZE*5,BLUR_SIZE); % 'blurring'
%% perform some image normalization and background subtraction tasks
% normalize intensity range
im3_1 = double(im3);

% 3_2 is the normalized imaged
im3_2 = im3_1-quantile(im3_1(:),SATURATE_LOW);
im3_2 = im3_2./quantile(im3_2(:),SATURATE_HIGH);

% im_illum is heavily blurred image representing the background
% illumination
im_illum = imfilter(im3_2,hbig);

% im3_3 is a background subtracted image
im3_3 = im3_2 - im_illum;

% im3_4 is a smoothed version of im3_3 
im3_4 = imfilter(im3_3,hsmall);

% % establish a threshold for regions
% im3_5 = im3_4>IM_THRESH;
% 
% properties1 = regionprops(im3_5,'area');
% midSized = median([properties1.Area]);
% [centers,radii,metric] = imfindcircles(im3_4,...
%     round([sqrt(midSized/pi)*.75,sqrt(midSized/pi)*1.7]),...
%     'objectPolarity','bright');

%%
[centers,radii,metric] = imfindcircles(im3_4,...
    [WELLSIZE_SMALL,WELLSIZE_LARGE],...
    'objectPolarity','bright');

% see which circles are overlapping, if anyone is overlapping, keep the one
% with the one with the stronger edge
ii = 1;
bbb = tic;
while  ii < length(radii)
    distanceToCenters = sqrt((centers(:,1)-centers(ii,1)).^2+...
        (centers(:,2)-centers(ii,2)).^2);
    
    % determine which indices are close to this colony
   jj = find(distanceToCenters<(2*radii(ii)));
   
    % find how strength the edge features are
   edgeStrength = metric(jj);
   
    % remove all but the strongest edge
   isRemove = jj(edgeStrength<max(edgeStrength));
   
   
   centers(isRemove,:) = [];
   radii(isRemove) = [];
   metric(isRemove)=  [];

   % increment loop index
    ii = ii+1;
%     disp(ii);
end
%% determine which circles are close to each other

dt1 = delaunayTriangulation(centers);
edges1 = edges(dt1);

% loop over the edges and store their distances
connectedMatrix = nan(length(centers));
for iiEdge = 1:length(edges1)
    % index of circles being compared
    jjCircle = edges1(iiEdge,1);
    kkCircle = edges1(iiEdge,2);
    % the distance between these nearest neighbors should have a peak at
    % "1" and "sqrt 2" and the higher order terms should be much smaller
      connectedMatrix(jjCircle,kkCircle) = sqrt(sum(...
          (centers(jjCircle,:)-centers(kkCircle,:)).^2,2));
 
end

% kernel smoothing density
try

    [pOfDist,dist] = ksdensity(connectedMatrix(:));
% plot(dist,pOfDist)
% find the highest peak in this distribution. A fancier approach would be
% to fit the whole distribution to a set of peaks whose position and
% amplitude matches that of a square lattice nearest neighbor spacing, but
% that seems more complicated than we need
[~,distIndx] = max(pOfDist);
estimateOfScale = dist(distIndx);
catch ME
    estimateOfScale = 10;
end

%%


if IS_DISPLAY_A
% display some images
figure(gcf)
clf
subplot(2,2,1);
imshow(im3_2,[0,1]);
title('raw')

subplot(2,2,2);
imshow(im3_3,[0,1]);
title('background subtracted')

subplot(2,2,3)
imshow(im3_4,[0,1]);
title('smoothed');

subplot(2,2,4)
cla;
imshow(im3_4,[0,1]);
hold on;
viscircles(centers,radii,'color','red');
title('smoothed with autodetected wells');

end

%% user interaction
if or(IS_DISPLAY_A,IS_DISPLAY_B)
    figHand = gcf();
end

figure();
imshow(im3,[]);
hold on;
viscircles(centers,radii,'color','red');
title('please click near A1');

[A1_X,A1_Y] = ginput(1);

close(gcf)

if or(IS_DISPLAY_A,IS_DISPLAY_B)
    figure(figHand);
end
    

%% calculate a grid of points
%
% x2 = xyPositionsOfWells(A1_X,A1_Y,angle,scale,K1,distX0,distY0);
distX0 = size(im3,2)/2;
distY0 = size(im3,1)/2;
estimatedAngle = -160;
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

