
clc, clearvars

%Just check that (re)-installation is done in the right folder
try
InstallationPath = which('setup_hyscorean');
InstallationPath = InstallationPath(1:end-length('\setup_hyscorean.m'));
CurrentPath = pwd;
if ~strcmp(CurrentPath,InstallationPath)
  cd(InstallationPath)
end
catch 
end

%Get system information
% InstallationPath = pwd;
MATLAB_version = version;
OS = computer;
allFilesOK = true;
JavaVersion  = version('-java');

fprintf('===========================================================================\n')
fprintf('Hyscorean: HYSCORE processing and analysis software     (c)2018 ETH Zurich \n')
fprintf('Version 1.0                                                                \n')
fprintf('===========================================================================\n')
fprintf('Installation info                                                          \n')
fprintf('     Path:           %s \n',InstallationPath)
fprintf('     MATLAB Version: %s \n',MATLAB_version)
fprintf('     OS:             %s \n',OS)
fprintf('     Java Version:   %s \n',JavaVersion)
fprintf('===========================================================================\n')
fprintf('Verfying Hyscorean directory contents... ')
if allFilesOK
fprintf('no missing files \n')
end

%--------------------------------------------------------------------------
%Set Hyscorean default paths
%--------------------------------------------------------------------------
fprintf('Setting Hyscorean paths... ')
MatlabPaths = path;
OldPaths = textscan(MatlabPaths,'%s','Delimiter',';');
OldPaths = OldPaths{1}(:)';
AddPaths = {pwd,[pwd '\bin']};
PathsAlreadyAdded = strfind(horzcat(OldPaths),AddPaths{1});
%Check if paths have been already added
if isempty([PathsAlreadyAdded{:}])
NewPaths = horzcat(AddPaths,OldPaths(1:end));
if ~isequal(NewPaths,OldPaths)
    npath = sprintf('%s;', NewPaths{:} );
    npath = npath(1:end-1);
    path(npath);
end
savepath
end
fprintf('done. \n')

%--------------------------------------------------------------------------
% GIT installation and environmental variables
%--------------------------------------------------------------------------

% fprintf('Checking GIT installation and environmental variable... ')
% [DOS_Failed,DOS_Output] = dos('git --version');
% if DOS_Failed
%   fprintf('not found \n')
% Set Sourcetree's local git path as a OS environmental path
% [~,DOS_output] = dos('echo %username%');
% Username = DOS_output(1:end-1);
% AtlassianDefaultPath  = sprintf('C:\\Users\\%s\\AppData\\Local\\Atlassian',Username);
% fprintf('Searching for Atlassian path at: \n')
% fprintf('      %s \n',AtlassianDefaultPath)
% [AtlassianNotFound,~] = dos(sprintf('dir %s',AtlassianDefaultPath));
% if ~AtlassianNotFound
%   AtlassianPath = AtlassianDefaultPath;
%   fprintf('Directory found.\n')
% else
%   fprintf('Searching for Atlassian path in C drive...\n')
%   cd C:\
%   [DOS_status,DOS_output] = dos('dir Atlassian /s /b /AD');
%   cd(InstallationPath)
%   fprintf('done. \n')
%   StrPos = strfind(DOS_output,'C:\');
%   AtlassianPath = DOS_output(StrPos(1):StrPos(2)-1);
%   if strcmp(DOS_output(1:14),'File Not Found')
%     fprintf('Sourcetree path not found. Make sure it is properly installed\n')
%     fprintf('and located in the C: drive of your computer. \n')
%     fprintf('Alternatively you can install GIT externaly. \n')
%     setpref('hyscorean','repository_connected',false)
%   end
% end
%   fprintf('Setting Atlassian local git environment path...\n')
%   EnviromentalVariablePATH = strcat(AtlassianPath,'\SourceTree\git_local\bin');
%   fprintf('Editing powershell script...\n')
%   fid = fopen('./bin/setPathRegistry.ps1','r+');
%     % Read all lines & collect in cell array
%     txt = textscan(fid,'%s','delimiter','\n');
%     txt{1}{2}  = sprintf('    [string] $AddedFolder =  "%s",',EnviromentalVariablePATH);
%     fid = fopen('./bin/setPathRegistry.ps1','w+');
%     for i=1:length(txt{1})
%       fprintf(fid, '%s \n',txt{1}{i});
%     end
%     fclose('all');
%       fprintf('Appending path to OS environmental variable\n')
%     [PS_failed,AddedSuccesfully] = system('powershell -file ./bin/setPathRegistry.ps1 ');
%     if AddedSuccesfully && ~PS_failed
%       fprintf('Environmental variable was added succesfully. \n');
%     else
%       fprintf('Environmental variable addition failed. \n');
%       fprintf('Environmental variable has to be added manually \n');
%       fprintf('Press the Windows key and type: \n');
%       fprintf('          Edit the system environmental variables \n');
%       fprintf('Press "Environmental Variables..." \n');
%       fprintf('Double-click on "Path" under "User variables for %s" \n',Username);
%       fprintf('Press "New" and copy-paste the following line: \n');
%       fprintf('          %s \n',EnviromentalVariablePATH);
%       fprintf('Press Enter when finished \n');
%       pause
%     end
%   [DOS_Failed,DOS_Output] = dos('git --version');
%   fprintf('GIT version: %s ',DOS_Output)
% 
% else
%     fprintf('found \n')
%     fprintf('GIT version: %s',DOS_Output)
% end
fprintf('===========================================================================\n')

%--------------------------------------------------------------------------
% Connect to repository
%--------------------------------------------------------------------------

  %Check status of repository as trial
   fprintf('Connecting to Hyscorean repository... ')
   DOS_failed = dos('git fetch');
   if DOS_failed
     fprintf(' connection failed \n')
     fprintf(' (Check your internet connection) \n')
   else
     fprintf(' connection successful \n')
     setpref('hyscorean','repository_connected',true)
     !git status origin master
   end

fprintf('===========================================================================\n')

%--------------------------------------------------------------------------
% Hyscorean preferences
%--------------------------------------------------------------------------

    fprintf('Setting Hyscorean preferences... \n')
    SavePath = userpath;
    %Check if preferences have been already defined to keep user preferences
    if ~ispref('hyscorean','savepath')
      setpref('hyscorean','savepath',SavePath)
      fprintf('        Save path: %s \n',SavePath)
    else
       fprintf('        Save path: %s \n',getpref('hyscorean','savepath')) 
    end
    if ~ispref('hyscorean','graphicalsettings')
      GraphicalSettings = struct('LineWidth',1,'Levels',40,'PlotType',1,'Colormap',1,'Real',0,'Imaginary',0,'Absolute',1);
      setpref('hyscorean','graphicalsettings',GraphicalSettings)
      fprintf('        Graphical settings: defaults \n')
    else
      fprintf('        Graphical settings: user-defined \n')
    end
    if ~ispref('hyscorean','defaultsystemEasyspin')
      SystemInputString(1,:) =  '%---------------------------------------------';
      SystemInputString(2,:) =  '% EasySpin Input                              ';
      SystemInputString(3,:) =  '%---------------------------------------------';
      SystemInputString(4,:) =  '                                              ';
      SystemInputString(5,:) =  '%Spin System definition                       ';
      SystemInputString(6,:) =  '%---------------------------------------------';
      SystemInputString(8,:) =  'Sys.Nucs = ''14N,15N,1H'';                      ';
      SystemInputString(9,:) =  'Sys.A = [9 0  0; 7.6 0 0 ; 7.6 8.7 7.0];      ';
      SystemInputString(10,:) = 'Sys.Q = [0.8 0.8 0.8; 0 0 0; 0 0 0];          ';
      SystemInputString(11,:) = '                                              ';
      SystemInputString(12,:) = '%Fit variables definition                     ';
      SystemInputString(13,:) = '%---------------------------------------------';
      SystemInputString(14,:) = 'Vary.A =  [2 4 6; 5 4 9; 2 2 2];              ';
      setpref('hyscorean','defaultsystemEasyspin',SystemInputString)
      fprintf('        Easyspin input system: default \n')
    else
      fprintf('        Easyspin input system: user-defined \n')
    end

%--------------------------------------------------------------------------
% Toolbox licenses checkout
%--------------------------------------------------------------------------
    
%Look for required toolboxes 
fprintf('===========================================================================\n')
fprintf('Checking required MATLAB toolboxes... \n')
%Signal processing toolbox
LicenseCheckout = license('test','signal_toolbox');
if LicenseCheckout
  VersionInfo = ver('signal');
  fprintf('    Signal Processing Toolbox  (installed) v%s %s %s \n',VersionInfo.Version,VersionInfo.Release,VersionInfo.Date)
  setpref('hyscorean','signalprocessinglicense',true)
else
  fprintf('    Signal Processing Toolbox  (not found) \n')
  fprintf('    (Hyscorean is not able to work and cannot be used) \n')
  setpref('hyscorean','signalprocessinglicense',false)
end

%Report generator
LicenseCheckout = license('test','matlab_report_gen');
if LicenseCheckout
  VersionInfo = ver('rptgen');
  fprintf('    MATLAB Report Generator    (installed) v%s %s %s \n',VersionInfo.Version,VersionInfo.Release,VersionInfo.Date)
  setpref('hyscorean','reportlicense',true)
else
  fprintf('    MATLAB Report Generator    (not found) \n')
  fprintf('    (Hyscorean is able to work without this functionality) \n')
  setpref('hyscorean','reportlicense',false)
end
fprintf('===========================================================================\n')

%--------------------------------------------------------------------------
% Easyspin installation checkout
%--------------------------------------------------------------------------

fprintf('Easyspin installation \n')
try
  warning('off','all')
  easyspin
  warning('on','all')
  setpref('hyscorean','easyspin_installed',true)
catch
  fprintf('Easyspin not found or not installed. Make sure its path is added \n')
  fprintf('to the MATLAB default search path and run this installation again.\n')
  fprintf('Otherwise the fitting functionalities of Hyscorean will be unavailable\n')
  setpref('hyscorean','easyspin_installed',false)
end
fprintf('============================================================================\n')
fprintf('INSTALLATION FINISHED \n')
fprintf(' - Please restart MATLAB and re-run this setup to refresh the new system environment variables. \n')
fprintf(' - MATLAB preferences may be changed later in the GUI \n')
fprintf('============================================================================\n')

clearvars