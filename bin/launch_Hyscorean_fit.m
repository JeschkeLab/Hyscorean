function launch_Hyscorean_fit(FileNames,Paths,Input)

if nargin < 3
    Input = [];
end

if nargin < 2
  Paths = {pwd};
end

if ~iscell(Paths)
  Paths = {Paths};
end

if ~iscell(FileNames)
  FileNames = {FileNames};
end

if length(Paths) < length(FileNames)
  for i=2:length(FileNames)
    Paths{i} = Paths{1};
  end
end

if isfield(Input,'Sys')
Sys = Input.Sys;
else
    Sys = [];
end

if isfield(Input,'Vary')
    Vary = Input.Vary;
else
   Vary = []; 
end

numSpec = length(FileNames);

ExpSpectra = cell(numSpec);
Exp = cell(numSpec,1);
Opt = cell(numSpec,1);

for Index = 1:numSpec
  
  load(fullfile(Paths{Index},FileNames{Index}));
  
  ExpSpectra{Index} = abs(DataForFitting.Spectrum);
  Opt{Index}.FileNames = FileNames{Index};
  Opt{Index}.FilePaths = Paths{Index};

  %Fill known experimental parameters
  Exp{Index}.Sequence = 'HYSCORE';
  Exp{Index}.Field = DataForFitting.Field + DataForFitting.FieldOffset;
  Exp{Index}.tau = DataForFitting.TauValues;
  Exp{Index}.dt = DataForFitting.TimeStep1;
  Exp{Index}.nPoints = DataForFitting.nPoints;
  
  %Fill known optional parameters
  Opt{Index}.nKnots = 181;
  Opt{Index}.ZeroFillFactor = DataForFitting.ZeroFillFactor;
  Opt{Index}.FreqLim = DataForFitting.FreqLim;
  Opt{Index}.WindowType = DataForFitting.WindowType;
  if isfield(DataForFitting,'WindowDecay')
    %Compatibility with older versions
    Opt{Index}.WindowDecay1 = DataForFitting.WindowDecay;
    Opt{Index}.WindowDecay2 = DataForFitting.WindowDecay;
  else
    Opt{Index}.WindowDecay1 = DataForFitting.WindowDecay1;
    Opt{Index}.WindowDecay2 = DataForFitting.WindowDecay2;
  end
  Opt{Index}.L2GParameters = DataForFitting.L2GParameters;
  Opt{Index}.Lorentz2GaussCheck = DataForFitting.Lorentz2GaussCheck;
end

  esfit_hyscorean('saffron',ExpSpectra,Sys,Vary,Exp,Opt)
  
end
