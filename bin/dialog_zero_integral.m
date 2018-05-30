function Answer = dialog_zero_integral
% Construct a questdlg with three options
choice = questdlg('Zero-integral was found. Data may be damaged or corrupted', ...
	'TrierAnalysis', ...
	'Ok','Ok');
% Handle response
switch choice
    case 'Ok'
        disp(['Canceling processing due to damaged data...'])
        Answer = 1;
end