function [frame,timestamp] = getFrameData(vidobj,dtFormat)

  [data,time,metadata] = getdata(vidobj,1,'native','cell');

  frame = data{1};
  timestamp = datetime(datenum(metadata(1).AbsTime),'ConvertFrom',...
                       'datenum','Format',dtFormat);

end
