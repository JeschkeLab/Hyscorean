
clc

InstallationPath = pwd;
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

%Set Hyscorean default paths
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
% Set Sourcetree's local git path as a OS environmental path
fprintf('Searching for Sourcetree path...')
cd C:\
[DOS_status,DOS_output] = dos('dir Atlassian /s /b /AD');
cd(InstallationPath)
fprintf('done. \n')
if ~strcmp(DOS_output(1:14),'File Not Found')
  %If Sourcetree is found
  fprintf('Setting SourceTree local git environment path...\n')
  StrPos = strfind(DOS_output,'C:\');
  AtlassianPath = DOS_output(StrPos(1):StrPos(2)-1);
  EnviromentalVariablePATH = strcat(AtlassianPath,'\SourceTree\git_local\bin');
  %Check if Atlassian path is already in the PATH variable
  if isempty(strfind(getenv('PATH'),EnviromentalVariablePATH))
    fprintf('done. \n')
    NewPATH = [getenv('PATH') ';' EnviromentalVariablePATH];
    fprintf('Writting to OS environment variable... ');
    Command = sprintf('setx PATH "%s"',NewPATH);
    dos(Command);
  end
  %Check status of repository as trial
   fprintf('Connecting to Hyscorean repository... \n ')
   !git status origin master
   setpref('hyscorean','repository_connected',true)
else
    fprintf('Sourcetree path not found. Make sure it is properly installed\n')
    fprintf('and located in the C: drive of your computer. \n')
    setpref('hyscorean','repository_connected',false)
end

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
  setpref('hyscorean','reportlicense',false)
end
fprintf('===========================================================================\n')
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
fprintf('Please restart MATLAB to refresh the new system environment variables. \n')
fprintf('============================================================================\n')

