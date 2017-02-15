function flyMultiPlateScript()

%% Edit flyMultiPlateScriptAnalysis.m for run parameters

%% This method is a wrapper of the flyMultiPlateScriptAnalysis.m method
%% It monitors the script and emails the user below if it crashes

%% If sendmail is not working on this computer and this script errors out, you
%% can just run flyMultiPlateScriptAnalysis.m directly without crash
%% notifications.

%% Make sure you're running the latest version.  Download from github:
%% https://github.com/hepcat72/flyMultiPlate/archive/master.zip

%% Requirements:
% notifier, http://www.mathworks.com/matlabcentral/fileexchange/28733-notifier
% sendmail - needs to be configured. Test with sendmail('your@email.c','test');
%  Doc: https://www.mathworks.com/help/matlab/ref/sendmail.html?s_tid=srchtitle
%  Details: http://blogs.mathworks.com/pick/2010/10/1/be-notified/

emailAddress = {'email1@princeton.edu','email2@princeton.edu'};

notifier(emailAddress,@flyMultiPlateScriptAnalysis);

end
