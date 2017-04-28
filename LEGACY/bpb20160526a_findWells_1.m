hsmall = fspecial('gaussian',10,3);
hbig = fspecial('gaussian',200,60);
%%
% normalize intensity range
im3_1 = double(im3);
% 3_2 normalized imaged
im3_2 = im3_1-quantile(im3_1(:),0.01);
im3_2 = im3_2./quantile(im3_2(:),0.999);

% im_illum
im_illum = imfilter(im3_2,hbig);

% illumination subtracted
im3_3 = im3_2 - im_illum;

% blurred illum subtracted
im3_4 = imfilter(im3_3,hsmall);

% thresh 
im3_5 = im3_4>0.2;

properties1 = regionprops(im3_5,'area');
midSized = median([properties1.Area]);
[centers,radii,metric] = imfindcircles(im3_4,...
    round([sqrt(midSized/pi)*.75,sqrt(midSized/pi)*1.7]),...
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

% im3_1 = imfilter(double(im3),hbig);
% imshow(double(im3)-im3_1,[]);

% display some images
subplot(2,2,1);
imshow(im3_2,[0,1]);

subplot(2,2,2);
imshow(im3_3,[0,1]);

subplot(2,2,3)
imshow(im3_4,[0,1]);

subplot(2,2,4)
cla;
imshow(im3_4,[0,1]);
hold on;
% viscircles(centers,radii,'color','red');




%
xPos = repmat(1:12,8,1);
yPos = repmat([1:8]',1,12);

% x/y offset
xOffset = 700;
yOffset = 175;

% scale
scale = 66;
angle = -90;
rotMat = [[cosd(angle),sind(angle)];[-sind(angle),cosd(angle)]];

[x2] = rotMat*[xPos(:)';yPos(:)'];
x2 = scale*x2;
x2 = bsxfun(@plus, x2,[xOffset;yOffset]);
scatter(x2(1,:),x2(2,:),'bx');
scatter(x2(1,1),x2(2,1),'bs');

% 
