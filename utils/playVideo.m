disp(['Select the video file to play'])
[fileName,pathName] = uigetfile({'*.mj2;*.avi;*.mp4;*.m4v'; ...
                                 '*.mj2';'*.avi';'*.mp4';'*.m4v'},...
                                 'Play Video File');

%% Open the timestamp file

datetimeFormat    = 'dd-MMM-uuuu HH:mm:ss.SSSSSSSSS';
datetimeSpec      = ['%{',datetimeFormat,'}D']; %For file reading
datetimeOutFormat = 'dd-mmm-yyyy HH:MM:SS.FFF';

%Get the timestamp file - do all the possible replacements to brute-force
%finding the filename
baseFilename = strrep(fileName,'.mj2','');
baseFilename = strrep(baseFilename,'.avi','');
baseFilename = strrep(baseFilename,'.mp4','');
baseFilename = strrep(baseFilename,'.m4v','');

timestampFileName = strcat(baseFilename,'-timestamps.csv');

curFolder = pwd;

%Check the existence of the associated timstamp file
cd(pathName);
if not(exist(timestampFileName,'file') == 2)
    msg = sprintf('Select the timestamp file associated with: %s',fileName)
    disp(msg)
    [timestampFileName,timestampPathName] = uigetfile({'*.csv'},msg);
else
    timestampPathName = pathName;
end

cd(curFolder);

disp(strcat('Opening timestamp file: ',fullfile(timestampPathName,...
                                                timestampFileName)))
timestampTable = readtable(fullfile(timestampPathName,...
                                    timestampFileName),...
                           'Delimiter',',','Format',datetimeSpec,...
                           'ReadVariableNames',false);
[numTimestamps, ~] = size(timestampTable);

%Open the video file
vidObj = VideoReader(fullfile(pathName,fileName));


%Open the output video file (to add timestamps)
[vidExtension,vidFormat] = selectFiletype(numTimestamps);
fileNameTSVid = strcat(baseFilename,'-withTimestamps',vidExtension);
diskLogger = VideoWriter(fullfile(pathName,fileNameTSVid),vidFormat);
open(diskLogger);


%Determine the height and width of the frames.
vidHeight = vidObj.Height;
vidWidth  = vidObj.Width;

%Create a MATLAB® movie structure array, s.
s = struct('cdata',zeros(vidHeight,vidWidth,3,'uint8'),...
    'colormap',[]);

%Read one frame at a time using readFrame until the end of the file is reached. Append data from each video frame to the structure array.
frameNum = 1;
while hasFrame(vidObj)
    timstampStr = timestampTable{frameNum,1};
    frameImg = readFrame(vidObj);
    %s(frameNum).cdata = insertText(frameImg,[0 0],[datestr(timstampStr,...
    %    datetimeOutFormat) ' Frame: ' num2str(frameNum)]);
    frameImg = insertText(frameImg,[0 0],[datestr(timstampStr,...
        datetimeOutFormat) ' Frame: ' num2str(frameNum)],...
        'BoxOpacity',0.0,'TextColor','white');
    imshow(frameImg)
    writeVideo(diskLogger,frameImg);
    frameNum = frameNum + 1;
    if mod(frameNum,1000) == 0
        disp(['Writing frame ' num2str(frameNum) ' of ' num2str(numTimestamps)])
    end
end

%Play/view the movie
%movie(s,1,vidObj.FrameRate);

close(diskLogger);
close;
