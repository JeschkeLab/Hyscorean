function Answer = dialog_default_saver
% Construct a questdlg with three options
choice = questdlg('The default save path has been modified and will be now saved for further sessions. Do you want to overwrite the previous default path?', ...
	'Hyscorean', ...
	'Yes','No','Yes');
% Handle response
switch choice
    case 'Yes'
        Answer = 1;
    case 'No'
        Answer = 0;
end