function [ ouptutCoords ] = repositionCrosses( inputImage,inputCoords,markerWidth )
%%
if nargin==0
    inputImage = imread('pout.tif');
    [inputCoordA,inputCoordB] = meshgrid(10:60:240,10:40:240);
    inputCoords = ([inputCoordA(:),inputCoordB(:)]);
    markerWidth = 6;
end
 
%%
% Create a new figure and display the image and position of wells
figHandle = figure('ResizeFcn', @setmarkersize);

% set(figHandle,'gui_OutputFcn',  @Gui_OutputFcn)
% 
% if nargout
%     [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
% else
%     gui_mainfcn(gui_State, varargin{:});
% end
 
% function varargout = gui_mainfcn
imshow(inputImage,[],'InitialMag','Fit');
hold on;
msg = 'Click to select, then move using arrow keys. Move fast using shift+arrow';
disp(msg)
title(msg);
for ii = 1:length(inputCoords);
    h1(ii) = scatter(inputCoords(ii,1),inputCoords(ii,2));
end
% default colors
dispColor.outline = 'blue';
dispColor.selected = [1,0,0];
dispColor.modified = 'green';
setappdata(figHandle,'dispColor',dispColor);
setappdata(figHandle,'h1',h1);

%Make the marker size relative to the image scale/axes
setappdata(figHandle,'markerWidth',markerWidth);
setmarkersize(figHandle);

% set the color
set(h1,'MarkerFaceColor','none');
set(h1,'MarkerEdgeColor',dispColor.outline);
 
% set up the key/mouse hooks
set(figHandle,'WindowKeyPressFcn',@keyHookFunction);
% set(figHandle,'WindowKeyReleaseFcn',@keyReleaseFunction);
set(figHandle,'WindowButtonDownFcn',@windowButtonDownCallback);
 
% how to handle figure window closures
set(figHandle,'CloseRequestFcn',@closeFigure);
 
updateTriangulation(figHandle);
 
uiwait(figHandle)
h1 = getappdata(figHandle,'h1');
for ii = 1:length(h1)
    ouptutCoords(ii,1) = get(h1(ii),'XData');
    ouptutCoords(ii,2) = get(h1(ii),'YData');
end
  
delete(figHandle)

function [ ] = setmarkersize( src, ~ )
    % resize the marker
    pointFactor = 0.58139; % 1/1.72 (conversion from data to "points")
    % get position of the figure (pos = [x, y, width, height]) 
    pos = get(src, 'Position'); 
    % get the scattergroup object 
    h = getappdata(src,'h1');
    markerWidth = getappdata(src,'markerWidth') * pointFactor;
    newMarkerWidth = markerWidth/diff(xlim)*pos(3);
    set(h,'SizeData', newMarkerWidth^2); 

function toggleDisplay(src);
h1 = getappdata(src,'h1');
if strcmp(get(h1(1),'Visible'),'on');
    set(h1,'Visible','off');
else
    set(h1,'Visible','on');
end
 
function keyHookFunction(src,evnt)
% set up step sizes for moving spots
if strcmp(evnt.Modifier,'shift');
    stepSize = 5;
else
    stepSize = 1;
end
switch evnt.Key
    case {'rightarrow'};
         
        moveRight(src,stepSize);
    case {'leftarrow'};
        moveLeft(src, stepSize);
    case {'uparrow'};
        moveUp(src,stepSize);
    case {'downarrow'};
        moveDown(src,stepSize);
    case {'u'};
        if strcmp(evnt.Modifier,'control');
            updateTriangulation(src);
        end
    case {'h'};
        if or(strcmp(evnt.Modifier,'control'),...
                strcmp(evnt.Modifier,'command'));
            toggleDisplay(src);
        end
         
    otherwise
end

function windowButtonDownCallback(h,evd)
initialUnits = get(h,'Units');
 
% get the current point in axis units
axHand = gca;
cpAxisUnits = get(axHand, 'CurrentPoint');
 
xPos = cpAxisUnits(1,1);
yPos = cpAxisUnits(1,2);
cursorStartAxNorm = [xPos,yPos];
 
% title(num2str(cursorStartAxNorm));
dt1 = getappdata(get(axHand,'parent'),'dt1');
dispColor = getappdata(get(axHand,'parent'),'dispColor');
[nearestNeighborIndex,dist] = nearestNeighbor(dt1,[xPos,yPos]);
h1 = getappdata(get(axHand,'parent'),'h1');
 
for ii =1:length(h1)
    if isequal(get(h1(ii),'MarkerEdgeColor'),(dispColor.selected));
        set(h1(ii),'MarkerEdgeColor',dispColor.modified)
    end
end
 
if dist<15
    set(h1(nearestNeighborIndex),'MarkerEdgeColor',dispColor.selected);
    setappdata(get(axHand,'parent'),'selectedHandle',h1(nearestNeighborIndex));
else
    dispColor = getappdata(get(axHand,'parent'),'dispColor');
    set(h1,'MarkerEdgeColor',dispColor.outline);
    setappdata(get(axHand,'parent'),'selectedHandle',nan);
end
 
 
 
 
%
% setappdata(h,'cursorStartAxNorm',cursorStartAxNorm )
%
% %   Y = HGCONVERTUNITS(FIG, X, SRCUNITS, DESTUNITS, REF) converts
% %   rectangle X in figure FIG from units SRCUNITS to DESTUNITS
% %   using the object with handle REF as the reference container for
% %   normalized units. REF can be the root object.
% % y = hgconvertunits(ancestor(h,'figure'), [cursorStart, 0, 0], initialUnits,
% currentPointFig = get(h,'CurrentPoint');
% startPointFigNorm = hgconvertunits(h, [currentPointFig 0 0], get(h,'Units'), 'normalized', h);
%
% % initialize the box
% boxLine(1) = annotation(h, 'line', [0 .5-0.2], [.5 .5]);
% boxLine(2) = annotation(h, 'line', [0 .5-0.2], [.5 .5]);
% boxLine(3) = annotation(h, 'line', [0 .5-0.2], [.5 .5]);
% boxLine(4) = annotation(h, 'line', [0 .5-0.2], [.5 .5]);
%
% % set the handles for the box like the full crosshair in ginput
% set(boxLine, 'LineWidth', 1, 'Visible','off',...
%     'HandleVisibility', 'off', ...
% 'HitTest', 'off');
%
% boxLineColor = getappdata(h,'boxLineColor');
% set(boxLine,'Color',boxLineColor);
%
% % store some this data
% setappdata(h,'startPointFigNorm',startPointFigNorm);
% setappdata(h,'boxLine',boxLine);
%
% % get the values and store them in the figure's appdata
% props.WindowButtonMotionFcn = get(h,'WindowButtonMotionFcn');
% props.WindowButtonUpFcn = get(h,'WindowButtonUpFcn');
% props.Units = initialUnits;
% setappdata(h,'TestGuiCallbacks',props);
 
% set the new values for the WindowButtonMotionFcn and
% WindowButtonUpFcn
% set(h,'WindowButtonMotionFcn',{@windowButtonMotionCallback})
% set(h,'WindowButtonUpFcn',{@windowButtonUpCallback})
 
function updateTriangulation(src);
h1 = getappdata(src,'h1');
 
for iiPosition = 1:length(h1)
    xx(iiPosition,1) = get(h1(iiPosition),'XData');
    xx(iiPosition,2) = get(h1(iiPosition),'YData');
end
 
dt1 = delaunayTriangulation(xx);
 
setappdata(src,'dt1',dt1);
 
 
function closeFigure(figHandle,varargin)
 
if isequal(get(figHandle, 'waitstatus'), 'waiting')
% The GUI is still in UIWAIT, us UIRESUME
uiresume(figHandle);
else
% The GUI is no longer waiting, just close it
delete(figHandle);
end
 
 
 
function moveRight(figHandle,stepSize)
 
selectedHandle = getappdata(figHandle,'selectedHandle');
if ishghandle(selectedHandle)
    xPos = get(selectedHandle,'XData');
    set(selectedHandle,'XData',xPos+stepSize)
end
updateTriangulation(figHandle);
 
 
function moveLeft(figHandle,stepSize)
 
selectedHandle = getappdata(figHandle,'selectedHandle');
if ishghandle(selectedHandle)
    xPos = get(selectedHandle,'XData');
    set(selectedHandle,'XData',xPos-stepSize)
end
updateTriangulation(figHandle);
 
 
function moveUp(figHandle,stepSize)
 
selectedHandle = getappdata(figHandle,'selectedHandle');
if ishghandle(selectedHandle)
    yPos = get(selectedHandle,'YData');
    set(selectedHandle,'YData',yPos-stepSize)
end
updateTriangulation(figHandle);
 
function moveDown(figHandle,stepSize)
 
selectedHandle = getappdata(figHandle,'selectedHandle');
if ishghandle(selectedHandle)
    yPos = get(selectedHandle,'YData');
    set(selectedHandle,'YData',yPos+stepSize)
end
updateTriangulation(figHandle);
 

