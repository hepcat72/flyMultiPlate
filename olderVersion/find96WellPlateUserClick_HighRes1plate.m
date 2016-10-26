function out=find96WellPlateUserClick_HighRes1plate(im,plotBool)
%%

% figure();

% estimate a range of intensities to display for user to click on the
% corners

% convert to grayscale
im2 = rgb2gray(im);

% fit intensities to a gaussian mixture model
gmGrayVals = gmdistribution.fit(double(im2(:)),2);

% % %
% % % to pull out all the values in a field of a matrix, one can use [structureName.fieldName]
% % % display the test image saturating some of the pixels as black and white
% % set(gcf,'color','w');
% % clf(gcf);
% % subplot(5,5,1);
% % % build a diagram to help the user know where to click
% % xCornersOuter = [0,3,60,60,3,0,0];
% % yCornersOuter = [37,40,40,0,0,3,37];
% % xCornersInner = [6,54,54,6,6];
% % yCornersInner = [34,34,6,6,34];
% % a1Position = [6,32];
% % plot(xCornersOuter,yCornersOuter,'k:');
% % hold on;
% % plot(xCornersInner,yCornersInner,'k-');
% 
% % for ii = 1:4
% %     text(xCornersInner(ii),yCornersInner(ii),num2str(ii),'Color','r',...
% %         'HorizontalAlignment','center','VerticalAlignment','middle');
% % end
% % text(a1Position(1),a1Position(2),'A1');
% % 
% % xlim([-3,63]);
% % ylim([-3,43]);
% % axis equal;
% % axis off;
% 
% % subplot(5,5,[6:25]);
% % imshow(im2,[min([gmGrayVals.mu]),max([gmGrayVals.mu])],'i','f');

% apply the image saturation to the image and then look for edges
im3 = im2;
im3(im3<min([gmGrayVals.mu])) = min([gmGrayVals.mu]);
im3(im3>max([gmGrayVals.mu])) = max([gmGrayVals.mu]);
%%
% find the plate and then have the user click on the corner closest to A1
figure(gcf);

% % clf;
thresholdIntensityOfPlate = 0.00898;
imshow(im2,[],'i','f');
%
% normalize intensities between 0 and 1
im3Normalized = double(im3)-min(double(im3(:)));
im3Normalized = double(im3Normalized)./max(double(im3(:)));
% use a simple threshold to segment out the plate
plateBinary = double(im3Normalized<thresholdIntensityOfPlate);
% clean up the mask
plateBinary = imclearborder(plateBinary);
plateBinary = bwmorph(plateBinary,'erode',3);
plateBinary = bwmorph(plateBinary,'open',3);
plateBinary = imfill(plateBinary,'holes');

 imshow(plateBinary,[],'i','f');
%%
% find the area and position of each plate
objects = regionprops(plateBinary,'area','ConvexHull');

% if there are multiple plates, their areas should be similar. Small blobs
% that are not a plate should be small
objectsRemove = [objects.Area]<0.85*max([objects.Area]);
    
% remove small objects;
objects(objectsRemove) = [];

% plot the four corners and connecting edges
hold on;
colormap gray;
%

% these convex hulls are not perfectly straight lines and have somewhat
% rounded corners

% figure(clf);
for iObject = 1:length(objects)
    vectorA = objects(iObject).ConvexHull(1:end-2,:) - objects(iObject).ConvexHull(2:end-1,:);
    vectorB = objects(iObject).ConvexHull(2:end-1,:) - objects(iObject).ConvexHull(3:end,:);
    % magnitude is the sqrt of sum of squared components
    magA = sqrt(sum(vectorA.^2,2));
    magB = sqrt(sum(vectorB.^2,2));
    % some angles are slightly complex
    angleAB = real(acosd((dot(vectorA',vectorB')'./(magA.*magB))));
    
    % if there are angles that are greater than 15 degrees or so, these are
    % not in a 'line'
    lineBreaks = find(angleAB>8);
    
    % loop over each break and calculate the pixel distance between the
    % convex hull points between this and the next break
    for jBreak = 1:(numel(lineBreaks)-1)
        distanceTemp = objects(iObject).ConvexHull(lineBreaks(jBreak),:)-...
            objects(iObject).ConvexHull(lineBreaks(jBreak+1),:);
        
        distances(jBreak) = sqrt(sum(distanceTemp.^2));
    end
    
    % it could be possible to have a break at the end?
    distanceTemp = objects(iObject).ConvexHull(lineBreaks(end),:)-...
        objects(iObject).ConvexHull(lineBreaks(1),:);
    distances(numel(lineBreaks)) = sqrt(sum(distanceTemp.^2));
    
    % keep the longest 4 as the 'sides'
    [~,keepSides_idxBreaks] = sort(distances,'descend');
    keepSides_idxBreaks = keepSides_idxBreaks(1:4);
    hold on;
    for iiSide = 1:4
       sidesIdx = (lineBreaks(keepSides_idxBreaks(iiSide))+1):(lineBreaks(keepSides_idxBreaks(iiSide)+1)+1);
        scatter(objects(iObject).ConvexHull(sidesIdx,1),objects(iObject).ConvexHull(sidesIdx,2),'ks');
        coeffs(iiSide,:) = polyfit(objects(iObject).ConvexHull(sidesIdx,1),objects(iObject).ConvexHull(sidesIdx,2),1);
        plot(xlim,polyval(coeffs(iiSide,:),xlim),'r');
    end
    
    % sometimes (n=1) the fourth line is at a weird orientation. If this
    % happens again, we'll add error handling for making sure that the
    % slopes of the four lines are parallel/perpendicular
    
    % find the intersection between these short and long sides
    for iiSide = 2:4
        aMinusB = coeffs(1,1) - coeffs(iiSide,1);
    intersectsOtherLinesAt(iiSide,1) = (coeffs(iiSide,2) - coeffs(1,2))/aMinusB;
    intersectsOtherLinesAt(iiSide,2) = (coeffs(1,1)*coeffs(iiSide,2) - coeffs(iiSide,1)*coeffs(1,2))/aMinusB;
    
    end
    
    for iiSide = [3,4]
        aMinusB = coeffs(2,1) - coeffs(iiSide,1);
        intersectsOtherLinesAt(iiSide+4,1) = (coeffs(iiSide,2) - coeffs(2,2))/aMinusB;
        intersectsOtherLinesAt(iiSide+4,2) = (coeffs(2,1)*coeffs(iiSide,2) - coeffs(iiSide,1)*coeffs(2,2))/aMinusB;
    end
    
    for iiSide = [4]
        aMinusB = coeffs(3,1) - coeffs(iiSide,1);
        intersectsOtherLinesAt(iiSide+7,1) = (coeffs(iiSide,2) - coeffs(3,2))/aMinusB;
        intersectsOtherLinesAt(iiSide+7,2) = (coeffs(3,1)*coeffs(iiSide,2) - coeffs(iiSide,1)*coeffs(3,2))/aMinusB;
    end
    
    % remove those outside the size of the image
    removeIdxOutsideFrame = any(intersectsOtherLinesAt<1,2);
    removeIdxOutsideFrame = or(removeIdxOutsideFrame,intersectsOtherLinesAt(:,1)>size(im,2));
    removeIdxOutsideFrame = or(removeIdxOutsideFrame,intersectsOtherLinesAt(:,2)>size(im,1));
    intersectsOtherLinesAt(removeIdxOutsideFrame,:) = [];
    
    % display the intersections
    scatter(intersectsOtherLinesAt(:,1),intersectsOtherLinesAt(:,2),'ws');
end
figure(gcf);
%%
title('please click near the A1 corner');
% user should click near the A1 corner
[x,y] = ginput(1);
% % flip in the y dimension
% y = size(im2,1)-y;
distances = sqrt(sum((bsxfun(@minus,intersectsOtherLinesAt,[x,y])).^2,2));
% keyboard
[distanceAwayFromClick,pointIdx] = min(distances);
% in previous nomenclature, this was "lower right??"
A1 = intersectsOtherLinesAt(pointIdx,:);
scatter(A1(1),A1(2),'mo');
% remove as a choice of an position
intersectsOtherLinesAt(pointIdx,:) = [];

% closest to this corner is along the short edge
distances = sqrt(sum((bsxfun(@minus,intersectsOtherLinesAt,A1)).^2,2));
[~,pointIdx] = min(distances);
H1 =  intersectsOtherLinesAt(pointIdx,:);
% remove as a choice of an position
intersectsOtherLinesAt(pointIdx,:) = [];

% next closest (after removing short edge) is long edge
distances = sqrt(sum((bsxfun(@minus,intersectsOtherLinesAt,A1)).^2,2));
[~,pointIdx] = min(distances);
A12 =  intersectsOtherLinesAt(pointIdx,:);
% remove as a choice of an position
intersectsOtherLinesAt(pointIdx,:) = [];

% the only thing that is left is the final
distances = sqrt(sum((bsxfun(@minus,intersectsOtherLinesAt,A1)).^2,2));
[~,pointIdx] = min(distances);
H12 =  intersectsOtherLinesAt(pointIdx,:);
% remove as a choice of an position
intersectsOtherLinesAt(pointIdx,:) = [];

%
% plotBool = true;
% UL = [x(2),y(2)];
% UR = [x(3),y(3)];
% LR = [x(4),y(4)];
% LL = [x(1),y(1)];

wellLeftStart=0.05;
wellRightEnd=0.95;
wellYCorrection=0.95;

if true
edgeAngle=atan2(-(A1(2)- H1(2)),(A1(1)- H1(1)));
% edgeAngle2 = atan2(-A12(2)+H12(2), A12(1)-H12(1));
% edgeAngle = (edgeAngle2+edgeAngle)/2;

edgeLength=sqrt((H1(2)-A1(2))^2+(H1(1)-A1(1))^2);
MP=[(H1(1)+A1(1))/2 (H1(2)+A1(2))/2];
% MP2 = [(LR(1)+LL(1))/2 (LR(2)+LL(2))/2];



longEdgeLength=sqrt((A1(2)-A12(2))^2+(A1(1)-A12(1))^2);

wellColCoords=linspace(wellLeftStart,wellRightEnd,12);
wellAngle=-edgeAngle+pi()/2;
wellColXVec=MP(1)+longEdgeLength*cos(wellAngle)*wellColCoords;
wellColYVec=MP(2)+longEdgeLength*sin(wellAngle)*wellColCoords;
colScale=8/12*(wellRightEnd-wellLeftStart)*longEdgeLength*wellYCorrection;
wellRowCoords=linspace(colScale/2,-colScale/2,8);

wellCoordinates=zeros(96,2);
for i=1:12
    wellXTemp=wellColXVec(i)+cos(edgeAngle)*wellRowCoords;
    wellYTemp=wellColYVec(i)+sin(edgeAngle)*wellRowCoords;
    wellCoordinates((i-1)*8+1:(i-1)*8+8,1)=wellXTemp';
    wellCoordinates((i-1)*8+1:(i-1)*8+8,2)=wellYTemp';
end

if plotBool
    ff=figure;
    subplot(1,2,1);
    set(0,'defaultaxesposition',[0 0 1 1])
    image(im);
    colormap(repmat(linspace(0,1,256)',1,3));
    hold on;
    scatter(A12(1),A12(2),'ro')
    scatter(A1(1),A1(2),'ko')
    scatter(H12(1),H12(2),'wo')
    plot([A1(1) H1(1)],[A1(2) H1(2)],'k-');
    scatter(MP(1),MP(2),'k.')
    plot([MP(1) MP(1)+cos(-edgeAngle+pi()/2)*longEdgeLength],[MP(2) MP(2)+sin(-edgeAngle+pi()/2)*longEdgeLength],'k-');
    scatter(wellCoordinates(:,1),wellCoordinates(:,2),'r.')
    scatter(wellCoordinates(1,1),wellCoordinates(1,2),'w*');
    scatter(wellCoordinates(2,1),wellCoordinates(2,2),'y*');
    scatter(wellCoordinates(9,1),wellCoordinates(9,2),'c*');

    % display the ends of the centerline
    scatter(MP(1),MP(2),'gs')

    hold off;
    F=getframe(gcf);
    [X, ~] = frame2im(F);
%     close(ff);
    out.wellImage=X;
end

out.coords=wellCoordinates;
out.colScale=colScale;

else
   out.coords = nan; 
end