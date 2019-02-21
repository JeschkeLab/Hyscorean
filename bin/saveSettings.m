function saveSettings(handles)
%==========================================================================
% Save Settings
%==========================================================================
% This function allows the user to save the current Hyscorean settings to a
% file via an OS window.
%
% (see Hyscorean manual for further information)
%==========================================================================
%
% Copyright (C) 2019  Luis Fabregas, Hyscorean 2019
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License 3.0 as published by
% the Free Software Foundation.
%==========================================================================

%Ask user where to put the new file
[File,Path] = uiputfile('Hyscorean_settings.mat','Save settings as...');
%If canceled then return
if File==0
  return
end
%Get the current settings
Settings = getSettings(handles);

%Send settings structure to base workspace
assignin('base', 'Settings', Settings);

%Save
save(fullfile(Path,File),'Settings');

%Remove the structure from base workspace
evalin('base','clear Settings')

return