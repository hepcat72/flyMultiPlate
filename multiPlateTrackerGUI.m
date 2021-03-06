function varargout = multiPlateTrackerGUI(varargin)
% MULTIPLATETRACKERGUI MATLAB code for multiPlateTrackerGUI.fig
%      MULTIPLATETRACKERGUI, by itself, creates a new MULTIPLATETRACKERGUI or raises the existing
%      singleton*.
%
%      H = MULTIPLATETRACKERGUI returns the handle to a new MULTIPLATETRACKERGUI or the handle to
%      the existing singleton*.
%
%      MULTIPLATETRACKERGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MULTIPLATETRACKERGUI.M with the given input arguments.
%
%      MULTIPLATETRACKERGUI('Property','Value',...) creates a new MULTIPLATETRACKERGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before multiPlateTrackerGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to multiPlateTrackerGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help multiPlateTrackerGUI

% Last Modified by GUIDE v2.5 17-Oct-2016 15:25:31

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @multiPlateTrackerGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @multiPlateTrackerGUI_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before multiPlateTrackerGUI is made visible.
function multiPlateTrackerGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to multiPlateTrackerGUI (see VARARGIN)

% Choose default command line output for multiPlateTrackerGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

if numel(varargin)==0
    load('multiPlateTrackerGUI.mat');
else
    im3 = varargin{1};
    initialSettings = varargin{2};
    set(handles.editA1X,'String',num2str(initialSettings(1)));
    set(handles.sliderA1X,'Value',initialSettings(1));
    
    set(handles.editA1Y,'String',num2str(initialSettings(2)));
    set(handles.sliderA1Y,'Value',initialSettings(2));

    set(handles.editAngle,'String',num2str(initialSettings(3)));
    set(handles.sliderAngle,'Value',initialSettings(3));

    set(handles.editScale,'String',num2str(initialSettings(4)));
    set(handles.sliderScale,'Value',initialSettings(4));

    set(handles.editK1,'String',num2str(initialSettings(5)));
    set(handles.sliderK1,'Value',initialSettings(5));

    set(handles.editX0,'String',num2str(initialSettings(6)));
    set(handles.sliderX0,'Value',initialSettings(6));

    set(handles.editY0,'String',num2str(initialSettings(7)));
    set(handles.sliderY0,'Value',initialSettings(7));
    
    plateType = varargin{3};
end

setappdata(handles.figure1,'im3',im3);
setappdata(handles.figure1,'pType',plateType);
updateImage(handles);


% UIWAIT makes multiPlateTrackerGUI wait for user response (see UIRESUME)
uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = multiPlateTrackerGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

A1X =  str2double(get(handles.editA1X,'String'));
A1Y =  str2double(get(handles.editA1Y,'String'));
estAngle =  str2double(get(handles.editAngle,'String'));
estScale =  str2double(get(handles.editScale,'String'));
K1 =  str2double(get(handles.editK1,'String'));
X0 =  str2double(get(handles.editX0,'String'));
Y0 =  str2double(get(handles.editY0,'String'));

% Get default command line output from handles structure
% varargout{1} = handles.output;
if nargout>0
    varargout{1} = [A1X,A1Y,estAngle,estScale,K1,X0,Y0];
else
    disp([A1X,A1Y,estAngle,estScale,K1,X0,Y0]);
end

% The figure can be deleted now
delete(handles.figure1);



% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of pushbutton1


% --- Executes on button press in togglebutton1.
function togglebutton1_Callback(hObject, eventdata, handles)
% hObject    handle to togglebutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of togglebutton1


% --- Executes on slider movement.
function slider2_Callback(hObject, eventdata, handles)
% hObject    handle to slider2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
% 
% im3 = getappdata(handles.figure1,'im3');
% im3 = double(im3);
% cla(handles.axes1);
% hold(handles.axes1,'off');
% imshow(im3,[],'Parent',handles.axes1);
% hold(handles.axes1,'on');
% xPos = repmat(1:12,8,1);
% yPos = repmat([1:8]',1,12);
% 
% % x/y offset
% xOffset = 700;
% yOffset = 175;
% 
% % scale
% scale = 66;
% angle = -90;
% rotMat = [[cosd(angle),sind(angle)];[-sind(angle),cosd(angle)]];
% 
% [x2] = rotMat*[xPos(:)';yPos(:)'];
% x2 = scale*x2;
% x2 = bsxfun(@plus, x2,[xOffset;yOffset]);
% scatter(x2(1,:),x2(2,:),'bx');
% scatter(x2(1,1),x2(2,1),'bs');



% 
% inputSize = 50;
% I = checkerboard(inputSize,4);
% 
% nRows = size(I,1);
% nCols = size(I,2);
% [xi,yi] = meshgrid(1:nRows,1:nCols);
% imid = round(size(I,2)/2); % Find index of middle element
% 
% xc = imid;
% yc = imid;
% xi = xi - xc;
% yi = yi - yc;
% 
% 
% 
% K1 = (get(handles.slider2,'Value')-0.5)/100000000; % pincushion and barrel distortion
% 
% r = sqrt((xi-xc).^2+(yi-yc).^2);
% 
% u = xi*(1+K1.*r.^2);
% v = yi*(1+K1.*r.^2);
% 
% tmap_B = cat(3,u,v);
% resamp = makeresampler('cubic','fill');
% 
% I_barrel = tformarray(I,[],resamp,[2 1],[1 2],[],tmap_B,.3);
% 
% imshow(I_barrel,[],'Parent',handles.axes1)
% title('barrel')

% --- Executes during object creation, after setting all properties.
function slider2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function slider7_Callback(hObject, eventdata, handles)
% hObject    handle to slider7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function slider7_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function edit5_Callback(hObject, eventdata, handles)
% hObject    handle to edit5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit5 as text
%        str2double(get(hObject,'String')) returns contents of edit5 as a double


% --- Executes during object creation, after setting all properties.
function edit5_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function sliderScale_Callback(hObject, eventdata, handles)
% hObject    handle to sliderScale (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

set(handles.editScale,'String',num2str(get(hObject,'Value')));
updateImage(handles);

% --- Executes during object creation, after setting all properties.
function sliderScale_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderScale (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function editScale_Callback(hObject, eventdata, handles)
% hObject    handle to editScale (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editScale as text
%        str2double(get(hObject,'String')) returns contents of editScale as a double

set(handles.sliderScale,'Value',str2double(get(hObject,'String')));
updateImage(handles)

% --- Executes during object creation, after setting all properties.
function editScale_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editScale (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function sliderAngle_Callback(hObject, eventdata, handles)
% hObject    handle to sliderAngle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

set(handles.editAngle,'String',num2str(get(hObject,'Value')));
updateImage(handles);

% --- Executes during object creation, after setting all properties.
function sliderAngle_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderAngle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function editAngle_Callback(hObject, eventdata, handles)
% hObject    handle to editAngle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editAngle as text
%        str2double(get(hObject,'String')) returns contents of editAngle as a double

set(handles.sliderAngle,'Value',str2double(get(hObject,'String')));
updateImage(handles)

% --- Executes during object creation, after setting all properties.
function editAngle_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editAngle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function sliderK1_Callback(hObject, eventdata, handles)
% hObject    handle to sliderK1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

set(handles.editK1,'String',num2str(get(hObject,'Value')));
updateImage(handles);

% --- Executes during object creation, after setting all properties.
function sliderK1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderK1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function editK1_Callback(hObject, eventdata, handles)
% hObject    handle to editK1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editK1 as text
%        str2double(get(hObject,'String')) returns contents of editK1 as a double
set(handles.sliderK1,'Value',str2double(get(hObject,'String')));
updateImage(handles)

% --- Executes during object creation, after setting all properties.
function editK1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editK1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function sliderA1X_Callback(hObject, eventdata, handles)
% hObject    handle to sliderA1X (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

set(handles.editA1X,'String',num2str(get(hObject,'Value')));
updateImage(handles);

% --- Executes during object creation, after setting all properties.
function sliderA1X_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderA1X (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function editA1X_Callback(hObject, eventdata, handles)
% hObject    handle to editA1X (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editA1X as text
%        str2double(get(hObject,'String')) returns contents of editA1X as a double
set(handles.sliderA1X,'Value',str2double(get(hObject,'String')));
updateImage(handles)

% --- Executes during object creation, after setting all properties.
function editA1X_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editA1X (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function sliderA1Y_Callback(hObject, eventdata, handles)
% hObject    handle to sliderA1Y (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

set(handles.editA1Y,'String',num2str(get(hObject,'Value')));
updateImage(handles);

% --- Executes during object creation, after setting all properties.
function sliderA1Y_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderA1Y (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function editA1Y_Callback(hObject, eventdata, handles)
% hObject    handle to editA1Y (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editA1Y as text
%        str2double(get(hObject,'String')) returns contents of editA1Y as a double
set(handles.sliderA1Y,'Value',str2double(get(hObject,'String')));
updateImage(handles)

% --- Executes during object creation, after setting all properties.
function editA1Y_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editA1Y (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit8_Callback(hObject, eventdata, handles)
% hObject    handle to edit8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit8 as text
%        str2double(get(hObject,'String')) returns contents of edit8 as a double


% --- Executes during object creation, after setting all properties.
function edit8_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu1.
function popupmenu1_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu1


% --- Executes during object creation, after setting all properties.
function popupmenu1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu2.
function popupmenu2_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu2


% --- Executes during object creation, after setting all properties.
function popupmenu2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton2.
function pushbutton2_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton3.
function pushbutton3_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in togglebutton2.
function togglebutton2_Callback(hObject, eventdata, handles)
% hObject    handle to togglebutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on slider movement.
function sliderX0_Callback(hObject, eventdata, handles)
% hObject    handle to sliderX0 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


set(handles.editX0,'String',num2str(get(hObject,'Value')));
updateImage(handles);

% --- Executes during object creation, after setting all properties.
function sliderX0_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderX0 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function editX0_Callback(hObject, eventdata, handles)
% hObject    handle to editX0 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editX0 as text
%        str2double(get(hObject,'String')) returns contents of editX0 as a double
set(handles.sliderX0,'Value',str2double(get(hObject,'String')));
updateImage(handles)

% --- Executes during object creation, after setting all properties.
function editX0_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editX0 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function sliderY0_Callback(hObject, eventdata, handles)
% hObject    handle to sliderY0 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


set(handles.editY0,'String',num2str(get(hObject,'Value')));
updateImage(handles);

% --- Executes during object creation, after setting all properties.
function sliderY0_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderY0 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function editY0_Callback(hObject, eventdata, handles)
% hObject    handle to editY0 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of editY0 as text
%        str2double(get(hObject,'String')) returns contents of editY0 as a double

set(handles.sliderY0,'Value',str2double(get(hObject,'String')));
updateImage(handles)

% --- Executes during object creation, after setting all properties.
function editY0_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editY0 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function slider12_Callback(hObject, eventdata, handles)
% hObject    handle to slider12 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function slider12_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider12 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function edit12_Callback(hObject, eventdata, handles)
% hObject    handle to edit12 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit12 as text
%        str2double(get(hObject,'String')) returns contents of edit12 as a double


% --- Executes during object creation, after setting all properties.
function edit12_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit12 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function figure1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

function updateImage(handles)
im3 = getappdata(handles.figure1,'im3');
plateType = getappdata(handles.figure1,'pType');

A1X =  str2double(get(handles.editA1X,'String'));
A1Y =  str2double(get(handles.editA1Y,'String'));
estAngle =  str2double(get(handles.editAngle,'String'));
estScale =  str2double(get(handles.editScale,'String'));
K1 =  str2double(get(handles.editK1,'String'));
X0 =  str2double(get(handles.editX0,'String'));
Y0 =  str2double(get(handles.editY0,'String'));

cla(handles.axes1);
imshow(double(im3),[],'Parent',handles.axes1);
hold(handles.axes1,'on');

x2 = xyPositionsOfWells([A1X,A1Y,estAngle,estScale,K1,X0,Y0],plateType);
scatter(handles.axes1,x2(1,:),x2(2,:),'bx');
scatter(handles.axes1,x2(1,1),x2(2,1),'bs');
scatter(handles.axes1,X0,Y0,'rs');


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isequal(get(hObject, 'waitstatus'), 'waiting')
% The GUI is still in UIWAIT, us UIRESUME
uiresume(hObject);
else
% The GUI is no longer waiting, just close it
delete(hObject);
end


% --- Executes when uipanel1 is resized.
function uipanel1_SizeChangedFcn(hObject, eventdata, handles)
% hObject    handle to uipanel1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
