function [xyPos] = xyPositionsOfWells(varargin);
% three different usage types for the input
% xyPositionsOfWells(A1_X,A1_Y,angle,scale,K1,distX0,distY0);
% xyPositionsOfWells([A1_X,A1_Y,angle,scale,K1,distX0,distY0]);
% xyPositionsOfWells(inputParametersStructure);
if nargin < 2
    % input came in as a structure
    if isstruct(varargin{1})
        v2struct(varargin{1});
    else % a matrix with all the inputs in it
        A1_X = varargin{1}(1);
        A1_Y = varargin{1}(2);
        angle = varargin{1}(3);
        scale = varargin{1}(4);
        K1 = varargin{1}(5);
        distX0 = varargin{1}(6);
        distY0 = varargin{1}(7);
    end
else
    A1_X = varargin{1};
    A1_Y = varargin{2};
    angle = varargin{3};
    scale = varargin{4};
    K1 = varargin{5};
    distX0 = varargin{6};
    distY0 = varargin{7};
end

%% initial/naive coordinates
% starts at [0,0]
x1 = repmat(1:12,8,1)-1;
x2 = repmat((1:8)',1,12)-1;

%% apply rotation
% calculate the rotation matrix for the given orienation angle
rotMat = [[cosd(angle),sind(angle)];...
    [-sind(angle),cosd(angle)]];


[x2] = rotMat*[x1(:)';x2(:)'];

%% scale
x2 = scale*x2;

%% move to the correct offset
x2 = bsxfun(@plus, x2,[A1_X;A1_Y]);

%% apply pincushion correction

% distance to center of distortion
r = sqrt((x2(1,:)-distX0).^2+(x2(2,:)-distY0).^2)/scale;
% distortion factor
u = x2(1,:).*(1+K1.*r.^2);
v = x2(2,:).*(1+K1.*r.^2);
xyPos = cat(1,u,v);
% % if one needs to resample the image to apply this distortion, here's a
% % snippet. For this function, I only need the new coordinates
% tmap_B = cat(3,u,v);
% resamp = makeresampler('cubic','fill');
% 
% I_barrel = tformarray(I,[],resamp,[2 1],[1 2],[],tmap_B,.3);

