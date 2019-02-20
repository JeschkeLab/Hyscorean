%==========================================================================
% Hyscorean Installer
%==========================================================================
% This script installs Hyscorean for MATLAB. The installer takes care of
% setting up all necessary files, variables and preferences required for
% the program. It also checks for required MATLAB toolboxes and external
% programs that may be required.
% The user has to accept the terms and conditions of the GNU General Public
% License 3.0 in order for the program to be installed. 
%
% The program can be executed normally as a MATLAB script by either
% pressing the Run button or the F5 key.
%==========================================================================
%
% Copyright (C) 2019  Luis Fabregas, Hyscorean 2019
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License 3.0 as published by
% the Free Software Foundation.
%==========================================================================

%Clear workspace
clc, clearvars

%Just check that (re)-installation is done in the right folder
try
InstallationPath = fileparts(which('setup_hyscorean'));
CurrentPath = pwd;
if ~strcmp(CurrentPath,InstallationPath)
  cd(InstallationPath)
end
catch 
end

%Initiallize variable
fullyInstalled = true;

%Get OS system information
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


%==========================================================================
% License agreement
%==========================================================================

%If license has been accepted, do not ask again
if ~ispref('hyscorean','LGPL_license')
    
    %Construct GUI with license agreement
    FigureHandle = figure('NumberTitle','off','Name','Hyscorean: License Agreement','menu','none','WindowStyle','modal','toolbar','none','units','normalized','Position',[0.25 0.15 0.31 0.75]);
    PanelHandel = uipanel(FigureHandle,'Units','normalized','position',[0.02 0.05 0.96 0.86],'title','License');
    ListBoxHandle = uicontrol(PanelHandel,'style','listbox','Units','normalized','position',[0 0 1 1],'FontSize',9);
    %Add accept and decline buttons
    uicontrol(FigureHandle,'style','pushbutton','Units','normalized','position',[0.25 0.005 0.2 0.04],'FontSize',9,'String','Agree','Callback',@AgreeCallback);
    uicontrol(FigureHandle,'style','pushbutton','Units','normalized','position',[0.56 0.005 0.2 0.04],'FontSize',9,'String','Disagree','Callback',@DisagreeCallback); 
    %Add the GNU LGPL logo
    AxisHandle = axes(FigureHandle,'Units','normalized','position',[0.02 0.92 0.35 0.075]);
    [matlabImage,~,Alpha] = imread(fullfile(InstallationPath,'bin','licenseLogo.png'));
    image(matlabImage,'AlphaData',Alpha)
    axis(AxisHandle,'off')
    
    %Open license file
    FileID = fopen(fullfile(InstallationPath,'LICENSE.LGPL.txt'));
    %Copy license text into UI list box
    LineIndicator = 1;
    while true
        TextLine = fgetl(FileID);
        if ~ischar(TextLine)
            break
        end
        strings{LineIndicator}=TextLine;
        LineIndicator = LineIndicator + 1;
    end
    fclose(FileID);
    set(ListBoxHandle,'string',strings);
    set(ListBoxHandle,'Value',1);
    set(ListBoxHandle,'Selected','on');
    
    %Wait for user response
    waitfor(FigureHandle)
    
    %Set Hyscorean preference accordingly. If not agreed abort installation
    if exist('LicenseAgreed','var')
        if LicenseAgreed
            fprintf('Hyscorean GNU LGPL 3.0 license accepted \n')
            setpref('hyscorean','LGPL_license',true)
        else
            fprintf('Hyscorean GNU LGPL 3.0 license needs to be accepted. Aborting installation... \n')
            return
        end
    else
        fprintf('Hyscorean GNU LGPL 3.0 license needs to be accepted. Aborting installation... \n')
        return
    end
end

%==========================================================================
% Hyscorean default paths
%==========================================================================

%Inform user
fprintf('Setting Hyscorean paths... ')
%Get MATLAB search paths
MatlabPaths = path;
OldPaths = textscan(MatlabPaths,'%s','Delimiter',';');
OldPaths = OldPaths{1}(:)';
AddPaths = {pwd,[pwd '\bin']};
PathsAlreadyAdded = strfind(horzcat(OldPaths),AddPaths{1});

%Check if Hyscorean paths have been already added
if isempty([PathsAlreadyAdded{:}])
  NewPaths = horzcat(AddPaths,OldPaths(1:end));
  %If not then add them
  if ~isequal(NewPaths,OldPaths)
    PathToAdd = sprintf('%s;', NewPaths{:} );
    PathToAdd = PathToAdd(1:end-1);
    path(PathToAdd);
  end
  %Save the MATLAB search paths
  savepath
end
fprintf('done. \n')
fprintf('===========================================================================\n')

%==========================================================================
% Hyscorean preferences
%==========================================================================

%Inform user
fprintf('Setting Hyscorean preferences... \n')
%Get MATLAB default path
SavePath = userpath;

%Check if preferences have been already defined to keep user preferences
if ~ispref('hyscorean','savepath')
  setpref('hyscorean','savepath',SavePath)
  fprintf('        Save path: %s \n',SavePath)
else
  fprintf('        Save path: %s \n',getpref('hyscorean','savepath'))
end
%Graphical settings
if ~ispref('hyscorean','graphicalsettings')
  GraphicalSettings = struct('LineWidth',1,'Levels',40,'PlotType',1,'Colormap',1,'ColormapName','parula','Real',0,'Imaginary',0,'Absolute',1);
  setpref('hyscorean','graphicalsettings',GraphicalSettings)
  fprintf('        Graphical settings: defaults \n')
else
  fprintf('        Graphical settings: user-defined \n')
end
%EasySpin default spin system definition
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

%==========================================================================
% MATLAB toolbox licenses
%==========================================================================
    
%Look for required toolboxes licenses
fprintf('===========================================================================\n')
fprintf('Checking required MATLAB toolboxes... \n')
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
  fullyInstalled = false;
end
fprintf('===========================================================================\n')

%==========================================================================
% Easyspin installation checkout
%==========================================================================

%Check if easyspin is installed and added to path
fprintf('Easyspin installation \n')
try
  warning('off','all')
  easyspin
  warning('on','all')
  setpref('hyscorean','easyspin_installed',true)
catch
  fprintf('Easyspin not found or not installed. Make sure its path is added  \n')
  fprintf('to the MATLAB default search path and run this installation again.\n')
  fprintf('Otherwise the fitting module of Hyscorean will be unavailable.    \n')
  setpref('hyscorean','easyspin_installed',false)
  fullyInstalled = false;
end

%==========================================================================
% Finish & Return
%==========================================================================

fprintf('============================================================================\n')
fprintf('INSTALLATION FINISHED \n')
if fullyInstalled
fprintf(' - Hyscorean was successfully and fully installed and all functionalities are operational.\n')
else
fprintf(' - Hyscorean was successfully but incompletely installed.\n')
end
fprintf(' - MATLAB preferences may be changed later in the GUI \n')
fprintf('============================================================================\n')

%Remove all installer variables from workspace
clearvars

%==========================================================================
%Callbacks for License Agreement GUI
%==========================================================================

function AgreeCallback(Object)

assignin('base','LicenseAgreed',1)
close(Object.Parent)
end

function DisagreeCallback(Object)

assignin('base','LicenseAgreed',0)
close(Object.Parent)
end