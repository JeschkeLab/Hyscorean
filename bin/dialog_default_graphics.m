function Answer = dialog_default_graphics
% Construct a questdlg with three options
choice = questdlg('These settings will be saved for further sessions. Do you want to overwrite the previous default settigns?', ...
	'Hyscorean', ...
	'Yes','No','Yes');
% Handle response
switch choice
    case 'Yes'
        Answer = 1;
    case 'No'
        Answer = 0;
end