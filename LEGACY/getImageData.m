function getImageData(obj,event)

  [data,time,metadata] = getdata(obj,obj.FramesAcquiredFcnCount,'native','cell');

  %Get & update the user data
  ud           = obj.UserData;
  fid          = ud{1};
  %frameCount   = ud{2} + 1;
  %lastFramePos = ud{3};
  %nextFramePos = ud{4};

  %fid = obj.UserData(1);
  %obj.UserData(2) = obj.UserData(2) + 1;

  %Save the user data changes
  %ud{2}            = frameCount;
  %ud{3}            = nextFramePos;
  %ud{4}            = nextFramePos + 1;
  %ud{nextFramePos} = data{1};
  %obj.UserData     = ud;
  %obj.UserData = {ud{1} frameCount newFramePos data{1}};
  %obj.UserData = {fid frameCount};

  %disp(['Recording frame [' num2str(frameCount) ']'])
  disp(['Recording a frame'])
  
  %set(obj,'UserData',ud);

  for ii = 1:numel(metadata)
    frameTime = datetime(datenum(metadata(ii).AbsTime),'ConvertFrom',...
                         'datenum','Format','dd-MMM-uuuu HH:mm:ss.SSSSSSSSS');
    fprintf(fid,'%s\r\n',frameTime);
  end

end
