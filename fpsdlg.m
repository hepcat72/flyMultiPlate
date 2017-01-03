function [percent,fps] = fpsdlg(maxfps,expLenSecs)

  numFrames = maxfps * expLenSecs;

  %Estimated file sizes in order: mj2-compressed, mj2, mj2-avi, avi, mp4
  sizes = {numFrames*0.000104264,numFrames*0.000285286,numFrames*0.000030849,...
           numFrames*0.001043562,...
           numFrames*0.000000562};
	       %numFrames*0.000000562,...
           %numFrames*0.000284,numFrames*0.000284};

  formatDescs = sprintf('[%s Gb] Motion JPEG 2000 Compressed (.mj2)\r\n\t[%s Gb] Archival (.mj2)\r\n\t[%s Gb] Motion JPEG AVI (.avi)\r\n\t[%s Gb] Uncompressed AVI (.avi)\r\n\t[%s Gb] MPEG-4 (.mp4)\r\n',...
      num2str(sizes{1}),num2str(sizes{2}),num2str(sizes{3}),num2str(sizes{4}),num2str(sizes{5}));

  prompt = sprintf('Enter desired frames per second.\r\n\r\nEstimated sizes at the max of %s frames per second: \r\n\r\n\t%s\r\n(Scales linearly)\r\n',...
      num2str(maxfps),formatDescs);

  bad_prompt = strcat(prompt,'**invalid entry - must be a number from 1 ',...
                      'to a max of [',num2str(maxfps),']:');

  dlg_title  = 'Input FPS';
  num_lines  = 1;
  defaultans = {num2str(maxfps)};

  fps = 0;
  status = 0;
  tmp_prompt = prompt;
  while status == 0 || fps <= 0 || fps > maxfps
    answer = inputdlg(tmp_prompt,dlg_title,num_lines,defaultans);
    [fps,status] = str2num(answer{1});
    tmp_prompt = bad_prompt;
  end

  percent = (fps / maxfps) * 100;

end
