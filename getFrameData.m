function [frame,timestamp] = getFrameData(vidobj)

  [data,time,metadata] = getdata(vidobj,1,'native','cell');

  frame = data{1};
  timestamp = datetime(datenum(metadata(1).AbsTime),'ConvertFrom',...
                       'datenum','Format','dd-MMM-uuuu HH:mm:ss.SSSSSSSSS');

end
