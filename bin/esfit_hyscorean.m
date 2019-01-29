function varargout = esfit_hyscorean(SimFunctionName,ExpSpec,Sys0,Vary,Exp,SimOpt,FitOpt)
%==========================================================================
% Hyscorean Fitting Module
%==========================================================================
% This function is responsible for the generation and execution of the
% fitting module of Hyscorean. This module employs EasySpin for fitting the
% spectra processed via Hyscorean. This function allows the fitting of
% several HYSCORE spectra at the same time e.g. at different field
% positions. The spectra are simulated via the saffron function and then
% processed by the same functions employed by Hyscorean during the
% processing. 
% (See the Hyscorean manual for further details) 
%==========================================================================
% This module can only be executed if a valid EasySpin installation is
% present. 
%==========================================================================
% Adapted from esfit(EasySpin) by Stoll et al.
%
% Copyright (C) 2019  Luis Fabregas, Hyscorean 2019
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License 3.0 as published by
% the Free Software Foundation.
%==========================================================================

%Check that the free software license has been accepted
if ispref('hyscorean','LGPL_license')
    if ~getpref('hyscorean','LGPL_license')
        w  = warndlg('Hyscorean''s GNU LGPL 3.0 license agreement not accepted. Please run setup_hyscorean again and accept the license agreemen.','Warning','modal');
        waitfor(w)
        return
    end
else
    w  = warndlg('Hyscorean''s GNU LGPL 3.0 license agreement not found. Please run setup_hyscorean again and accept the license agreemen.','Warning','modal');
    waitfor(w)
    return
end

%Check that EasySpin is installed
if ispref('hyscorean','easyspin_installed')
    if ~getpref('hyscorean','easyspin_installed')
        w  = warndlg('EasySpin installation has not been validated. Please run setup_hyscorean again with a valid EasySpin installation.','Warning','modal');
        waitfor(w)
        return
    end
else
    w  = warndlg('EasySpin installation has not been validated. Please run setup_hyscorean again with a valid EasySpin installation.','Warning','modal');
    waitfor(w)
    return
end

%Check input
if (nargin<5), error('Not enough inputs.'); end
if (nargin<6), SimOpt = struct('unused',NaN); end
if (nargin<7), FitOpt = struct('unused',NaN); end

if isempty(FitOpt), FitOpt = struct('unused',NaN); end
if ~isstruct(FitOpt)
  error('FitOpt (7th input argument of esfit) must be a structure.');
end

if ~iscell(Exp)
  Exp = {Exp};
end
if ~iscell(SimOpt)
  SimOpt = {SimOpt};
end
if ~iscell(ExpSpec)
  ExpSpec = {ExpSpec};
end

%Get the path to Hyscorean source code
Path2Hyscorean = which('Hyscorean');
Path2Hyscorean = Path2Hyscorean(1:end-11);

%Close all parpools
delete(gcp('nocreate'))

%Initialize global variables
global FitData FitOpts

%Empty the global variables to reset them
FitData = [];
FitOpts = [];

%Initialize default fields
FitData.currFitSet = [];
FitData.CurrentSpectrumDisplay = 1;
FitData.DisplayingFitSetSpec = false;
FitData.CurrentCoreUsage = 0;
FitData.DefaultExp = Exp;
FitData.DefaultSimOpt = SimOpt;
FitData.numSpec = length(Exp);

%Check that the given simulation function exists
switch class(SimFunctionName)
  case 'char'
    % Simulation function is given as a character array
    FitData.SimFcnName = SimFunctionName;
    FitData.SimFcn = str2func(SimFunctionName);
    if ~any(exist(FitData.SimFcnName)==[2 3 5 6])
      error('First input parameter must be a valid function name or function handle.');
    end
  case 'function_handle'
    % Simulation function is given as a function handle
    fdata = functions(SimFunctionName);
    FitData.SimFcnName = fdata.function;
    FitData.SimFcn = SimFunctionName;
    if ~strcmpi(fdata.type,'anonymous') && ~strcmpi(fdata.type,'scopedfunction')
      if ~any(exist(FitData.SimFcnName) == [2 3 5 6])
        error('First input parameter must be a valid function name or function handle.');
      end
    end
  otherwise
    error('First parameter must be simulation function name.');
end
FitData.lastSetID = 0;

%--------------------------------------------------------------------------
% Spin System Definition (Start-up)
%--------------------------------------------------------------------------

%Check whether the Sys and Vary structures have been given as input
if ~isempty(Sys0) || ~isempty(Vary)
  
  %If YES then construct the string to be printed in the system definition window
  
  %First for the Sys structure...
  FieldNames = fieldnames(Sys0);
  for i = 1:length(FieldNames)
    String = sprintf('Sys.%s  = ',FieldNames{i});
    switch class(getfield(Sys0,FieldNames{i}))
      case 'char'
        String = [String '''' getfield(Sys0,FieldNames{i}) ''''];
      case 'double'
        FieldSize = size(getfield(Sys0,FieldNames{i}));
        String = [String '['];
        Temp = getfield(Sys0,FieldNames{i});
        for ii = 1:FieldSize(1)
          String = [String sprintf('%.2f ',Temp(ii,1))];
          for jj=2:FieldSize(2)
            String = [String sprintf(', %.2f',Temp(ii,jj))];
          end
          if ii ~= FieldSize(1)
            String = [String '; '];
          end
        end
        String = [String ']'];
    end
    String = [String ';'];
    SysDefString{i} = String;
  end
  
  %... then for the Vary structure...
  FieldNames = fieldnames(Vary);
  for i = 1:length(FieldNames)
    String = sprintf('Vary.%s  = ',FieldNames{i});
    switch class(getfield(Vary,FieldNames{i}))
      case 'char'
        String = [String '''' getfield(Sys0,FieldNames{i}) ''''];
      case 'double'
        FieldSize = size(getfield(Vary,FieldNames{i}));
        String = [String '['];
        Temp = getfield(Vary,FieldNames{i});
        for ii = 1:FieldSize(1)
          String = [String sprintf('%.2f ',Temp(ii,1))];
          for jj=2:FieldSize(2)
            String = [String sprintf(', %.2f',Temp(ii,jj))];
          end
          if ii ~= FieldSize(1)
            String = [String '; '];
          end
        end
        String = [String ']'];
    end
    String = [String ';'];
    VaryDefString{i} = String;
  end
  
  %... and finally print it nicely
  DefaultInput{1} = '%---------------------------------------------';
  DefaultInput{2} = '% EasySpin Input                              ';
  DefaultInput{3} = '%---------------------------------------------';
  DefaultInput{4} = '                                              ';
  DefaultInput{5} = '% Spin System definition                      ';
  DefaultInput{6} = '%---------------------------------------------';
  for i = 1:length(SysDefString)
    DefaultInput{length(DefaultInput)+1} = SysDefString{i};
  end
  DefaultInput{length(DefaultInput) + 1} = '                                              ';
  DefaultInput{length(DefaultInput) + 1} = '% Fit variables definition                    ';
  DefaultInput{length(DefaultInput) + 1} = '%---------------------------------------------';
  for i = 1:length(VaryDefString)
    DefaultInput{length(DefaultInput)+1} = VaryDefString{i};
  end
  DefaultInput = char(DefaultInput);
  %Set this as the new spin system definition in the corresponding preference
  setpref('hyscorean','defaultsystemEasyspin',DefaultInput)

    
else
  
  %If NO then load the spin system definition from the preference
  DefaultInput = getpref('hyscorean','defaultsystemEasyspin');
  
end

%Prepare for reading the spin system input
SpinSystemInput = {DefaultInput};
FitData.SpinSystemInput = SpinSystemInput{1};
Size = size(SpinSystemInput{1},1);

%Remove comments in the input
for i=1:Size
  if SpinSystemInput{1}(i,1) == '%'
    SpinSystemInput{1}(i,:) = ' ';
  end
end

%Evaluate the spin system definition to get the Sys and Vary variables
StringForEval = SpinSystemInput{1};
try
  for i=1:size(StringForEval,1)
    eval(StringForEval(i,:))
  end
catch
end

%Check if any changes/additions to the Opt structure are requested
if exist('Opt','var')
  if ~iscell(Opt)
    %Get Opt fields
    OptFields = fields(Opt);
    for i=1:length(OptFields)
      for j=1:length(SimOpt)
        %Set these fields on the existing SimOpt structure
        SimOpt{j} = setfield(SimOpt{j},OptFields{i},getfield(Opt,OptFields{i}));
      end
    end
  end
else
  SimOpt = FitData.DefaultSimOpt;
end

%Check if any changes/additions to the Exp structure are requested
if exist('Exp','var')
  if ~iscell(Exp)
    %Get Opt fields
    ExpFields = fields(Exp);
    for i=1:length(ExpFields)
      for j=1:length(Exp)
        %Set these fields on the existing Exp structure
        Exp{j} = setfield(Exp{j},ExpFields{i},getfield(Exp,ExpFields{i}));
      end
    end
  end
else
  Exp = FitData.DefaultExp;
end

%Change the Sys variable name to match the rest of the code
Sys0 = Sys;
if ~iscell(Sys0)
  Sys0 = {Sys0}; 
end

%Get the number of systems (i.e. number of spectra) to be fitted
nSystems = numel(Sys0);
for s = 1:nSystems
  if ~isfield(Sys0{s},'weight')
    Sys0{s}.weight = 1; 
  end
end
FitData.nSystems = nSystems;


%Save experimental spectrum to global variable...
FitData.ExpSpec = ExpSpec;
%... and rescale it to its absolute maximum 
for i=1:length(ExpSpec)
  FitData.ExpSpecScaled{i} = rescale_mod(ExpSpec{i},'maxabs');
  if length(FitData.ExpSpec{i})~=length(FitData.ExpSpecScaled{i})
    FitData.ExpSpecScaled{i} = reshape(FitData.ExpSpecScaled{i},length(FitData.ExpSpec{i}),length(FitData.ExpSpec{i}));
  end
end

% Make sure user provides one Vary structure for each Sys
if ~iscell(Vary)
  Vary = {Vary}; 
end
if numel(Vary)~=nSystems
  error(sprintf('%d spin systems given, but %d vary structure.\n Give %d vary structures.',nSystems,numel(Vary),nSystems));
end
for iSys = 1:nSystems
  if ~isstruct(Vary{iSys}), Vary{iSys} = struct; end
end

%Make sure users are fitting with the logarithm of Diff or tcorr
for s = 1:nSystems
  if (isfield(Vary{s},'tcorr') && ~isfield(Vary{s},'logtcorr')) ||...
      (~isfield(Sys0{s},'logtcorr') && isfield(Vary{s},'logtcorr'))
    error('For least-squares fitting, use logtcorr instead of tcorr both in Sys and Vary.');
  end
  if (isfield(Vary{s},'Diff') && ~isfield(Vary{s},'logDiff')) ||...
      (~isfield(Sys0{s},'logDiff') && isfield(Vary{s},'logDiff'))
    error('For least-squares fitting, use logDiff instead of Diff both in Sys and Vary.');
  end
end
  
%Assert consistency between Sys0 and Vary structures
for s = 1:nSystems
  Fields = fieldnames(Vary{s});
  for k = 1:numel(Fields)
    if ~isfield(Sys0{s},Fields{k})
      error(sprintf('Field %s is given in Vary, but not in Sys0. Remove from Vary or add to Sys0.',Fields{k}));
    elseif numel(Sys0{s}.(Fields{k})) < numel(Vary{s}.(Fields{k}))
      error(['Field ' Fields{k} ' has more elements in Vary than in Sys0.']);
    end
  end
  clear Fields
end

%Count parameters and save indices into parameter vector for each system
for iSys = 1:nSystems
  [~,~,v_] = getParameters(Vary{iSys});
  VaryVals(iSys) = numel(v_);
end
FitData.xidx = cumsum([1 VaryVals]);
FitData.nParameters = sum(VaryVals);



%--------------------------------------------------------------------------
% Fitting options
%--------------------------------------------------------------------------

%Check function input
if ~isfield(FitOpt,'OutArg')
  FitData.nOutArguments = abs(nargout(FitData.SimFcn));
  FitData.OutArgument = FitData.nOutArguments;
else
  if numel(FitOpt.OutArg)~=2
    error('FitOpt.OutArg must contain two values [nOut iOut]');
  end
  if FitOpt.OutArg(2)>FitOpt.OutArg(1)
    error('FitOpt.OutArg: second number cannot be larger than first one.');
  end
  FitData.nOutArguments = FitOpt.OutArg(1);
  FitData.OutArgument = FitOpt.OutArg(2); 
end
if ~isfield(FitOpt,'Scaling'), FitOpt.Scaling = 'minmax'; end
if ~isfield(FitOpt,'Method'), FitOpt.Method = ''; end
FitOpt.MethodID = 1; % simplex
FitOpt.TargetID = 1; % function as is
if isfield(Exp,'Harmonic') && (Exp.Harmonic>0)
  FitOpt.TargetID = 2; % integral
else
  if strcmp(FitData.SimFcnName,'pepper') || strcmp(FitData.SimFcnName,'garlic')
    FitOpt.TargetID = 2; % integral
  end
end

%Definte fitting methods and their IDs
keywords = strread(FitOpt.Method,'%s');
for k = 1:numel(keywords)
  switch keywords{k}
    case 'simplex',    FitOpt.MethodID = 1;
    case 'levmar',     FitOpt.MethodID = 2;
    case 'montecarlo', FitOpt.MethodID = 3;
    case 'genetic',    FitOpt.MethodID = 4;
    case 'grid',       FitOpt.MethodID = 5;
    case 'swarm',      FitOpt.MethodID = 6;  
    case 'manual',     FitOpt.TargetID = 7;
    case 'fcn',        FitOpt.TargetID = 1;
    otherwise
      error('Unknown ''%s'' in FitOpt.Method.',keywords{k});
  end
end

%Make a list of the fields at which the spectra have been measured
AvailableFields = cell(1,length(Exp));
for i = 1:length(AvailableFields)
  AvailableFields{i} = strcat(string(Exp{i}.Field), ' mT');
end

%Get the number of CPU cores available for parallel processing
AvailableCores = cell(1,length(Exp));
AvailableCores{1} = 'off';
numcores = feature('numcores');
if numcores>1
    for i = 2:numcores
        AvailableCores{i} =sprintf('%i cores',i);
    end
end

%Set method names for display in the UI element
MethodNames{1} = 'Nelder/Mead simplex';
MethodNames{2} = 'Levenberg/Marquardt';
MethodNames{3} = 'Monte Carlo';
MethodNames{4} = 'genetic algorithm';
MethodNames{5} = 'grid search';
MethodNames{6} = 'particle swarm';
MethodNames{7} = 'Manual single run';
FitData.MethodNames = MethodNames;

%Set scaling names for display in the UI element
ScalingNames{1} = 'scale & shift (min/max)';
ScalingNames{2} = 'scale only (max abs)';
ScalingNames{3} = 'scale only (lsq)';
ScalingNames{4} = 'scale & shift (lsq0)';
ScalingNames{5} = 'scale & linear baseline (lsq1)';
ScalingNames{6} = 'scale & quad. baseline (lsq2)';
ScalingNames{7} = 'no scaling';
FitData.ScalingNames = ScalingNames;

%Set scaling names for the program
ScalingString{1} = 'minmax';
ScalingString{2} = 'maxabs';
ScalingString{3} = 'lsq';
ScalingString{4} = 'lsq0';
ScalingString{5} = 'lsq1';
ScalingString{6} = 'lsq2';
ScalingString{7} = 'none';
FitData.ScalingString = ScalingString;

%Set startpoint names for display in the UI element
StartpointNames{1} = 'center of range';
StartpointNames{2} = 'random within range';
StartpointNames{3} = 'selected parameter set';
FitData.StartpointNames = StartpointNames;
FitOpt.StartID = 1; 

FitOpt.ScalingID = find(strcmp(FitOpt.Scaling,ScalingString));
if isempty(FitOpt.ScalingID)
  error('Unknown ''%s'' in FitOpt.Scaling.',FitOpt.Scaling);
end

%Check if user has defined any of these fit options otherwise set defaults
if ~isfield(FitOpt,'Plot'), FitOpt.Plot = 1; end
if (nargout>0), FitData.GUI = 0; else, FitData.GUI = 1; end
if ~isfield(FitOpt,'PrintLevel'), FitOpt.PrintLevel = 1; end
if ~isfield(FitOpt,'nTrials'), FitOpt.nTrials = 20000; end
if ~isfield(FitOpt,'TolFun'), FitOpt.TolFun = 1e-4; end
if ~isfield(FitOpt,'TolStep'), FitOpt.TolStep = 1e-6; end
if ~isfield(FitOpt,'maxTime'), FitOpt.maxTime = inf; end
if ~isfield(FitOpt,'RandomStart'), FitOpt.Startpoint = 1; else, FitOpt.Startpoint = 0; end
if ~isfield(FitOpt,'GridSize'), FitOpt.GridSize = 7; end
if ~isfield(FitOpt,'PlotStretchFactor'), FitOpt.PlotStretchFactor = 0.05; end
if ~isfield(FitOpt,'maxGridPoints'), FitOpt.maxGridPoints = 1e5; end
if ~isfield(FitOpt,'maxParameters'), FitOpt.maxParameters = 30; end
if (FitData.nParameters>FitOpt.maxParameters)
  error('Cannot fit more than %d parameters simultaneously.',...
    FitOpt.maxParameters);
end
FitData.inactiveParams = logical(zeros(1,FitData.nParameters));
FitOpt.IterationPrintFunction = @iterationprint;

%Save the EasySpin structures to the global variable
FitData.Vary = Vary;
FitData.Exp = Exp;
FitData.Sys0 = Sys0;
FitData.SimOpt = SimOpt;
FitOpts = FitOpt;

%--------------------------------------------------------------------------
% Construction of the GUI
%--------------------------------------------------------------------------
if FitData.GUI
  
  %Close the RMSD detached plot if still open
    hObj = findobj('Tag','detachedRMSD');
  if ~isempty(hObj)
    close(hObj)
  end
  
  %Define default graphical settings
  FitOpts.GraphicalSettings.LineWidth = 1;
  FitOpts.GraphicalSettings.ContourLevels = 40;
  FitOpts.GraphicalSettings.ExperimentalSpectrumType = 1;
  FitOpts.GraphicalSettings.ExperimentalSpectrumTypeString = 'contour';
  FitOpts.GraphicalSettings.FitSpectraType = 1;
  FitOpts.GraphicalSettings.FitSpectraTypeString = 'colormap';


  % Construction of main figure
  %------------------------------------------------------------------------
  
  %Check if another instance is open, close it and create new one
  hFig = findobj('Tag','esfitFigure_hyscorean');
  if isempty(hFig)
    hFig = figure('Tag','esfitFigure_hyscorean','WindowStyle','normal');
  else
    figure(hFig);
    clf(hFig);
  end
  
  %Set main window properties
  sz = [1410 600]; %Figure size
  screensize = get(0,'ScreenSize'); %Get screensize
  xpos = ceil((screensize(3)-sz(1))/2); %Center the figure on the screen horizontally
  ypos = ceil((screensize(4)-sz(2))/2); %Center the figure on the screen vertically
  set(hFig,'position',[xpos, ypos, sz(1), sz(2)],'units','pixels');
  set(hFig,'WindowStyle','normal','DockControls','off','MenuBar','none');
  set(hFig,'Resize','off');
  set(hFig,'Name','Hyscorean: EasySpin - Least-Squares Fitting','NumberTitle','off');
  set(hFig,'CloseRequestFcn','global UserCommand; UserCommand = 99; drawnow; delete(gcf);');
  
  %Construct the axes in the figure
  excludedRegions = [];
  %Axis for main display
  hAx = axes('Parent',hFig,'Units','pixels',...
    'Position',[50 50 900 420],'FontSize',8,'Layer','top');
  %Axis for inset1
  hsubAx1 = axes('Parent',hFig,'Units','pixels',...
    'Position',[50 480 900 100],'FontSize',8,'Layer','top');
  %Axis for inset 2
  hsubAx2 = axes('Parent',hFig,'Units','pixels',...
    'Position',[960 50 100 420],'FontSize',8,'Layer','top');


  %Get experimental dataset to display
  dispData = FitData.ExpSpecScaled{FitData.CurrentSpectrumDisplay};
  
  %Construct a NaN dataset to use when not wanting to display
  NaNdata = ones(length(dispData))*NaN;
  
  %Get data limits
  maxy = max(max(dispData)); 
  miny = min(min(dispData));
  
  %Not sure if this is still needed
  YLimits = [miny maxy] + [-1 1]*FitOpt.PlotStretchFactor*(maxy-miny);
  for r = 1:size(excludedRegions,1)
    h = patch(excludedRegions(r,[1 2 2 1]),YLimits([1 1 2 2]),[1 1 1]*0.8);
    set(h,'EdgeColor','none');
  end
  
  %Construct frequency axis
  TimeStep = SimOpt{1}.TimeStepFactor*Exp{1}.dt;
  FrequencyAxis = linspace(-1/(2*TimeStep),1/(2*TimeStep),length(dispData));
  
  %Remove all warnings to avoid contour w/ NaN warning at initialization
  warning('off','all')
  
  % Construction of main display
  %------------------------------------------------------------------------
  grid(hAx,'on')
  hold(hAx,'on')
  
  %Plot auxiliary lines
  plot(hAx,ones(length(FrequencyAxis),1)*0,linspace(0,max(FrequencyAxis),length(FrequencyAxis)),'k-')
  plot(hAx,FrequencyAxis,abs(FrequencyAxis),'k-.')  
  
  %Define an auxiliary axis to contain the experimental spectrum
  ax1 = axes('Parent',hFig,'Tag','dataaxes_exp','Units','pixels',...
    'Position',[50 50 900 420],'FontSize',8,'Layer','bottom');
  
  %Create the EXPERIMENTAL spectrum plot
  switch   FitOpts.GraphicalSettings.ExperimentalSpectrumTypeString
    case 'contour'
      [~,h] = contour(ax1,FrequencyAxis,FrequencyAxis,NaNdata,100,...
        'LevelList',linspace(0,1,FitOpts.GraphicalSettings.ContourLevels),...
        'LineWidth',FitOpts.GraphicalSettings.LineWidth);
    case 'colormap'
      [h] = pcolor(ax1,FrequencyAxis,FrequencyAxis,NaNdata);
    case 'filledcontour'
      [~,h] = contourf(ax1,FrequencyAxis,FrequencyAxis,NaNdata,'LineStyle','none',...
        'LevelList',linspace(0,1,FitOpts.GraphicalSettings.ContourLevels));
  end
 
  %Create the BEST FIT spectrum plot
  switch   FitOpts.GraphicalSettings.FitSpectraTypeString
    case 'contour'
      [~,h2] = contour(hAx,FrequencyAxis,FrequencyAxis,NaNdata,100,...
        'LevelList',linspace(0,1,FitOpts.GraphicalSettings.ContourLevels),...
        'LineWidth',FitOpts.GraphicalSettings.LineWidth);
    case 'colormap'
      [h2] = pcolor(hAx,FrequencyAxis,FrequencyAxis,NaNdata);
    case 'filledcontour'
      [~,h2] = contourf(hAx,FrequencyAxis,FrequencyAxis,NaNdata,'LineStyle','none',...
        'LevelList',linspace(0,1,FitOpts.GraphicalSettings.ContourLevels));
  end
  
  %Use a custom made colormap for the fitted spectra
  % Normal  ->  Green-Red with white transition
  % Fliplr  ->  Blue-Orange with white transition
  CustomColormap = ...
  [0.0 0.5 0.2; 0.0 0.45 0.2; 0.0 0.4 0.2; 0.1 0.4 0.2; 0.2 0.4 0.2; 0.2 0.35 0.2;  0.2 0.35 0.2;  
   0.2 0.3 0.2; 0.2 0.20 0.2; 0.2 0.1 0.2; 0.0 0.4 0.2; 0.0 0.5 0.2; 0.0 0.60 0.2;  0.1 0.7 0.2; 
   0.2 0.8 0.2; 0.1 0.80 0.0; 0.2 0.8 0.0; 0.6 1.0 0.6; 0.7 1.0 0.7; 0.8 1.00 0.8;   
   1 1 1;
   1.00 0.7 0.7; 1.0 0.65 0.65; 1.0 0.6 0.6; 1.0 0.55 0.55; 1.00 0.5 0.5; 1.0 0.45 0.45; 1.0 0.4 0.4; 
   1.00 0.4 0.4; 1.0 0.30 0.30; 1.0 0.2 0.2; 1.0 0.10 0.10; 1.00 0.0 0.0; 0.95 0.0 0.00; 0.9 0.0 0.0; 
   0.85 0.0 0.0; 0.8 0.00 0.00; 0.7 0.0 0.0; 0.7 0.00 0.00; 0.65 0.0 0.0; 0.60 0.0 0.00];
  FitData.CustomColormap = CustomColormap;
  
  %Create the CURRENT FIT spectrum plot
  switch   FitOpts.GraphicalSettings.FitSpectraTypeString
    case 'contour'
      [~,h3] = contour(hAx,FrequencyAxis,FrequencyAxis,NaNdata,100,...
        'LevelList',linspace(0,1,FitOpts.GraphicalSettings.ContourLevels),...
        'LineWidth',FitOpts.GraphicalSettings.LineWidth);
    case 'colormap'
      [h3] = pcolor(hAx,FrequencyAxis,FrequencyAxis,NaNdata);
    case 'filledcontour'
      [~,h3] = contourf(hAx,FrequencyAxis,FrequencyAxis,NaNdata,'LineStyle','none',...
        'LevelList',linspace(0,1,FitOpts.GraphicalSettings.ContourLevels));
  end
  
  %Set the shading to interp for the fitted spectra to be able to see something
  shading(hAx,'interp');
  %Link the main display and auxiliary axis together
  linkaxes([ax1,hAx])
  %Now that they are linked give the experimental spectrum its own colormap...
  colormap(ax1,'gray');
  %And make the auxiliary axis invisible
  ax1.Visible = 'off';
  %For the other plots use the custom colormap
  colormap(hAx,CustomColormap)
  
  %Set the limits so that later the different colors of the colormap can be used
  set(hAx,'CLim',[-1 1])
  
  %Generate a NaN vector to use in the insets
  NaNdata = ones(1,length(dispData))*NaN;

  %Create inset 1 plots
  hold(hsubAx1,'on')
  hsub1 = plot(hsubAx1,FrequencyAxis,NaNdata,'Color','k');
  hsub1_2 = plot(hsubAx1,FrequencyAxis,NaNdata,'Color','g');
  hsub1_3 = plot(hsubAx1,FrequencyAxis,NaNdata,'Color','r');
  
  %Create inset 2 plots
  hold(hsubAx2,'on')
  hsub2 = plot(hsubAx2,FrequencyAxis,NaNdata,'Color','k');
  hsub2_2 = plot(hsubAx2,FrequencyAxis,NaNdata,'Color','g');
  hsub2_3 = plot(hsubAx2,FrequencyAxis,NaNdata,'Color','r');
  
  %Now that everything is plotted enable warnings again
  warning('on','all')
  
  %Insert the experimental spectrum data in the main display
  switch FitOpts.GraphicalSettings.ExperimentalSpectrumTypeString
    case 'colormap'
      set(h,'XData',FrequencyAxis,'YData',FrequencyAxis,'CData',dispData);
    case 'contour'
      set(h,'XData',FrequencyAxis,'YData',FrequencyAxis,'ZData',dispData);
  end
  
  %Set the tags of the different plots to access them later
  set(h,'Tag','expdata')
  set(h2,'Tag','bestsimdata');
  set(h3,'Tag','currsimdata');
  
  %Insert the experimental spectrum data in inset 1
  Inset = max(dispData(round(length(dispData)/2,0):end,:));
  set(hsub1,'Tag','expdata_projection1','XData',FrequencyAxis,'YData',Inset);
  set(hsub1_2,'Tag','bestsimdata_projection1');
  set(hsub1_3,'Tag','currsimdata_projection1');
  
  %Insert the experimental spectrum data in inset 2
  Inset = max(dispData,[],2);
  set(hsub2,'Tag','expdata_projection2','YData',FrequencyAxis,'XData',Inset);
  set(hsub2_2,'Tag','bestsimdata_projection2');
  set(hsub2_3,'Tag','currsimdata_projection2');
  
  %Set limits of all axes
  set(hAx,'XLim',[-SimOpt{FitData.CurrentSpectrumDisplay}.FreqLim SimOpt{FitData.CurrentSpectrumDisplay }.FreqLim]);
  set(hAx,'YLim',[0 SimOpt{FitData.CurrentSpectrumDisplay}.FreqLim]);
  set(hsubAx1,'XLim',[-SimOpt{FitData.CurrentSpectrumDisplay}.FreqLim SimOpt{FitData.CurrentSpectrumDisplay }.FreqLim]);
  set(hsubAx2,'YLim',[0 SimOpt{FitData.CurrentSpectrumDisplay}.FreqLim]);
  set(hsubAx1,'YLim',[0 1]);
  set(hsubAx2,'XLim',[0 1]);
  
  %Set labels of main axis
  xlabel(hAx,'\omega_1 [MHz]');
  ylabel(hAx,'\omega_2 [MHz]');
  
  %Remove all ticks in the insets
  set(hsubAx1,'XTickLabel',[],'YTickLabel',[]);
  set(hsubAx2,'XTickLabel',[],'YTickLabel',[]);
  
  %Give tags to the axes
  set(hAx,'Tag', 'dataaxes');
  set(hsubAx1,'Tag', 'projectiondataaxes1');
  set(hsubAx2,'Tag', 'projectiondataaxes2');
  
  %Add boxes for nicer display
  box(hAx,'on')
  box(hsubAx1,'on')
  box(hsubAx2,'on')
  
  %Link the axes of the main display to the insets (to zoom at the same time)
  linkaxes([hAx,hsubAx1],'x')
  linkaxes([hAx,hsubAx2],'y')

%--------------------------------------------------------------------------
% Construction of the UI elements
%--------------------------------------------------------------------------

% Field position selection
%-----------------------------------------------------------------------
x0 = 960; y0 = 380; dx = 80;
uicontrol('Style','text',...
  'Position',[x0 y0+125 230 20],...
  'BackgroundColor',get(gcf,'Color'),...
  'FontWeight','bold','String','Display @ field',...
  'HorizontalAl','left');

uicontrol('Style','pushbutton',...
  'Position',[x0 y0+155 100 25],...
  'Tag','GraphicsButton',...
  'BackgroundColor',get(gcf,'Color'),...
  'String','Graphics',...
  'HorizontalAl','left','Callback',@SetGraphicsSettings);

uicontrol(hFig,'Style','popupmenu',...
  'Position',[x0 y0+100 100 25],...
  'Tag','ChangeDisplay',...
  'String',AvailableFields,...
  'Value',FitData.CurrentSpectrumDisplay,...
  'BackgroundColor','w',...
  'Tooltip','Change displayed spectrum',...
  'Callback',@ChangeCurrentDisplay);
  
% Iteration and RMSD error displays
%-----------------------------------------------------------------------
x0 = 1070; y0 = 175;
hAx = axes('Parent',hFig,'Units','pixels','Position',[x0 y0-25 270 110],'Layer','top');
h = plot(hAx,1,NaN,'.');
set(h,'Tag','errorline','MarkerSize',6,'Color',[0.2 0.2 0.8]);
set(gca,'FontSize',7,'YScale','lin','XTick',[],'YAxisLoc','right','Layer','top');
title('log10(rmsd)','Color','k','FontSize',7,'FontWeight','normal');

h = uicontrol('Style','text','Position',[x0 y0+119 270 16]);
set(h,'FontSize',8,'String',' RMSD: -','ForegroundColor',[0 0 1],'Tooltip','Current best RMSD');
set(h,'Tag','RmsText','HorizontalAl','left');

h = uicontrol('Style','text','Position',[x0 y0+100 270 16]);
set(h,'FontSize',7,'Tag','logLine','Tooltip','Information from fitting algorithm');
set(h,'Horizontal','left');

h = uicontrol('Style','pushbutton','Position',[x0 y0-25 22 22]);
load([Path2Hyscorean 'bin\detach_icon'])
set(h,'FontSize',7,'Tag','ExpandRMSD',...
  'Tooltip','Show individual fits RMSD',...
  'CData',CData,...
  'Tooltip','Change displayed spectrum',...
  'Callback',@DetachRMSD);
set(h,'Horizontal','left');

 
% Parameter table
%-----------------------------------------------------------------------
columnname = {'','Name','best','current','center','vary'};
columnformat = {'logical','char','char','char','char','char'};
colEditable = [true false false true true true];
if ~isempty(fieldnames(Vary{1}))
  [FitData.parNames,FitData.CenterVals,FitData.VaryVals] = getParamList(Sys0,Vary);
  for p = 1:numel(FitData.parNames)
    data{p,1} = true;
    data{p,2} = FitData.parNames{p};
    data{p,3} = '-';
    data{p,4} = '-';
    data{p,5} = sprintf('%0.6g',FitData.CenterVals(p));
    data{p,6} = sprintf('%0.6g',FitData.VaryVals(p));
  end
else
  data{1,1} = false;
  data{1,2} = '-';
  data{1,3} = '-';
  data{1,4} = '-';
  data{1,5} = '-';
  data{1,6} = '-';
end

x0 = 1070; y0 = 400; dx = 80;
uitable('Tag','ParameterTable',...
  'FontSize',8,...
  'Position',[x0 y0 330 150],...
  'ColumnFormat',columnformat,...
  'ColumnName',columnname,...
  'ColumnEditable',colEditable,...
  'CellEditCallback',@tableEditCallback,...
  'ColumnWidth',{20,62,62,62,62,60},...
  'RowName',[],...
  'Data',data);

uicontrol('Style','text',...
  'Position',[x0 y0+170 230 20],...
  'BackgroundColor',get(gcf,'Color'),...
  'FontWeight','bold','String','System',...
  'HorizontalAl','left');

uicontrol('Style','text',...
  'Position',[x0+115 y0+169 230 20],...
  'BackgroundColor',get(gcf,'Color'),'ForegroundColor',[0 0 1],...
  'FontWeight','normal','String',FitData.Sys0{1}.Nucs,...
  'Tag','SystemName',...
  'HorizontalAl','left');

uicontrol('Style','text',...
  'Position',[x0 y0+150 230 20],...
  'BackgroundColor',get(gcf,'Color'),...
  'FontWeight','bold','String','Parameters',...
  'HorizontalAl','left');

uicontrol('Style','pushbutton','Tag','selectInvButton',...
  'Position',[x0+70 y0+172 40 20],...
  'String','...','Enable','on','Callback',@systemButtonCallback,...
  'HorizontalAl','left',...
  'Tooltip','Invert selection of parameters');

uicontrol('Style','pushbutton','Tag','selectInvButton',...
  'Position',[x0+210 y0+150 50 20],...
  'String','invert','Enable','on','Callback',@selectInvButtonCallback,...
  'HorizontalAl','left',...
  'Tooltip','Invert selection of parameters');

uicontrol('Style','pushbutton','Tag','selectAllButton',...
  'Position',[x0+260 y0+150 30 20],...
  'String','all','Enable','on','Callback',@selectAllButtonCallback,...
  'HorizontalAl','left',...
  'Tooltip','Select all parameters');

uicontrol('Style','pushbutton','Tag','selectNoneButton',...
  'Position',[x0+290 y0+150 40 20],...
  'String','none','Enable','on','Callback',@selectNoneButtonCallback,...
  'HorizontalAl','left',...
  'Tooltip','Unselect all parameters');

uicontrol(hFig,'Style','pushbutton','Tag','reportButton',...
  'Position',[x0+270 y0+171 60 25],...
  'String','Report',...
  'Tooltip','Generate fitting report','Enable','off',...
  'Callback',@reportButtonCallback);

uicontrol('Style','pushbutton','Tag','ORCAbutton',...
  'Position',[x0+160 y0+150 50 20],...
  'String','ORCA','Enable','on','Callback',@loadORCACallback,...
  'HorizontalAl','left',...
  'Tooltip','Load parameters from ORCA');


% Zoom in/out
%-----------------------------------------------------------------
Path = which('Hyscorean');
Path = Path(1:end-11);
[Image,~]=imread(fullfile(Path,'bin\zoomin_icon.jpg'));
CData=imresize(Image, [30 30]);
uicontrol('Style','pushbutton','Tag','ZoomInButton',...
  'Position',[52 438 30 30],'CData',CData,...
  'String','','Enable','on','Callback',@zoomInButtonCallback,...
  'HorizontalAl','left',...
  'Tooltip','Zoom spectra');

[Image,~]=imread(fullfile(Path,'bin\zoomout_icon.jpg'));
CData=imresize(Image, [30 30]);
uicontrol('Style','pushbutton','Tag','ZoomOutButton',...
  'Position',[52 406 30 30],'CData',CData,...
  'String','','Enable','on','Callback',@zoomOutButtonCallback,...
  'HorizontalAl','left',...
  'Tooltip','Reset zoom');

% ListBoxes
%-----------------------------------------------------------------
x0 = 1070; dx = 60; y0 = 299; dy = 24;
uicontrol(hFig,'Style','text',...
  'String','Method',...
  'FontWeight','bold',...
  'HorizontalAlign','left',...
  'BackgroundColor',get(gcf,'Color'),...
  'Position',[x0 y0+3*dy-4 dx 20]);

uicontrol(hFig,'Style','popupmenu',...
  'Tag','MethodMenu',...
  'String',MethodNames,...
  'Value',FitOpt.MethodID,...
  'BackgroundColor','w',...
  'Tooltip','Fitting algorithm',...
  'Position',[x0+dx y0+3*dy 150 20]);

uicontrol(hFig,'Style','text',...
  'String','Scaling',...
  'FontWeight','bold',...
  'HorizontalAlign','left',...
  'BackgroundColor',get(gcf,'Color'),...
  'Position',[x0 y0+2*dy-4 dx 20]);

uicontrol(hFig,'Style','popupmenu',...
  'Tag','ScalingMenu',...
  'String',ScalingNames,...
  'Value',FitOpt.ScalingID,...
  'BackgroundColor','w',...
  'Tooltip','Scaling mode',...
  'Position',[x0+dx y0+2*dy 150 20]);

uicontrol(hFig,'Style','text',...
  'String','Startpoint',...
  'FontWeight','bold',...
  'HorizontalAlign','left',...
  'BackgroundColor',get(gcf,'Color'),...
  'Position',[x0 y0+dy-4 dx 20]);

h = uicontrol(hFig,'Style','popupmenu',...
  'Tag','StartpointMenu',...
  'String',StartpointNames,...
  'Callback',@StartpointNamesCallback,...
  'Value',1,...
  'BackgroundColor','w',...
  'Tooltip','Starting point for fit',...
  'Position',[x0+dx y0+dy 150 20]);

if (FitOpts.Startpoint==2), set(h,'Value',2); end
  
% Start/Stop and Speed-ups
%-----------------------------------------------------------------
pos =  [x0+220 y0-3+50 110 45];
pos1 = [x0+220 y0-3+25 110 25];
uicontrol(hFig,'Style','pushbutton',...
  'Tag','StartButton',...
  'String','Start',...
  'Callback',@runFitting,...
  'Visible','on',...
  'Tooltip','Start fitting',...
  'Position',pos);

uicontrol(hFig,'Style','pushbutton',...
  'Tag','StopButton',...
  'String','Stop',...
  'Visible','off',...
  'Tooltip','Stop fitting',...
  'Callback','global UserCommand; UserCommand = 1;',...
  'Position',pos);

uicontrol(hFig,'Style','pushbutton',...
  'Tag','SaveButton',...
  'String','Save parameter set',...
  'Callback',@saveFitsetCallback,...
  'Enable','off',...
  'Tooltip','Save latest fitting result',...
  'Position',pos1);

uicontrol(hFig,'Style','checkbox',...
  'Tag','ProductRule',...
  'String','Product Rule',...
  'Value',0,...
  'Callback',@ProductRuleCallback,...
  'Enable','on',...
  'Tooltip','Use product rule for simulations',...
  'Position',[x0+250 y0-3 80 25]);

uicontrol(hFig,'Style','popupmenu',...
  'Tag','SpeedUp',...
  'String',AvailableCores,...
  'Value',FitData.CurrentCoreUsage+1,...
  'Callback',@speedUpCallback,...
  'Enable','on',...
  'Tooltip','Parallel computing options',...
  'Position',[x0+185 y0-5 60 25]);

uicontrol('Style','text',...
  'String','Speed-up',...
  'Position',[x0+133 y0-8 50 25],...
  'HorizontalAlignment','right',...
  'BackgroundColor',get(gcf,'Color'),...
  'HorizontalAl','left');

IconData = imread(fullfile(Path2Hyscorean,'bin\detach_icon.png'));
uicontrol('Style','pushbutton','Tag','detachButton',...
  'Position',[927 446 22 22],'CData',IconData,...
  'String','','Enable','on','Callback',@detachButtonCallback,...
  'Tooltip','Detach current display to new window');

% Fitset list
%-----------------------------------------------------------------
x0 = 1070; y0 = 10;
uicontrol('Style','text','Tag','SetListTitle',...
  'Position',[x0 y0+100 230 20],...
  'BackgroundColor',get(gcf,'Color'),...
  'FontWeight','bold','String','Parameter sets',...
  'Tooltip','List of stored fit parameter sets',...
  'HorizontalAl','left');

uicontrol(hFig,'Style','listbox','Tag','SetListBox',...
  'Position',[x0 y0 330 100],...
  'String','','Tooltip','',...
  'BackgroundColor',[1 1 0.9],...
  'KeyPressFcn',@deleteSetListKeyPressFcn,...
  'Callback',@setListCallback);

uicontrol(hFig,'Style','pushbutton','Tag','deleteSetButton',...
  'Position',[x0+280 y0+100 50 20],...
  'String','delete',...
  'Tooltip','Delete fit set','Enable','off',...
  'Callback',@deleteSetButtonCallback);

uicontrol(hFig,'Style','pushbutton','Tag','exportSetButton',...
  'Position',[x0+230 y0+100 50 20],...
  'String','export',...
  'Tooltip','Export fit set to workspace','Enable','off',...
  'Callback',@exportSetButtonCallback);

uicontrol(hFig,'Style','pushbutton','Tag','sortIDSetButton',...
  'Position',[x0+210 y0+100 20 20],...
  'String','id',...
  'Tooltip','Sort parameter sets by ID','Enable','off',...
  'Callback',@sortIDSetButtonCallback);

uicontrol(hFig,'Style','pushbutton','Tag','sortRMSDSetButton',...
  'Position',[x0+180 y0+100 30 20],...
  'String','rmsd',...
  'Tooltip','Sort parameter sets by rmsd','Enable','off',...
  'Callback',@sortRMSDSetButtonCallback);

drawnow

set(hFig,'NextPlot','new');

end


% Run fitting routine if not GUI
if (~FitData.GUI)
  [BestSys,BestSpec,Residuals] = runFitting;
end

% Arrange outputs if not GUI
if ~FitData.GUI
  if (nSystems==1), BestSys = BestSys{1}; end
  switch (nargout)
    case 0, varargout = {BestSys};
    case 1, varargout = {BestSys};
    case 2, varargout = {BestSys,BestSpec};
    case 3, varargout = {BestSys,BestSpec,Residuals};
  end
else
  varargout = cell(1,nargout);
end

clear global UserCommand

function [FinalSys,BestSpec,Residuals] = runFitting(object,src,event)

%===================================================================
% Main fitting function
%===================================================================

global FitOpts FitData UserCommand

try

UserCommand = 0;

%===================================================================
% Update UI, pull settings from UI
%===================================================================
if FitData.GUI
    
  % Hide Start button, show Stop button
  set(findobj('Tag','StopButton'),'Visible','on');
  set(findobj('Tag','StartButton'),'Visible','off');
  set(findobj('Tag','SaveButton'),'Enable','off');
  
  % Disable listboxes
  set(findobj('Tag','MethodMenu'),'Enable','off');
  set(findobj('Tag','TargetMenu'),'Enable','off');
  set(findobj('Tag','ScalingMenu'),'Enable','off');
  set(findobj('Tag','StartpointMenu'),'Enable','off');
  
  % Disable parameter table
  set(findobj('Tag','selectAllButton'),'Enable','off');
  set(findobj('Tag','selectNoneButton'),'Enable','off');
  set(findobj('Tag','selectInvButton'),'Enable','off');
  set(getParameterTableHandle,'Enable','off');
  set(findobj('Tag','ORCAbutton'),'Enable','off');
  set(findobj('Tag','GraphicsButton'),'Enable','off');
  set(findobj('Tag','detachButton'),'Enable','off');

  % Disable speedups and report
  set(findobj('Tag','ProductRule'),'Enable','off');
  set(findobj('Tag','SpeedUp'),'Enable','off');
  set(findobj('Tag','reportButton'),'Enable','off');

  % Disable fitset list controls
  set(findobj('Tag','deleteSetButton'),'Enable','off');
  set(findobj('Tag','exportSetButton'),'Enable','off');
  set(findobj('Tag','sortIDSetButton'),'Enable','off');
  set(findobj('Tag','sortRMSDSetButton'),'Enable','off');
  
  drawnow
  
  % Determine selected method, target, and scaling
  FitOpts.MethodID = get(findobj('Tag','MethodMenu'),'Value');
  FitOpts.TargetID = 1;
  FitOpts.Scaling = FitData.ScalingString{get(findobj('Tag','ScalingMenu'),'Value')};
  FitOpts.Startpoint = get(findobj('Tag','StartpointMenu'),'Value');
  
end

%===================================================================
% Run fitting algorithm
%===================================================================

if ~FitData.GUI
  if FitOpts.PrintLevel
    disp('-- esfit ------------------------------------------------');
    fprintf('Simulation function:      %s\n',FitData.SimFcnName);
    fprintf('Problem size:             %d spectra, %d components, %d parameters\n',FitData.nSpectra,FitData.nSystems,FitData.nParameters);
    fprintf('Minimization method:      %s\n',FitData.MethodNames{FitOpts.MethodID});
    fprintf('Residuals computed from:  %s\n',FitData.TargetNames{FitOpts.TargetID});
    fprintf('Scaling mode:             %s\n',FitOpts.Scaling);
    disp('---------------------------------------------------------');
  end
end

if FitData.GUI
  data = get(getParameterTableHandle,'Data');
  for iPar = 1:FitData.nParameters
    FitData.inactiveParams(iPar) = data{iPar,1}==0;
  end
end

switch FitOpts.Startpoint
  case 1 % center of range
    startx = zeros(FitData.nParameters,1);
  case 2 % random
    startx = 2*rand(FitData.nParameters,1) - 1;
    startx(FitData.inactiveParams) = 0;
  case 3 % selected fit set
    h = findobj('Tag','SetListBox');
    s = get(h,'String');
    if ~isempty(s)
      s = s{get(h,'Value')};
      ID = sscanf(s,'%d');
      startx = FitData.FitSets(ID).bestx;
    else
      startx = zeros(FitData.nParameters,1);
    end
end
FitData.startx = startx;

x0_ = startx;
x0_(FitData.inactiveParams) = [];
nParameters_ = numel(x0_);

bestx = startx;
if strcmp(FitOpts.Scaling, 'none')
  fitspc = FitData.ExpSpec;
else
  fitspc = FitData.ExpSpecScaled;
end

funArgs = {fitspc,FitData,FitOpts};  % input args for assess and residuals_

% Depending on the method chosen launch the assess function with a different esfit function
if (nParameters_>0)
  switch FitOpts.MethodID
    case 1 % Nelder/Mead simplex
      bestx0_ = esfit_simplex(@assess,x0_,FitOpts,funArgs{:});
    case 2 % Levenberg/Marquardt
      FitOpts.Gradient = FitOpts.TolFun;
      bestx0_ = esfit_levmar(@residuals_,x0_,FitOpts,funArgs{:});
    case 3 % Monte Carlo
      bestx0_ = esfit_montecarlo(@assess,nParameters_,FitOpts,funArgs{:});
    case 4 % Genetic
      bestx0_ = esfit_genetic(@assess,nParameters_,FitOpts,funArgs{:});
    case 5 % Grid search
      bestx0_ = esfit_grid(@assess,nParameters_,FitOpts,funArgs{:});
    case 6 % Particle swarm
      bestx0_ = esfit_swarm(@assess,nParameters_,FitOpts,funArgs{:});
    case 7 %Manual fit
      assess(startx,funArgs{:});
      bestx0_ = startx;
  end
  bestx(~FitData.inactiveParams) = bestx0_;
end

if FitData.GUI
  
  % Remove current values from parameter table
  hTable = getParameterTableHandle;
  Data = get(hTable,'Data');
  for p = 1:size(Data,1), Data{p,4} = '-'; end
  set(hTable,'Data',Data);
  
  if FitOpts.MethodID~=7
    
    %If using AUTOMATIC FITTING
    switch FitOpts.GraphicalSettings.FitSpectraTypeString
      case 'colormap'
        set(findobj('Tag','currsimdata'),'CData',NaN*ones(length(FitData.ExpSpec{FitData.CurrentSpectrumDisplay}),length(FitData.ExpSpec{FitData.CurrentSpectrumDisplay})));
      case 'contour'
        set(findobj('Tag','currsimdata'),'ZData',NaN*ones(length(FitData.ExpSpec{FitData.CurrentSpectrumDisplay}),length(FitData.ExpSpec{FitData.CurrentSpectrumDisplay})));
    end
    
    set(findobj('Tag','currsimdata_projection2'),'YData',NaN*ones(1,length(FitData.ExpSpec{FitData.CurrentSpectrumDisplay})));
    set(findobj('Tag','currsimdata_projection1'),'YData',NaN*ones(1,length(FitData.ExpSpec{FitData.CurrentSpectrumDisplay})));
    
  else
    
    %If using MANUAL FITTING (colormap  has been already flipped during assess)
    switch FitOpts.GraphicalSettings.FitSpectraTypeString
      case 'colormap'
        set(findobj('Tag','bestsimdata'),'CData',NaN*ones(length(FitData.ExpSpec{FitData.CurrentSpectrumDisplay}),length(FitData.ExpSpec{FitData.CurrentSpectrumDisplay})));
      case 'contour'
        set(findobj('Tag','bestsimdata'),'ZData',NaN*ones(length(FitData.ExpSpec{FitData.CurrentSpectrumDisplay}),length(FitData.ExpSpec{FitData.CurrentSpectrumDisplay})));
    end
    set(findobj('Tag','bestsimdata_projection2'),'YData',NaN*ones(1,length(FitData.ExpSpec{FitData.CurrentSpectrumDisplay})));
    set(findobj('Tag','bestsimdata_projection1'),'YData',NaN*ones(1,length(FitData.ExpSpec{FitData.CurrentSpectrumDisplay})));
  end
  drawnow
  set(findobj('Tag','logLine'),'String','');

  % Reactivate UI components
  set(findobj('Tag','SaveButton'),'Enable','on'); 
  if isfield(FitData,'FitSets') && numel(FitData.FitSets)>0
    set(findobj('Tag','deleteSetButton'),'Enable','on');
    set(findobj('Tag','exportSetButton'),'Enable','on');
    set(findobj('Tag','sortIDSetButton'),'Enable','on');
    set(findobj('Tag','sortRMSDSetButton'),'Enable','on');
  end
  
  % Hide stop button, show start button
  set(findobj('Tag','StopButton'),'Visible','off');
  set(findobj('Tag','StartButton'),'Visible','on');
  set(findobj('Tag','reportButton'),'Enable','on');
  set(findobj('Tag','SpeedUp'),'Enable','on');
  set(findobj('Tag','ProductRule'),'Enable','on');
  set(findobj('Tag','ORCAbutton'),'Enable','on');
  set(findobj('Tag','GraphicsButton'),'Enable','on');
  set(findobj('Tag','detachButton'),'Enable','on');
  
  % Re-enable listboxes
  set(findobj('Tag','MethodMenu'),'Enable','on');
  set(findobj('Tag','TargetMenu'),'Enable','on');
  set(findobj('Tag','ScalingMenu'),'Enable','on');
  set(findobj('Tag','StartpointMenu'),'Enable','on');
  
  % Re-enable parameter table and its selection controls
  set(findobj('Tag','selectAllButton'),'Enable','on');
  set(findobj('Tag','selectNoneButton'),'Enable','on');
  set(findobj('Tag','selectInvButton'),'Enable','on');
  set(getParameterTableHandle,'Enable','on');
  
end

%===================================================================
% Final stage: simulate the best spectrum again
%===================================================================

%Compile best-fit system structures
[FinalSys,bestvalues] = getSystems(FitData.Sys0,FitData.Vary,bestx);

%Simulate best-fit spectrum
if numel(FinalSys)==1
  fs = FinalSys{1};
else
  fs = FinalSys;
end

numSpec = length(FitData.Exp);

%initialize rmsd to allow recursive summation
rmsd = 0;
BestSpec = cell(numSpec,1);
BestSpecScaled = cell(numSpec,1);
Residuals = cell(numSpec,1);
rmsd_individual = cell(numSpec,1);

%Loop over all field positions (i.e. different files/spectra)
parfor (Index = 1:numSpec,FitData.CurrentCoreUsage)

  %Run saffron for a given field position
  [t1,t2,~,out] = saffron(fs,FitData.Exp{Index},FitData.SimOpt{Index});
  %Get time-domain signal
  if iscell(out)
  Out = out{1:FitData.nOutArguments};
  else
    Out = out;
  end
  td = Out.td;
  %Do base-correction as would be done in saffron
  tdx = basecorr(td,[1 2],[0 0]);
  %If done for experimental data, then do Lorentz-Gauss transformation
  if FitData.SimOpt{Index}.Lorentz2GaussCheck
    Processed.TimeAxis1 = t1;
    Processed.TimeAxis2 = t2;
    Processed.Signal = tdx;
    [Processed]=Lorentz2Gauss2D(Processed,FitData.SimOpt{Index}.L2GParameters);
    tdx = Processed.Signal;
  end
  %Use same apodization window as experimental data
  tdx = apodizationWin(tdx,FitData.SimOpt{Index}.WindowType,FitData.SimOpt{Index}.WindowDecay1,FitData.SimOpt{Index}.WindowDecay2);
  %Fourier transform with same zerofilling as experimental data
  Spectrum = fftshift(fft2(tdx,FitData.SimOpt{Index}.ZeroFillFactor*FitData.Exp{Index}.nPoints,FitData.SimOpt{Index}.ZeroFillFactor*FitData.Exp{Index}.nPoints));
  %Symmetrize the spectrum if needed
  switch FitData.SimOpt{Index}.Symmetrization
    case 'Diagonal'
      Spectrum = (Spectrum.*Spectrum').^0.5;
    case 'Anti-Diagonal'
      Spectrum = fliplr(fliplr(Spectrum).*fliplr(Spectrum)').^0.5;
    case 'Both'
      Spectrum = (Spectrum.*Spectrum').^0.5;
      Spectrum = fliplr(fliplr(Spectrum).*fliplr(Spectrum)').^0.5;
  end
   BestSpec{Index} = Spectrum;
  % (SimSystems{s}.weight is taken into account in the simulation function)
  BestSpecScaled{Index} = rescale_mod(BestSpec{Index},FitData.ExpSpecScaled{Index},FitOpts.Scaling);
  if length(FitData.ExpSpec{Index})~=BestSpecScaled{Index}
    BestSpecScaled{Index} = reshape(BestSpecScaled{Index},length(FitData.ExpSpec{Index}),length(FitData.ExpSpec{Index}));
  end
  BestSpec{Index} = rescale_mod(BestSpec{Index},FitData.ExpSpec{Index},FitOpts.Scaling);
  if length(FitData.ExpSpec)~=BestSpec{Index}
    BestSpec{Index} = reshape(BestSpec{Index},length(FitData.ExpSpec{Index}),length(FitData.ExpSpec{Index}));
  end
  
  %Compute the residual
  Residuals{Index} = norm(BestSpec{Index} - FitData.ExpSpec{Index});
  %Compute the individual and total RMSD
  rmsd_individual{Index} = norm(BestSpec{Index} - FitData.ExpSpec{Index})/sqrt(numel(FitData.ExpSpec{Index}));
  rmsd = rmsd + rmsd_individual{Index};
  
end

if ~FitData.GUI
  
  if FitOpts.PrintLevel && (UserCommand~=99)
    disp('---------------------------------------------------------');
    disp('Best-fit parameters:');
    str = bestfitlist(FinalSys,FitData.Vary);
    fprintf(str);
    fprintf('Residuals of best fit:\n    rmsd  %g\n',rmsd);
    disp('=========================================================');
  end

else
    
  % Save current set to set list
  newFitSet.rmsd = rmsd;
  if strcmp(FitOpts.Scaling, 'none')
    newFitSet.fitSpec = BestSpec;
    newFitSet.expSpec = FitData.ExpSpec;
  else
    newFitSet.fitSpec = BestSpecScaled;
    newFitSet.expSpec = FitData.ExpSpecScaled;
  end
  newFitSet.residuals = Residuals;
  newFitSet.bestx = bestx;
  newFitSet.bestvalues = bestvalues;
  TargetKey = {'fcn','int','iint','diff','fft'};
  newFitSet.Target = TargetKey{FitOpts.TargetID};
  if numel(FinalSys)==1
    newFitSet.Sys = FinalSys{1};
  else
    newFitSet.Sys = FinalSys;
  end
  FitData.currFitSet = newFitSet;
  
end



catch Error
  
    %In case some error occurs catch it, display it and then reactivate the
  %whole GUI to avoid getting stuck in a crash
  
  w = errordlg(sprintf('The fit protocol stopped due to an error : \n\n %s \n\n Please check your input. If this error persists restart the program.',getReport(Error,'extended','hyperlinks','off')),'Error','modal');
  waitfor(w);
  % If fails hide Stop button, show Start button
  set(findobj('Tag','StopButton'),'Visible','off');
  set(findobj('Tag','StartButton'),'Visible','on');
  set(findobj('Tag','SaveButton'),'Enable','off');
  % Re-enable listboxes
  set(findobj('Tag','MethodMenu'),'Enable','on');
  set(findobj('Tag','TargetMenu'),'Enable','on');
  set(findobj('Tag','ScalingMenu'),'Enable','on');
  set(findobj('Tag','StartpointMenu'),'Enable','on');
  % Re-enable parameter table and its selection controls
  set(findobj('Tag','selectAllButton'),'Enable','on');
  set(findobj('Tag','selectNoneButton'),'Enable','on');
  set(findobj('Tag','selectInvButton'),'Enable','on');
  set(findobj('Tag','reportButton'),'Enable','off');
  set(findobj('Tag','SpeedUp'),'Enable','on');
  set(findobj('Tag','ProductRule'),'Enable','on');
  set(findobj('Tag','ORCAbutton'),'Enable','on');
  set(findobj('Tag','GraphicsButton'),'Enable','on');
  set(findobj('Tag','detachButton'),'Enable','on');
  set(getParameterTableHandle,'Enable','on');

end

return
%===================================================================


%===================================================================
function resi = residuals_(x,ExpSpec,FitDat,FitOpt)
[rms,resi] = assess(x,ExpSpec,FitDat,FitOpt);
%===================================================================

%===================================================================
% Assess the current parameter set by simulating and getting rmsd                                                               
%===================================================================
function varargout = assess(x,ExpSpec,FitDat,FitOpt)


global UserCommand FitData FitOpts
persistent BestSys;

if ~isfield(FitData,'smallestError') || isempty(FitData.smallestError)
  FitData.smallestError = inf;
end
if ~isfield(FitData,'errorlist')
  FitData.errorlist = [];
end
if ~isfield(FitData,'individualErrors')
  FitData.individualErrors = cell(FitData.numSpec,1);
end

Sys0 = FitDat.Sys0;
Vary = FitDat.Vary;
Exp = FitDat.Exp;
SimOpt = FitDat.SimOpt;
rmsd_individual = cell(FitData.numSpec,1);

% Simulate spectra ------------------------------------------
inactive = FitData.inactiveParams;
x_all = FitData.startx;
x_all(~inactive) = x;
[SimSystems,simvalues] = getSystems(Sys0,Vary,x_all);

numSpec = length(Exp);
rmsd = 0;
simspec = cell(numSpec,1);
rmsd_individual = cell(numSpec,1);
nOutArguments = FitData.nOutArguments;
SimFcnHandel = FitData.SimFcn;
ScalingOption = FitOpt.Scaling;
%Loop over all field positions (i.e. different files/spectra)
parfor (Index = 1:numSpec,FitData.CurrentCoreUsage)
  if numel(SimSystems)==1
    [t1,t2,~,out] = saffron(SimSystems,Exp{Index},SimOpt{Index});
  else
    [t1,t2,~,out] = saffron(SimSystems,Exp{Index},SimOpt{Index});
  end
  
  %Get time-domain signal
  if iscell(out)
    Out = out{1:nOutArguments};
  else
    Out = out;
  end
  td = Out.td;
  %Do base-correction as would be done in saffron
  tdx = basecorr(td,[1 2],[0 0]);
  %If done for experimental data, then do Lorentz-Gauss transformation
  if SimOpt{Index}.Lorentz2GaussCheck
    Processed.TimeAxis1 = t1;
    Processed.TimeAxis2 = t2;
    Processed.Signal = tdx;
    [Processed]=Lorentz2Gauss2D(Processed,SimOpt{Index}.L2GParameters);
    tdx = Processed.Signal;
  end
  %Use same apodization window as experimental data
  tdx = apodizationWin(tdx,SimOpt{Index}.WindowType,SimOpt{Index}.WindowDecay1,SimOpt{Index}.WindowDecay2);
  %Fourier transform with same zerofilling as experimental data
  Spectrum = fftshift(fft2(tdx,SimOpt{Index}.ZeroFillFactor*Exp{Index}.nPoints,SimOpt{Index}.ZeroFillFactor*Exp{Index}.nPoints));
  switch SimOpt{Index}.Symmetrization
    case 'Diagonal'
      Spectrum = (Spectrum.*Spectrum').^0.5;
    case 'Anti-Diagonal'
      Spectrum = fliplr(fliplr(Spectrum).*fliplr(Spectrum)').^0.5;
    case 'Both'
      Spectrum = (Spectrum.*Spectrum').^0.5;
      Spectrum = fliplr(fliplr(Spectrum).*fliplr(Spectrum)').^0.5;
  end
   simspec{Index} = Spectrum;
  
  % (SimSystems{s}.weight is taken into account in the simulation function)
  % simspec = out{FitData.OutArgument}; % pick last output argument
  
  % Scale simulated spectrum to experimental spectrum ----------
  simspec{Index} = rescale_mod(simspec{Index},ExpSpec{Index},ScalingOption);
  simspec{Index}  = reshape(simspec{Index},length(ExpSpec{Index}),length(ExpSpec{Index}));
  
  rmsd_individual{Index} = norm(simspec{Index} - ExpSpec{Index})/sqrt(numel(ExpSpec{Index}));
  rmsd = rmsd + rmsd_individual{Index};
 

end

for i=1:FitData.numSpec
 FitData.individualErrors{i} = [FitData.individualErrors{i} rmsd_individual{i}];
end

FitData.errorlist = [FitData.errorlist rmsd];
isNewBest = rmsd<FitData.smallestError;

if isNewBest
  FitData.smallestError = rmsd;
  FitData.bestspec = simspec;
  BestSys = SimSystems;
end

% update GUI
%-----------------------------------------------------------

FitData.DisplayingFitSetSpec = false;

if FitData.GUI%&& ((UserCommand~=99) )
  TimeStep = FitData.Exp{FitData.CurrentSpectrumDisplay}.dt;
  FrequencyAxis = linspace(-1/(2*TimeStep),1/(2*TimeStep),length(FitData.ExpSpec{FitData.CurrentSpectrumDisplay}));
    CurrentExpSpec = ExpSpec{FitData.CurrentSpectrumDisplay};
    CurrentSimSpec = simspec{FitData.CurrentSpectrumDisplay};
    FitData.CurrentSimSpec = simspec;
    CurrentBestSpec = FitData.bestspec{FitData.CurrentSpectrumDisplay};

if FitOpts.MethodID<7
  % update contour graph  
  %       set(findobj('Tag','expdata'),'XData',FrequencyAxis,'YData',FrequencyAxis,'ZData',CurrentExpSpec);
  handle = findobj('Tag','currsimdata');
  colormap(handle.Parent,(FitData.CustomColormap))
  
  switch FitOpts.GraphicalSettings.FitSpectraTypeString
    case 'colormap'
      if isequal(abs(CurrentBestSpec),abs(CurrentSimSpec))
        set(findobj('Tag','bestsimdata'),'XData',FrequencyAxis,'YData',FrequencyAxis,'CData',-abs(CurrentBestSpec));
        set(findobj('Tag','currsimdata'),'XData',FrequencyAxis,'YData',FrequencyAxis,'CData',NaN*abs(CurrentSimSpec));
      else
        set(findobj('Tag','bestsimdata'),'XData',FrequencyAxis,'YData',FrequencyAxis,'CData',-abs(CurrentBestSpec));
        set(findobj('Tag','currsimdata'),'XData',FrequencyAxis,'YData',FrequencyAxis,'CData',abs(CurrentSimSpec));
      end
    case 'contour'
      set(findobj('Tag','bestsimdata'),'XData',FrequencyAxis,'YData',FrequencyAxis,'ZData',-abs(CurrentBestSpec));
      set(findobj('Tag','currsimdata'),'XData',FrequencyAxis,'YData',FrequencyAxis,'ZData',abs(CurrentSimSpec))
  end
  % update upper projection graph
  Inset = max(CurrentExpSpec,[],1);
  set(findobj('Tag','expdata_projection2'),'YData',FrequencyAxis,'XData',Inset);
    Temp = abs(CurrentBestSpec);
    %   Temp = abs(CurrentBestSpec)/max(max(abs(CurrentBestSpec)));
    Inset = max(Temp(:,round(length(Temp)/2,0):end),[],2);
    set(findobj('Tag','bestsimdata_projection2'),'YData',FrequencyAxis,'XData',Inset);
    %   Temp = abs(CurrentSimSpec)/max(max(abs(CurrentSimSpec)));
    Temp = abs(CurrentSimSpec);
    Inset = max(Temp(:,round(length(Temp)/2,0):end),[],2);
    set(findobj('Tag','currsimdata_projection2'),'YData',FrequencyAxis,'XData',Inset,'Color','r');
    % update lower projection graph
    Inset = max(CurrentExpSpec(round(length(CurrentExpSpec)/2,0):end,:));
%     set(findobj('Tag','expdata_projection1'),'XData',FrequencyAxis,'YData',Inset);
    %   Temp = abs(CurrentBestSpec)/max(max(abs(CurrentBestSpec)));
    Temp = abs(CurrentBestSpec);
    Inset = max(Temp(:,round(length(Temp)/2,0):end),[],2);
    set(findobj('Tag','bestsimdata_projection1'),'XData',FrequencyAxis,'YData',Inset);
    %   Temp = abs(CurrentSimSpec)/max(max(abs(CurrentSimSpec)));
    Temp = abs(CurrentSimSpec);
    Inset = max(Temp(:,round(length(Temp)/2,0):end),[],2);
    set(findobj('Tag','currsimdata_projection1'),'XData',FrequencyAxis,'YData',Inset,'Color','r');
    
  if strcmp(FitOpts.Scaling, 'none')
    dispData = [FitData.ExpSpec;real(FitData.bestspec).';abs(CurrentSimSpec).'];
    maxy = max(max(dispData)); miny = min(min(dispData));
    YLimits = [miny maxy] + [-1 1]*FitOpt.PlotStretchFactor*(maxy-miny);
    set(findobj('Tag','dataaxes'),'YLim',YLimits);
  end
  
elseif FitOpts.MethodID==7
      handle = findobj('Tag','currsimdata');
    colormap(handle.Parent,fliplr(FitData.CustomColormap))
  switch FitOpts.GraphicalSettings.FitSpectraTypeString
    case 'colormap'
      set(findobj('Tag','currsimdata'),'XData',FrequencyAxis,'YData',FrequencyAxis,'CData',abs(CurrentSimSpec));
    case 'contour' 
    set(findobj('Tag','currsimdata'),'XData',FrequencyAxis,'YData',FrequencyAxis,'ZData',abs(CurrentSimSpec))
  end
  Temp = abs(CurrentSimSpec);
  Inset = max(Temp(:,round(length(Temp)/2,0):end),[],2);
  set(findobj('Tag','currsimdata_projection2'),'YData',FrequencyAxis,'XData',Inset,'Color','b');
  Temp = abs(CurrentSimSpec);
  Inset = max(Temp(:,round(length(Temp)/2,0):end),[],2);
  set(findobj('Tag','currsimdata_projection1'),'XData',FrequencyAxis,'YData',Inset,'Color','b');
  
else
  
  switch FitOpts.GraphicalSettings.FitSpectraTypeString
    case 'colormap'
      handle = findobj('Tag','currsimdata');
    ColormapNew = [FitData.CustomColormap(:,2)  FitData.CustomColormap(:,2) FitData.CustomColormap(:,1)];
    colormap(handle.Parent,ColormapNew)
    set(findobj('Tag','currsimdata'),'XData',FrequencyAxis,'YData',FrequencyAxis,'CData',-abs(CurrentSimSpec));
    case 'contour' 
    set(findobj('Tag','currsimdata'),'XData',FrequencyAxis,'YData',FrequencyAxis,'ZData',-abs(CurrentSimSpec))
  end
  Temp = abs(CurrentSimSpec);
  Inset = max(Temp(:,round(length(Temp)/2,0):end),[],2);
  cmp = lines(5);
  set(findobj('Tag','currsimdata_projection2'),'YData',FrequencyAxis,'XData',Inset,'Color',cmp(3,:));
  Temp = abs(CurrentSimSpec);
  Inset = max(Temp(:,round(length(Temp)/2,0):end),[],2);
  set(findobj('Tag','currsimdata_projection1'),'XData',FrequencyAxis,'YData',Inset,'Color',cmp(3,:));
  
end
  drawnow
  
  % update numbers parameter table
  if (UserCommand~=99)
    
    % current system set
    hParamTable = getParameterTableHandle;
    data = get(hParamTable,'data');
    for p=1:numel(simvalues)
      olddata = striphtml(data{p,4});
      newdata = sprintf('%0.6f',simvalues(p));
      idx = 1;
      while (idx<=length(olddata)) && (idx<=length(newdata))
        if olddata(idx)~=newdata(idx), break; end
        idx = idx + 1;
      end
      active = data{p,1};
      if active
        data{p,4} = ['<html><font color="#000000">' newdata(1:idx-1) '</font><font color="#ff0000">' newdata(idx:end) '</font></html>'];
      else
        data{p,4} = ['<html><font color="#888888">' newdata '</font></html>'];
      end
    end
    
    % current system set is new best
    if isNewBest
      [str,values] = getSystems(BestSys,Vary);
      
      str = sprintf(' RMSD: %g\n',(FitData.smallestError));
      hRmsText = findobj('Tag','RmsText');
      set(hRmsText,'String',str);
      
      for p=1:numel(values)
        olddata = striphtml(data{p,3});
        newdata = sprintf('%0.6g',values(p));
        idx = 1;
        while (idx<=length(olddata)) && (idx<=length(newdata))
          if olddata(idx)~=newdata(idx), break; end
          idx = idx + 1;
        end
        active = data{p,1};
        if active
          data{p,3} = ['<html><font color="#000000">' newdata(1:idx-1) '</font><font color="#009900">' newdata(idx:end) '</font></html>'];
        else
          data{p,3} = ['<html><font color="#888888">' newdata '</font></html>'];
        end
      end
    end
    set(hParamTable,'Data',data);
    
  end
  
  hErrorLine = findobj('Tag','errorline');
  if ~isempty(hErrorLine)
    n = min(100,numel(FitData.errorlist));
    set(hErrorLine,'XData',1:n,'YData',log10(FitData.errorlist(end-n+1:end)));
    ax = get(hErrorLine,'Parent');
    axis(ax,'tight');
    drawnow
  end
 
  hObj = findobj('Tag','detachedRMSD');
  if ~isempty(hObj)
      numPlots = FitData.numSpec+1;
      for j=2:2:2*numPlots
          hDetachedErrorPlot = FitData.DetachedRMSD_Fig.Children(j);
          if j < 2*numPlots
            CurrentError = FitData.individualErrors{j/2};
          else
            CurrentError = FitData.errorlist;
          end
          set(hDetachedErrorPlot.Children,'XData',1:n,'YData',log10(CurrentError(end-n+1:end)));
          axis(hDetachedErrorPlot,'tight');
      end
  end
  drawnow

end
%-------------------------------------------------------------------

if (UserCommand==2)
  UserCommand = 0;
  str = bestfitlist(BestSys,Vary);
  disp('--- current best fit parameters -------------')
  fprintf(str);
  disp('---------------------------------------------')
end

out = {rmsd,[],simspec};
varargout = out(1:nargout);
return
%==========================================================================

%==========================================================================
function simSpec = globalfit(Sys,ExpCell,Opt)
numSpectra = ExpCell;
for i = 1:numSpectra
  ExpCell = ExpCell{i};
  simSpec = pepper(Sys,Exp,Opt);  
end
 
return
%==========================================================================

%==========================================================================
% Calculate spin systems with values based on Sys0 (starting points), Vary
% (parameters to vary, and their vary range), and x (current point in vary
% range)
function [Sys,values] = getSystems(Sys0,Vary,x)
global FitData
values = [];
if nargin==3, x = x(:); end
for iSys = 1:numel(Sys0)
  [Fields,Indices,VaryVals] = getParameters(Vary{iSys});
  
  if isempty(VaryVals)
    % no parameters varied in this spin system
    Sys{iSys} = Sys0{iSys};
    continue
  end
  
  thisSys = Sys0{iSys};
  
  pidx = FitData.xidx(iSys):FitData.xidx(iSys+1)-1;
  if (nargin<3)
    Shifts = zeros(numel(VaryVals),1);
  else
    Shifts = x(pidx).*VaryVals(:);
  end
  values_ = [];
  for p = 1:numel(VaryVals)
    f = thisSys.(Fields{p});
    idx = Indices(p,:);
    values_(p) = f(idx(1),idx(2)) + Shifts(p);
    f(idx(1),idx(2)) = values_(p);
    thisSys.(Fields{p}) = f;
  end
  
  values = [values values_];
  Sys{iSys} = thisSys;
  
end

return
%==========================================================================


%==========================================================================
function [parNames,parCenter,parVary] = getParamList(Sys,Vary)
nSystems = numel(Sys);
p = 1;
for s = 1:nSystems
  allFields = fieldnames(Vary{s});
  for iField = 1:numel(allFields)
    fieldname = allFields{iField};
    CenterValue = Sys{s}.(fieldname);
    VaryValue = Vary{s}.(fieldname);
    [idx1,idx2] = find(VaryValue);
    idx = sortrows([idx1(:) idx2(:)]);
    singletonDims = sum(size(CenterValue)==1);
    for iVal = 1:numel(idx1)
      parCenter(p) = CenterValue(idx(iVal,1),idx(iVal,2));
      parVary(p) = VaryValue(idx(iVal,1),idx(iVal,2));
      Indices = idx(iVal,:);
      if singletonDims==1
        parName_ = sprintf('(%d)',max(Indices));
      elseif singletonDims==0
        parName_ = sprintf('(%d,%d)',Indices(1),Indices(2));
      else
        parName_ = '';
      end
      parNames{p} = [fieldname parName_];
      if (nSystems>1), parNames{p} = [char('A'-1+s) '.' parNames{p}]; end
      p = p + 1;
    end
  end
end
return
%==========================================================================


%==========================================================================
function [Fields,Indices,Values] = getParameters(Vary)
Fields = [];
Indices = [];
Values = [];
if isempty(Vary), return; end
allFields = fieldnames(Vary);
p = 1;
for iField = 1:numel(allFields)
  Value = Vary.(allFields{iField});
  [idx1,idx2] = find(Value);
  idx = sortrows([idx1(:) idx2(:)]);
  for i = 1:numel(idx1)
    Fields{p} = allFields{iField};
    Indices(p,:) = [idx(i,1) idx(i,2)];
    Values(p) = Value(idx(i,1),idx(i,2));
    p = p + 1;
  end
end
Values = Values(:);
return
%==========================================================================


%==========================================================================
% Print from Sys values of field elements that are nonzero in Vary.
function [str,Values] = bestfitlist(Sys,Vary)
nSystems = numel(Sys);
str = [];
p = 1;
for s=1:nSystems
  AllFields = fieldnames(Vary{s});
  if numel(AllFields)==0, continue; end
  for iField = 1:numel(AllFields)
    fieldname = AllFields{iField};
    FieldValue = Sys{s}.(fieldname);
    [idx1,idx2] = find(Vary{s}.(fieldname));
    idx = sortrows([idx1(:) idx2(:)]);
    singletonDims_ = sum(size(FieldValue)==1);
    for i = numel(idx1):-1:1
      Fields{p} = fieldname;
      Indices(p,:) = idx(i,:);
      singletonDims(p) = singletonDims_;
      Values(p) = FieldValue(idx(i,1),idx(i,2));
      Component(p) = s;
      p = p + 1;
    end
  end
end
nParameters = p-1;

for p = 1:nParameters
  if (nSystems>1) && ((p==1) || Component(p-1)~=Component(p))
    str = [str sprintf('component %s\n',char('A'-1+Component(p)))];
  end
  if singletonDims(p)==2
    str = [str sprintf('     %7s:   %0.7g\n',Fields{p},Values(p))];
  elseif singletonDims(p)==1
    str = [str sprintf('  %7s(%d):   %0.7g\n',Fields{p},max(Indices(p,:)),Values(p))];
  else
    str = [str sprintf('%7s(%d,%d):   %0.7g\n',Fields{p},Indices(p,1),Indices(p,2),Values(p))];
  end
end

if (nargout==0), fprintf(str); end
return
%==========================================================================


%==========================================================================
function residuals = getResiduals(A,B,mode)
residuals = A - B;
idxNaN = isnan(A) | isnan(B);
residuals(idxNaN) = 0; % ignore NaNs in either A or B
switch mode
  case 1 % fcn
    % nothing to do
  case 2 % int
    residuals = cumsum(residuals);
  case 3 % iint
    residuals = cumsum(cumsum(residuals));
  case 4 % fft
    residuals = abs(fft(residuals));
  case 5 % diff
    residuals = deriv(residuals);
end
return
%==========================================================================


%==========================================================================
function iterationprint(str)
hLogLine = findobj('Tag','logLine');
if isempty(hLogLine)
  disp(str);
else
  set(hLogLine,'String',str);
end
%==========================================================================


%==========================================================================
function str = striphtml(str)
html = 0;
for k = 1:numel(str)
  if ~html
    rmv(k) = false;
    if str(k)=='<', html = 1; rmv(k) = true; end
  else
    rmv(k) = true;
    if str(k)=='>', html = 0; end
  end
end
str(rmv) = [];
return
%==========================================================================


%==========================================================================
function plotFittingResult
if (FitOpt.Plot) && (UserCommand~=99)
  close(hFig); clf
  
  subplot(4,1,4);
  contour(FrequencyAxis,FrequencyAxis,ExpSpec);
  contour(FrequencyAxis,FrequencyAxis,BestSpec);
  h = legend('best fit - data');
  legend boxoff
  set(h,'FontSize',8);
  axis tight
  height4 = get(gca,'Position'); height4 = height4(4);
  
  subplot(4,1,[1 2 3]);
%   h = plot(x,ExpSpec,'k.-',x,BestSpec,'g');
    h = pcolor(x,x,ExpSpec);shading interp;
    pcolor(x,x,BestSpec,'g');

  set(h(2),'Color',[0 0.8 0]);
  h = legend('data','best fit');
  legend boxoff
  set(h,'FontSize',8);
  axis tight
  yl = ylim;
  yl = yl+[-1 1]*diff(yl)*FitOpt.PlotStretchFactor;
  ylim(yl);
  height123 = get(gca,'Position'); height123 = height123(4);
  
  subplot(4,1,4);
  yl = ylim;
  ylim(mean(yl)+[-1 1]*diff(yl)*height123/height4/2);
  
end
return
%==========================================================================


%==========================================================================
function deleteSetButtonCallback(object,src,event)
global FitData
h = findobj('Tag','SetListBox');
idx = get(h,'Value');
str = get(h,'String');
nSets = numel(str);
if (nSets>0)
  ID = sscanf(str{idx},'%d');
  for k = numel(FitData.FitSets):-1:1
    if (FitData.FitSets(k).ID==ID)
      FitData.FitSets(k) = [];
    end
  end
  if idx>length(FitData.FitSets), idx = length(FitData.FitSets); end
  if (idx==0), idx = 1; end
  set(h,'Value',idx);
  refreshFitsetList(0);
end

str = get(h,'String');
if isempty(str)
  set(findobj('Tag','deleteSetButton'),'Enable','off');
  set(findobj('Tag','exportSetButton'),'Enable','off');
  set(findobj('Tag','sortIDSetButton'),'Enable','off');
  set(findobj('Tag','sortRMSDSetButton'),'Enable','off');
end
return
%==========================================================================


%==========================================================================
function deleteSetListKeyPressFcn(object,event)
if strcmp(event.Key,'delete')
  deleteSetButtonCallback(object,gco,event);
  displayFitSet
end
return
%==========================================================================


%==========================================================================
function setListCallback(object,src,event)
  displayFitSet
return
%==========================================================================

%==========================================================================
function displayFitSet

global FitData FitOpts


FitData.DisplayingFitSetSpec = true;


h = findobj('Tag','SetListBox');
idx = get(h,'Value');
str = get(h,'String');
if ~isempty(str)
  ID = sscanf(str{idx},'%d');

  idx = 0;
  for k=1:numel(FitData.FitSets)
    if FitData.FitSets(k).ID==ID, idx = k; break; end
  end
  
  if (idx>0)
    fitset = FitData.FitSets(idx);
    
    h = getParameterTableHandle;
    data = get(h,'data');
    values = fitset.bestvalues;
    for p = 1:numel(values)
      data{p,3} = sprintf('%0.6g',values(p));
    end
    set(h,'Data',data);
    
    CurrentFitSpec = fitset.fitSpec{FitData.CurrentSpectrumDisplay};
    CurrentFitSpec = abs(CurrentFitSpec);
    h = findobj('Tag','bestsimdata');
    h2 = findobj('Tag','currsimdata');
    colormap(h.Parent,(FitData.CustomColormap))
    switch FitOpts.GraphicalSettings.FitSpectraTypeString
      case 'colormap'
        set(h,'CData',-abs(CurrentFitSpec));
        set(h2,'CData',NaN*abs(CurrentFitSpec));
      case 'contour'
        set(h,'ZData',-abs(CurrentFitSpec));
        set(h2,'ZData',NaN*abs(CurrentFitSpec));
    end
    h = findobj('Tag','bestsimdata_projection1');
    h2 = findobj('Tag','currsimdata_projection1');
    Inset = max(CurrentFitSpec(round(length(CurrentFitSpec)/2,0):end,:),[],1);
    set(h,'YData',Inset);
    set(h2,'YData',NaN*Inset);
    h = findobj('Tag','bestsimdata_projection2');
    h2 = findobj('Tag','currsimdata_projection2');
    Inset = max(CurrentFitSpec,[],2);
    set(h,'XData',Inset);
    set(h2,'XData',NaN*Inset);
    drawnow
  end
else
  h = findobj('Tag','bestsimdata');
  switch FitOpts.GraphicalSettings.FitSpectraTypeString
    case 'colormap'
      set(h,'CData',get(h,'CData')*NaN);
    case 'contour'
    set(h,'ZData',get(h,'ZData')*NaN);
  end
  h = findobj('Tag','bestsimdata_projection1');
  set(h,'YData',get(h,'YData')*NaN);
  h = findobj('Tag','bestsimdata_projection2');
  set(h,'YData',get(h,'XData')*NaN);

  drawnow;
end

return
%==========================================================================


%==========================================================================
function exportSetButtonCallback(object,src,event)
global FitData
h = findobj('Tag','SetListBox');
v = get(h,'Value');
s = get(h,'String');
ID = sscanf(s{v},'%d');
for k=1:numel(FitData.FitSets), if FitData.FitSets(k).ID==ID, break; end, end
varname = sprintf('fit%d',ID);
fitSet = rmfield(FitData.FitSets(k),'bestx');
fitSet = rmfield(fitSet,'Target');

assignin('base',varname,fitSet);
fprintf('Fit set %d assigned to variable ''%s''.\n',ID,varname);
evalin('base',varname);
return
%==========================================================================


%==========================================================================
function systemButtonCallback(object,src,event)
global FitData

%Reset the local Sys and Vary variables
clear Sys Vary
while true
  
  %Get the current spin system definition from the Hyscorean preferences
  DefaultInput = getpref('hyscorean','defaultsystemEasyspin');
  
  %And prompt the spin system definition window for the user to edit
  SpinSystemInput = inputdlg_mod('Input','Spin System & Variables', [20 80],{DefaultInput});
  
  %If canceled just return without any changes
  if isempty(SpinSystemInput) 
    return
  end
  
  %Get the user edited string and store as new preference
  FitData.SpinSystemInput = SpinSystemInput{1};
  DefaultInput = SpinSystemInput{1};
  setpref('hyscorean','defaultsystemEasyspin',DefaultInput)
  
  %Remove comments on the input
  Size = size(SpinSystemInput{1},1);
  for i=1:Size
    if SpinSystemInput{1}(i,1) == '%'
      SpinSystemInput{1}(i,:) = ' ';
    end
  end
  StringForEval = SpinSystemInput{1};
  
  %Compile the user input
  try
    for i=1:size(StringForEval,1)
      eval(StringForEval(i,:));
    end
    CompilerFailed = false;
  catch CompilerError
    CompilerFailed = true;
  end
  
  %If some MATLAB-based error occurs during compilation catch it display it to the user and repeat input
  if CompilerFailed
    w = errordlg(sprintf('Error found in the definition: \n\n %s \n\n Please check your input. ',CompilerError.message),'Error','modal');
    waitfor(w)
  else
    
    %If no MATLAB-based error is found check for other error sources
    
    %If Vary not defined then warn and repeat input
    if ~exist('Vary','var')
      w  = errordlg('The Vary structure needs to have at least one valid field.','Vary structure not found','modal');
      waitfor(w)
    end
    %If Sys not defined then warn and repeat input
    if ~exist('Sys','var')
      w  = errordlg('The Sys structure needs to be defined properly.','Sys structure not found','modal');
      waitfor(w)
    end
    
    %Check for EasySpin-based errors but validatespinsys is a private EasySpin function
    CurrentPath = cd;
    EasySpinPath = which('easyspin');
    EasySpinPath = EasySpinPath(1:end-10);
    %Change to the location of the file to be able to call it... 
    cd(fullfile(EasySpinPath,'private'))
    [~,SpinSystemError] = validatespinsys(Sys);
    %... and return to the location without the user noticing it
    cd(CurrentPath)
    
    %If some error was found, notify the user and repeat input
    if ~isempty(SpinSystemError)
      w  = errordlg(sprintf('EasySpin has found an error in the definition: \n\n %s \n\n Please check your input.',SpinSystemError),'Spin system error','modal');
      waitfor(w)
    end
    
  end

  %If no error of any type are found then break the loop and continue
  if exist('Sys','var') && exist('Vary','var') && isempty(SpinSystemError) && ~CompilerFailed
    break
  end  
  %Otherwise repeat endlessly until the user gives a correct input
end

%Check if any changes/additions to the Opt structure are requested
if exist('Opt','var')
  if ~iscell(Opt)
    %Get Opt fields
    OptFields = fields(Opt);
    for i=1:length(OptFields)
      for j=1:length(FitData.SimOpt)
        %Set these fields on the existing SimOpt structure
        FitData.SimOpt{j} = setfield(FitData.SimOpt{j},OptFields{i},getfield(Opt,OptFields{i}));
      end
    end
  end
else
  FitData.SimOpt = FitData.DefaultSimOpt;
end
%Check if any changes/additions to the Exp structure are requested
if exist('Exp','var')
  if ~iscell(Exp)
    %Get Opt fields
    ExpFields = fields(Exp);
    for i=1:length(ExpFields)
      for j=1:length(FitData.Exp)
        %Set these fields on the existing Exp structure
        FitData.Exp{j} = setfield(FitData.Exp{j},ExpFields{i},getfield(Exp,ExpFields{i}));
      end
    end
  end
else
  FitData.Exp = FitData.DefaultExp;
end

%Update the system name given in blue next to the button
set(findobj('Tag','SystemName'),'string',Sys.Nucs)

%Now go through the same protols as in the startup
if ~iscell(Sys)
Sys = {Sys};
end
if ~iscell(Vary)
Vary = {Vary};
end
nSystems = numel(Sys);
for s = 1:nSystems
  if ~isfield(Sys{s},'weight'), Sys{s}.weight = 1; end
end
FitData.nSystems = nSystems;
FitData.Sys0 = Sys;

% Make sure user provides one Vary structure for each Sys
if numel(Vary)~=nSystems
  error(sprintf('%d spin systems given, but %d vary structure.\n Give %d vary structures.',nSystems,numel(Vary),nSystems));
end
for iSys = 1:nSystems
  if ~isstruct(Vary{iSys}), Vary{iSys} = struct; end
end

% Make sure users are fitting with the logarithm of Diff or tcorr
for s = 1:nSystems
  if (isfield(Vary{s},'tcorr') && ~isfield(Vary{s},'logtcorr')) ||...
      (~isfield(Sys{s},'logtcorr') && isfield(Vary{s},'logtcorr'))
    error('For least-squares fitting, use logtcorr instead of tcorr both in Sys and Vary.');
  end
  if (isfield(Vary{s},'Diff') && ~isfield(Vary{s},'logDiff')) ||...
      (~isfield(Sys{s},'logDiff') && isfield(Vary{s},'logDiff'))
    error('For least-squares fitting, use logDiff instead of Diff both in Sys and Vary.');
  end
end
  
% Assert consistency between System0 and Vary structures
for s = 1:nSystems
  Fields = fieldnames(Vary{s});
  for k = 1:numel(Fields)
    if ~isfield(Sys{s},Fields{k})
      error(sprintf('Field %s is given in Vary, but not in Sys0. Remove from Vary or add to Sys0.',Fields{k}));
    elseif numel(Sys{s}.(Fields{k})) < numel(Vary{s}.(Fields{k}))
      error(['Field ' Fields{k} ' has more elements in Vary than in Sys0.']);
    end
  end
  clear Fields
end

% count parameters and save indices into parameter vector for each system
for iSys = 1:nSystems
  [dummy,dummy,v_] = getParameters(Vary{iSys});
  VaryVals(iSys) = numel(v_);
end
FitData.xidx = cumsum([1 VaryVals]);
FitData.nParameters = sum(VaryVals);

if (FitData.nParameters==0)
%   error('No variable parameters to fit.');
end
FitData.inactiveParams = logical(zeros(1,FitData.nParameters));

FitData.Vary = Vary;

[FitData.parNames,FitData.CenterVals,FitData.VaryVals] = getParamList(Sys,Vary);
    for p = 1:numel(FitData.parNames)
    data{p,1} = true;
    data{p,2} = FitData.parNames{p};
    data{p,3} = '-';
    data{p,4} = '-';
    data{p,5} = sprintf('%0.6g',FitData.CenterVals(p));
    data{p,6} = sprintf('%0.6g',FitData.VaryVals(p));
    end

h = getParameterTableHandle;
set(h,'Data',data);

return
%==========================================================================

%==========================================================================
function selectAllButtonCallback(object,src,event)
h = getParameterTableHandle;
d = get(h,'Data');
d(:,1) = {true};
set(h,'Data',d);
return
%==========================================================================


%==========================================================================
function selectNoneButtonCallback(object,src,event)
h = getParameterTableHandle;
d = get(h,'Data');
d(:,1) = {false};
set(h,'Data',d);
return
%==========================================================================

%==========================================================================
function ChangeCurrentDisplay(hObject,event)

global FitData FitOpts

%Get the current field selected in the UI element
FitData.CurrentSpectrumDisplay = get(hObject,'value');

%Construct the frequency axis again for the experimental spectrum
TimeStep = FitData.SimOpt{FitData.CurrentSpectrumDisplay}.TimeStepFactor*FitData.Exp{FitData.CurrentSpectrumDisplay}.dt;
FrequencyAxis = linspace(-1/(2*TimeStep),1/(2*TimeStep),length(FitData.ExpSpec{FitData.CurrentSpectrumDisplay}));

%Get the corresponding experimental spectrum
CurrentExpSpec = FitData.ExpSpecScaled{FitData.CurrentSpectrumDisplay};
CurrentExpSpec = CurrentExpSpec/max(max(CurrentExpSpec));

%Update the experimental main display plot
switch FitOpts.GraphicalSettings.ExperimentalSpectrumTypeString
  case 'colormap'
    set(findobj('Tag','expdata'),'XData',FrequencyAxis,'YData',FrequencyAxis,'CData',-CurrentExpSpec);
  case 'contour'
    set(findobj('Tag','expdata'),'XData',FrequencyAxis,'YData',FrequencyAxis,'ZData',CurrentExpSpec);
end

% Update the inset experimental plots
Inset = max(CurrentExpSpec(:,round(length(CurrentExpSpec)/2,0):end),[],2);
set(findobj('Tag','expdata_projection1'),'XData',FrequencyAxis,'YData',Inset);
Inset = max(CurrentExpSpec,[],2);
set(findobj('Tag','expdata_projection2'),'YData',FrequencyAxis,'XData',Inset);

%Update fit plots only if one fit has been run at least
if isfield(FitData,'bestspec')
  
%Construct the frequency axis again for the fit spectra
TimeStep = FitData.Exp{FitData.CurrentSpectrumDisplay}.dt;
FrequencyAxis = linspace(-1/(2*TimeStep),1/(2*TimeStep),length(FitData.ExpSpec{FitData.CurrentSpectrumDisplay}));
  
CurrentBestSpec = abs(FitData.bestspec{FitData.CurrentSpectrumDisplay});

%If the current spectrum is not from a saved parameter set then show the current
if ~FitData.DisplayingFitSetSpec
  
  if FitOpts.MethodID >= 7
    
    %Get the manual fit or ORCA fit saved in the currentFitSpec variable
    CurrentFitSpec = FitData.CurrentSimSpec{FitData.CurrentSpectrumDisplay};
    CurrentFitSpec = abs(CurrentFitSpec);
    %Get handle to plot
    h = findobj('Tag','currsimdata');
    if FitOpts.MethodID==7
      %If MANUAL FITTED spectrum
      switch FitOpts.GraphicalSettings.FitSpectraTypeString
        case 'colormap'
          set(h,'XData',FrequencyAxis,'YData',FrequencyAxis,'CData',(CurrentFitSpec)/max(max((CurrentFitSpec))));
        case 'contour'
          set(h,'XData',FrequencyAxis,'YData',FrequencyAxis,'ZData',(CurrentFitSpec)/max(max((CurrentFitSpec))));
      end
    else
      %If ORCA SIMULATED spectrum
      switch FitOpts.GraphicalSettings.FitSpectraTypeString
        case 'colormap'
          set(h,'XData',FrequencyAxis,'YData',FrequencyAxis,'CData',-(CurrentFitSpec)/max(max((CurrentFitSpec))));
        case 'contour'
          set(h,'XData',FrequencyAxis,'YData',FrequencyAxis,'ZData',-(CurrentFitSpec)/max(max((CurrentFitSpec))));
      end
    end
    
    %Update the inset plots
    h = findobj('Tag','currsimdata_projection1');
    Inset = max(CurrentFitSpec(round(length(CurrentFitSpec)/2,0):end,:),[],1);
    set(h,'YData',Inset);
    h = findobj('Tag','currsimdata_projection2');
    Inset = max(CurrentFitSpec,[],2);
    set(h,'XData',Inset);
    
  else
    %If AUTOMATIC FITTING spectrum
    switch FitOpts.GraphicalSettings.FitSpectraTypeString
      case 'colormap'
        set(findobj('Tag','bestsimdata'),'XData',FrequencyAxis,'YData',FrequencyAxis,'CData',-CurrentBestSpec);
      case 'contour'
        set(findobj('Tag','bestsimdata'),'XData',FrequencyAxis,'YData',FrequencyAxis,'ZData',-abs(CurrentBestSpec));
    end
    
    %Update the inset plots
    Inset = max(CurrentBestSpec(:,round(length(CurrentBestSpec)/2,0):end),[],2);
    set(findobj('Tag','bestsimdata_projection1'),'XData',FrequencyAxis,'YData',Inset);
    Inset = max(CurrentBestSpec,[],2);
    set(findobj('Tag','bestsimdata_projection2'),'YData',FrequencyAxis,'XData',Inset);
    
  end
  
else
  
  h = findobj('Tag','SetListBox');
  idx = get(h,'Value');
  fitset = FitData.FitSets(idx);
  
  h = getParameterTableHandle;
  data = get(h,'data');
  values = fitset.bestvalues;
  for p = 1:numel(values)
    data{p,3} = sprintf('%0.6g',values(p));
  end
  set(h,'Data',data);
  CurrentFitSpec = abs(fitset.fitSpec{FitData.CurrentSpectrumDisplay});
  h = findobj('Tag','bestsimdata');
  h2 = findobj('Tag','currsimdata');
  %Set the bestsim to the current fit set and set the currsim invisible
  switch FitOpts.GraphicalSettings.FitSpectraTypeString
    case 'colormap'
      set(h,'CData',-CurrentFitSpec/max(max(CurrentFitSpec)));
      set(h2,'CData',NaN*CurrentFitSpec/max(max(CurrentFitSpec)));
    case 'contour'
      set(h,'ZData',-CurrentFitSpec/max(max(CurrentFitSpec)));
      set(h2,'ZData',NaN*CurrentFitSpec/max(max(CurrentFitSpec)));
  end
  h = findobj('Tag','bestsimdata_projection1');
  h2 = findobj('Tag','currsimdata_projection1');
  Inset = max(CurrentFitSpec(round(length(CurrentFitSpec)/2,0):end,:),[],1);
  %   Inset = abs(Inset - Inset(end));
  set(h,'YData',Inset);
  set(h2,'YData',NaN*Inset);
  h = findobj('Tag','bestsimdata_projection2');
  h2 = findobj('Tag','currsimdata_projection2');
  Inset = max(CurrentFitSpec,[],2);
  %   Inset = abs(Inset - Inset(end));
  set(h,'XData',Inset);
  set(h2,'XData',NaN*Inset);
  drawnow
end
end

return
%==========================================================================

%==========================================================================
function selectInvButtonCallback(object,src,event)
h = getParameterTableHandle;
d = get(h,'Data');
for k=1:size(d,1)
  d{k,1} = ~d{k,1};
end
set(h,'Data',d);
return
%==========================================================================


%==========================================================================
function sortIDSetButtonCallback(object,src,event)
global FitData
for k=1:numel(FitData.FitSets)
  ID(k) = FitData.FitSets(k).ID;
end
[ID,idx] = sort(ID);
FitData.FitSets = FitData.FitSets(idx);
refreshFitsetList(0);
return
%==========================================================================


%==========================================================================
function sortRMSDSetButtonCallback(object,src,event)
global FitData
rmsd = [FitData.FitSets.rmsd];
[rmsd,idx] = sort(rmsd);
FitData.FitSets = FitData.FitSets(idx);
refreshFitsetList(0);
return
%==========================================================================


%==========================================================================
function refreshFitsetList(idx)
global FitData FitOpts
h = findobj('Tag','SetListBox');
nSets = numel(FitData.FitSets);
for k=1:nSets
  s{k} = sprintf('%d. rmsd %g (%s)',...
    FitData.FitSets(k).ID,FitData.FitSets(k).rmsd,FitData.FitSets(k).Target);
end
if nSets==0, s = {}; end
set(h,'String',s);
if (idx>0), set(h,'Value',idx); end
if (idx==-1), set(h,'Value',numel(s)); end

if nSets>0, state = 'on'; else state = 'off'; end
set(findobj('Tag','deleteSetButton'),'Enable',state);
set(findobj('Tag','exportSetButton'),'Enable',state);
set(findobj('Tag','reportButton'),'Enable',state);
set(findobj('Tag','sortIDSetButton'),'Enable',state);
set(findobj('Tag','sortRMSDSetButton'),'Enable',state);

displayFitSet;
return
%==========================================================================


%==========================================================================
function saveFitsetCallback(object,src,event)
global FitData
FitData.lastSetID = FitData.lastSetID+1;
FitData.currFitSet.ID = FitData.lastSetID;
if ~isfield(FitData,'FitSets') || isempty(FitData.FitSets)
  FitData.FitSets(1) = FitData.currFitSet;
else
  FitData.FitSets(end+1) = FitData.currFitSet;
end
refreshFitsetList(-1);
return
%==========================================================================


%==========================================================================
function hTable = getParameterTableHandle
% uitable was introduced in R2008a, undocumented in
% R2007b, where property 'Tag' doesn't work

%h = findobj('Tag','ParameterTable'); % works only for R2008a and later

% for R2007b compatibility
hFig = findobj('Tag','esfitFigure_hyscorean');
if ishandle(hFig)
  hTable = findobj(hFig,'Type','uitable');
else
  hTable = [];
end
return
%==========================================================================


%==========================================================================
function speedUpCallback(object,src,event)

global FitData

%Get number of cores requested by the user
FitData.CurrentCoreUsage = get(object,'value');

%Check if too many are requested and inform the user
if FitData.CurrentCoreUsage > length(FitData.Exp)
  w  = warndlg(sprintf('%i cores accesed. This exceeds the number of spectra loaded (%i). No speed-up will be obtained from exceeding %i cores. Consider reducing the number of cores.' ...
    ,FitData.CurrentCoreUsage,length(FitData.Exp),length(FitData.Exp)),'Warning','modal');
  waitfor(w)
end

%Deletes the current parpool without creating one
delete(gcp('nocreate'))

%If more than one core is requested then open the parpool informing the user 
if FitData.CurrentCoreUsage>1
  w  = warndlg('Connecting workers to parallel computing pool...','Warning','modal');
  delete(w.Children(1))
  FitData.PoolData =  parpool(FitData.CurrentCoreUsage);
  close(w);
end

return
%==========================================================================

%==========================================================================
function tableEditCallback(hTable,callbackData)
global FitData

% Get row and column index of edited table cell
ridx = callbackData.Indices(1);
cidx = callbackData.Indices(2);

% Return unless it's the center or the vary column
if cidx==5
  struName = 'Sys0';
elseif cidx==6
  struName = 'Vary';
else
  return
end

% Get parameter string (e.g. 'g(1)', or 'B.g(2)' for more than 1 system)
% and determine system index
parName = hTable.Data{ridx,2};
if FitData.nSystems>1
  iSys = parName(1)-64; % 'A' -> 1, 'B' -> 2, etc
  parName = parName(3:end);
else
  iSys = 1;
end

% Revert edit if user-entered data does not cleanly convert to a scalar,
% assert non-negativity for vary range
numval = str2num(callbackData.EditData);
if numel(numval)~=1 || ((numval<0) && (cidx==6))
  hTable.Data{ridx,cidx} = callbackData.PreviousData;
  return
end

% Modify appropriate field in FitData.Sys0 or FitData.Vary
stru = sprintf('FitData.%s{%d}.%s',struName,iSys,parName);
try
  eval([stru '=' callbackData.EditData ';']);
catch
  hTable.Data{ridx,cidx} = callbackData.PreviousData;
end

return
%==========================================================================

%==========================================================================
function DetachRMSD(object,src,event)

global FitData

%Get number of spectra being fitted
numSpec = FitData.numSpec;

%Find the figure, close it and reopen it
FitData.DetachedRMSD_Fig = findobj('Tag','detachedRMSD');
if isempty(FitData.DetachedRMSD_Fig)
  FitData.DetachedRMSD_Fig = figure('Tag','detachedRMSD','WindowStyle','normal');
else
  figure(FitData.DetachedRMSD_Fig);
  clf(FitData.DetachedRMSD_Fig);
end

%Set figure properties
set(FitData.DetachedRMSD_Fig,'WindowStyle','normal','DockControls','off','MenuBar','none');
set(FitData.DetachedRMSD_Fig,'Resize','off');
set(FitData.DetachedRMSD_Fig,'Name','Hyscorean: EasySpin - Individual Fit RMSD','NumberTitle','off');

%Additional plot required for the total RMSD display
numPlots = numSpec+1;

%Generate tags for the plot tags
Tags{1} = 'DetachedRmsdPlot_Total';
for i=2:numPlots
  Tags{i} = sprintf('DetachedRmsdPlot%i', i);
end

%Set the figure size in accordance to how many plots are required 
sz = [600 numPlots*200]; % figure size
screensize = get(0,'ScreenSize');
xpos = ceil((screensize(3)-sz(1))/2); % center the figure on the screen horizontally
ypos = ceil((screensize(4)-sz(2))/2); % center the figure on the screen vertically
set(FitData.DetachedRMSD_Fig,'Position',[xpos ypos sz(1) sz(2)])

%Construct the axis and plots
cmp = lines(numPlots);
for i=1:numPlots
  %Generate axis fitting in the figure
  AxisWidth = 0.85/numPlots;
  YPositionAxis = 1 - i*AxisWidth - i*0.04;
  hAx = axes('Parent',FitData.DetachedRMSD_Fig,'Units','normalized','Position',[0.05 YPositionAxis 0.85 AxisWidth]);
  %Generate a dummy plot with desired properties
  h = plot(hAx,1,NaN,'.');
  set(hAx,'Tag',Tags{i})
  set(h,'Tag',Tags{i},'MarkerSize',10,'Color',cmp(i,:));
  set(gca,'FontSize',9,'YScale','lin','XTick',[],'YAxisLoc','right','Layer','top');
  ylabel(gca,'log10(RMSD)')
  if i>1
    LegendTag = sprintf('RMSD @ %.2f mT', FitData.Exp{i-1}.Field);
  else
    LegendTag = 'Total RMSD';
  end
  legend(hAx,LegendTag)
end
%The data is introduced durin the execution of the assess function

return
%==========================================================================


%==========================================================================
function StartpointNamesCallback(object,src,event)

global FitOpts
FitOpts.StartID = get(object,'value'); 

return
%==========================================================================
%==========================================================================
function reportButtonCallback(object,src,event)

global FitData FitOpts

if getpref('hyscorean','reportlicense')

%Store all information contained in global variables into report data 
ReportData.FitData = FitData; 
ReportData.FitOpts = FitOpts; 

%Get the current date
Date = date;
formatOut = 'yyyymmdd';
Date = datestr(Date,formatOut);

%Ask the user via the OS where to put the report
[ReportData.SaveName,ReportData.SavePath] = uiputfile('*.*','Save fitting report as');

%If directory does not exist just create it
if ~exist(ReportData.SavePath,'dir')
  mkdir(ReportData.SavePath)
end
  
%Get Hyscorean path
HyscoreanPath = which('Hyscorean');
HyscoreanPath = HyscoreanPath(1:end-11);
ReportData.FittingReport_logo_Path = [HyscoreanPath 'bin\FitReport_logo.png'];

%Check if it is cell
if ~iscell(ReportData.FitData.SimOpt{1}.FileNames)
  ReportData.FitData.SimOpt{1}.FileNames = {ReportData.FitData.SimOpt{1}.FileNames};
end

%If there are too many files just print the number of them
if length(ReportData.FitData.SimOpt{1}.FileNames) > 15
  ReportData.FitData.SimOpt{1}.FileNames = {sprintf('%i files',length(ReportData.FitData.SimOpt{1}.FileNames{1}))};
end

%Send structure to workspace
assignin('base', 'ReportData', ReportData);

%Generate report
 report Hyscorean_Fitting_report -fpdf ;

else
  %Report generator is not available without the license
  warning('MATLAB report generator license missing. Report cannot be generated.')
end

return
%==========================================================================

%==========================================================================
function zoomInButtonCallback(object,src,event)
zoom on 
return

function zoomOutButtonCallback(object,src,event)
global FitData
zoom off
HObj = findobj('Tag','bestsimdata');
set(HObj.Parent,'XLim',[-FitData.SimOpt{FitData.CurrentSpectrumDisplay}.FreqLim FitData.SimOpt{FitData.CurrentSpectrumDisplay }.FreqLim]);
set(HObj.Parent,'YLim',[0 FitData.SimOpt{FitData.CurrentSpectrumDisplay}.FreqLim]);

return
%==========================================================================


%==========================================================================
function detachButtonCallback(object,src,event)

%Search for figure, close it or\ans open it
hFig = findobj('Tag','esfitDetached');
if isempty(hFig)
  hFig = figure('Tag','esfitDetached','WindowStyle','normal');
else
  figure(hFig);
  clf(hFig);
end

%Set figure properties exactly as in the GUI
sz = [1080 600]; % figure size
screensize = get(0,'ScreenSize');
xpos = ceil((screensize(3)-sz(1))/2); % center the figure on the screen horizontally
ypos = ceil((screensize(4)-sz(2))/2); % center the figure on the screen vertically
set(hFig,'position',[xpos, ypos, sz(1), sz(2)],'units','pixels');

%Get handles of the plots parents
experimentalHandle = findobj('Tag','expdata');
experimentalHandle = experimentalHandle.Parent;
mainHandle = findobj('Tag','bestsimdata');
mainHandle = mainHandle.Parent;
inset1Handle = findobj('Tag','expdata_projection1');
inset1Handle = inset1Handle.Parent;
inset2Handle = findobj('Tag','bestsimdata_projection2');
inset2Handle = inset2Handle.Parent;

%Copy all objects into the new figure
copyobj(mainHandle,hFig);
copyobj(experimentalHandle,hFig);
copyobj(inset1Handle,hFig);
copyobj(inset2Handle,hFig);

%Remove the tags of all children in the new figure to avoid tag clashes
%with the GUI axis
for i=1:length(hFig.Children)
  for j=1:length(hFig.Children(i).Children)
    hFig.Children(i).Children(j).Tag = '';
     hFig.Children(i).Tag = '';
  end
end

%Remove the figure number and give it a title
set(hFig,'NumberTitle','off','Name','Hyscorean: HYSCORE Fit');

return
%==========================================================================

%==========================================================================
function ProductRuleCallback(object,src,event)

global FitData

%Warn that using product rule with less than three nuclei can slow down 
if get(object,'value')
  numNuclei =  length(strfind(FitData.Sys0{1}.Nucs,','))+1;
  if numNuclei < 3
    w  = warndlg(sprintf('Product rule usage activated. However only %i nuclei are defined in the system. This may result in a slow down of the simulation.' ...
      ,numNuclei),'Warning','modal');
    waitfor(w)
  end
end
for i=1:length(FitData.SimOpt)
  if get(object,'value')
    FitData.SimOpt{i}.ProductRule = 1;
  else
    FitData.SimOpt{i}.ProductRule = 0;
  end
end

return
%==========================================================================

%==========================================================================
function loadORCACallback(object,src,event)
 
global FitData FitOpts 

%Ask the user to select the ORCA file
[Filename,Path] = uigetfile('.prop','Load ORCA data');

%Convert the ORCA output to EasySpin structure
Sys1 = orca2easyspin(fullfile(Path,Filename));

%Identify all the different atoms in the ORCA output and make a list
Commas = strfind(Sys1.Nucs,',');
Nucs = Sys1.Nucs;
Pos1 = 1;
List = cell(length(Commas)+1,1);
Nuclei = cell(length(Commas)+1,1);
for i=1:length(Commas)
  Isotopes = isotopologues(Nucs(Pos1:Commas(i)-1));
  Nuclei{i} = Isotopes(1).Nucs;
  if isempty(Nuclei{i})
    Nuclei{i} = Isotopes(2).Nucs;
  end
  NucleiName =  Nuclei{i};
  NucleiShort = Nucs(Pos1:Commas(i)-1);
  IsotopeNumber = NucleiName(1:strfind(NucleiName,NucleiShort)-1);
  List{i} = sprintf('<HTML>#%i <SUP> %s </SUP> %s </HTML>',i,IsotopeNumber,NucleiShort);
  Pos1 = Commas(i)+1;
end
Isotopes = isotopologues(Nucs(Pos1:end));
Nuclei{i+1} = Isotopes(1).Nucs;
if isempty(Nuclei{i})
  Nuclei{i+1} = Isotopes(2).Nucs;
end
NucleiName =  Nuclei{i+1};
NucleiShort = Nucs(Pos1:end);
IsotopeNumber = NucleiName(1:strfind(NucleiName,NucleiShort)-1);
List{i+1} = sprintf('<HTML>#%i <SUP> %s </SUP> %s </HTML>',i+1,IsotopeNumber,NucleiShort);


%Ask the user to select the desired atoms from the list
[Indexes,Answered] = listdlg('Name',' ','PromptString','Select the nuclei to simulate',...
  'SelectionMode','multiple',...
  'ListString',List);

%Store hte current Sys and Vary structurers into temporary variables
Temp = FitData.Sys0;
Temp2 = FitData.Vary;

if Answered
  try
    %Inform the user that the simulation is running via message window
    f = msgbox('Simulating ORCA system...');
    delete(f.Children(1))
    drawnow
    
    %Get the atoms selected by the user from the list
    N = Indexes;
    Sys = Sys1;
    Sys.xyz = Sys1.xyz(N,:);
    string = sprintf('%s',Nuclei{Indexes(1)});
    if length(Indexes)>1
      for i=2:length(Indexes)
        string = sprintf('%s,%s',string,Nuclei{Indexes(i)});
      end
    end
    
    %Construct the reduced spin system to be simulated
    Sys.Nucs = string;
    Sys.A = Sys1.A(N,:);
    Sys.AFrame = Sys1.AFrame(N,:);
    Sys.Q = Sys1.Q(N,:);
    Sys.QFrame = Sys1.QFrame(N,:);
    
    %Setup the simulation options required for asses to run
    switch FitOpts.Startpoint
      case 1 % center of range
        startx = zeros(FitData.nParameters,1);
      case 2 % random
        startx = 2*rand(FitData.nParameters,1) - 1;
        startx(FitData.inactiveParams) = 0;
      case 3 % selected fit set
        h = findobj('Tag','SetListBox');
        s = get(h,'String');
        if ~isempty(s)
          s = s{get(h,'Value')};
          ID = sscanf(s,'%d');
          startx = FitData.FitSets(ID).bestx;
        else
          startx = zeros(FitData.nParameters,1);
        end
    end
    FitData.startx = startx;
    x0_ = startx;
    x0_(FitData.inactiveParams) = [];
    ORCASys = Sys;
    if strcmp(FitOpts.Scaling, 'none')
      fitspc = FitData.ExpSpec;
    else
      fitspc = FitData.ExpSpecScaled;
    end
    
    FitData.Sys0 = {ORCASys};
    %Set a dummy for vary for asses to work
    Dummy.A = 1;
    FitData.Vary = {Dummy};
    %Set a new method ID for asses to recognize and use another color
    FitOpts.MethodID = 8;
    
    %Launch the assess function (i.e. simulation)
    funArgs = {fitspc,FitData,FitOpts};
    assess(0,funArgs{:});
    
    %Once simulation finished restore the Sys and Vary as they were before
    FitData.Sys0 = Temp;
    FitData.Vary = Temp2;
    
    close(f)
    
  catch Error
    
    close(f)
    %If crashes restore the Sys and Vary as they were before
    FitData.Sys0 = Temp;
    FitData.Vary = Temp2;
    %And warn the user about the error
    f = errordlg(sprintf('Simulaton failed due to errors: \n\n %s \n\n ',getReport(Error,'extended','hyperlinks','off')),'Error','modal');
    
  end
  
end

return
%==========================================================================

%==========================================================================
function SetGraphicsSettings(object,src,event)

global FitOpts FitData

warning('off','all')

%Launch the graphical settings GUI with the current settings and retrieve them back
FitOpts.GraphicalSettings = Hyscorean_esfit_GraphicalSettings(FitOpts.GraphicalSettings);

%Translate the UI element values to evaluation strings
switch FitOpts.GraphicalSettings.ExperimentalSpectrumType
  case 1
    FitOpts.GraphicalSettings.ExperimentalSpectrumTypeString = 'contour';
  case 2
    FitOpts.GraphicalSettings.ExperimentalSpectrumTypeString = 'colormap';
  case 3
    FitOpts.GraphicalSettings.ExperimentalSpectrumTypeString = 'filledcontour';
end
switch FitOpts.GraphicalSettings.FitSpectraType
  case 1
    FitOpts.GraphicalSettings.FitSpectraTypeString = 'colormap';
  case 2
    FitOpts.GraphicalSettings.FitSpectraTypeString = 'contour';
  case 3
    FitOpts.GraphicalSettings.FitSpectraTypeString = 'filledcontour';
end

%Since rendering can be slow, inform the user until everything isfinished
f = msgbox('Rendering new graphical settings...');

%Find handle to experimental plot...
h = findobj('Tag','expdata');
%... and get its parent
ParentExp = h.Parent;
%Now get the parent of the fit spectra...
Parent = findobj('Tag','dataaxes');
%.. and the handles of the best and current fit spectra
h3 = Parent.Children(1);
h2 = Parent.Children(2);

%Get the limits informations on the parent as well as the frequency axis
xlims = h.Parent.XLim;
ylims = h.Parent.YLim;
FrequencyAxis = h.XData;
%And set them to the experimental parent 
set(ParentExp,'XLim',xlims,'YLim',ylims);
%Now link the parent axis together again 
linkaxes([ParentExp,Parent])

%Now delete the old experimental plot 
delete(h)

%Reconstruct the new experimental plot with current settings
switch FitOpts.GraphicalSettings.ExperimentalSpectrumTypeString
  case 'colormap'
    h = pcolor(ParentExp,FrequencyAxis,FrequencyAxis,-abs(FitData.ExpSpecScaled{FitData.CurrentSpectrumDisplay}));
    shading(ParentExp,'interp')
    %Manipulate the two linked axis so that fit is over experimental
    uistack(Parent,'top')
    Parent.Visible = 'off';
    ParentExp.Visible = 'on';
  case 'contour'
    [~,h] = contour(ParentExp,FrequencyAxis,FrequencyAxis,abs(FitData.ExpSpecScaled{FitData.CurrentSpectrumDisplay}),...
      'LevelList',linspace(0,1,FitOpts.GraphicalSettings.ContourLevels),...
      'LineWidth',FitOpts.GraphicalSettings.LineWidth);
    %Manipulate the two linked axis so that fit is over experimental
    uistack(ParentExp,'top')
    ParentExp.Visible = 'off';
    Parent.Visible = 'on';
end
%Give the new plot the old tag to find it later again
set(h,'Tag','expdata');

%Get the spectrum currently plotted as best fit
if isprop(h3,'CData')
  ColorData = h3.CData;
else
  ColorData = h3.ZData;
end
%Delete the old plot
delete(h3)

%Reconstruct the new best fit plot with current settings
switch   FitOpts.GraphicalSettings.FitSpectraTypeString
  case 'contour'
    [~,h3] = contour(Parent,FrequencyAxis,FrequencyAxis,ColorData,...
      FitOpts.GraphicalSettings.ContourLevels,...
      'LineWidth',FitOpts.GraphicalSettings.LineWidth);
  case 'colormap'
    [h3] = pcolor(Parent,FrequencyAxis,FrequencyAxis,ColorData);
  case 'filledcontour'
    [~,h3] = contourf(Parent,FrequencyAxis,FrequencyAxis,ColorData,'LineStyle','none',...
      'LevelList',linspace(-1,0,FitOpts.GraphicalSettings.ContourLevels));
end
%Set the limits and tag of the new plot as in the old one
set(Parent,'XLim',xlims,'YLim',ylims);
set(h3,'Tag','bestsimdata');
shading(Parent,'interp')

%Get the spectrum currently plotted as current fit
if isprop(h2,'CData')
  ColorData = h2.CData;
else
  ColorData = h2.ZData;
end
%Delete the old plot
delete(h2)

%Reconstruct the new current fit plot with current settings
switch   FitOpts.GraphicalSettings.FitSpectraTypeString
  case 'contour'
    [~,h2] = contour(Parent,FrequencyAxis,FrequencyAxis,ColorData,...
      FitOpts.GraphicalSettings.ContourLevels,...
      'LineWidth',FitOpts.GraphicalSettings.LineWidth);
  case 'colormap'
    [h2] = pcolor(Parent,FrequencyAxis,FrequencyAxis,ColorData);
  case 'filledcontour'
    [~,h2] = contourf(Parent,FrequencyAxis,FrequencyAxis,ColorData,'LineStyle','none',...
      'LevelList',linspace(0,1,FitOpts.GraphicalSettings.ContourLevels));
end
%Give the new plot its old tag
set(h2,'Tag','currsimdata');
shading(Parent,'interp')

%Warnings can now be enabled again
warning('on','all')

%Force the rendering of the new plots before the function finishes
drawnow

%Waits until the rendering is finished and then closes the information window
close(f)

return
%==========================================================================
