function getImageData(obj,event)

  [data, time, metadata] = getdata(obj,obj.FramesAcquiredFcnCount,'native','cell');
  %Save the last frame as the second element in the UserData cell array
  ca = obj.UserData;
  ca{3} = ca{3} + 1;
  disp(['Recording frame [' num2str(ca{3}) ']'])
  obj.UserData = {ca{1} data{1} ca{3}};
  %tmp = obj.UserData(1);
  %set(obj,'UserData',[tmp,(data)]);
  for ii = 1:numel(metadata)
    frameTime = datetime(datenum(metadata(ii).AbsTime), 'ConvertFrom', 'datenum', 'Format', 'dd-MMM-uuuu HH:mm:ss.SSSSSSSSS');
    fprintf(ca{1},'%s\r\n',frameTime);
  end

end
