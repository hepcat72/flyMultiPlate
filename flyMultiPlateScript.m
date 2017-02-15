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
% notifier
% sendmail - needs to be configured. Test with sendmail('your@email.c','test');

emailAddress = {'rleach@princeton.edu',''};

notifier(emailAddress,@flyMultiPlateScriptAnalysis);

end
