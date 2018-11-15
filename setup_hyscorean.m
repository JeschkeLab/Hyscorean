
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

fprintf('===========================================================================\n')
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
fprintf(' - Please restart MATLAB to refresh the new system environment variables. \n')
fprintf(' - MATLAB preferences may be changed later in the GUI \n')
fprintf('============================================================================\n')

