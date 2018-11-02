function launch_Hyscorean_fit(FileNames)

if ~iscell(FileNames)
  FileNames = {FileNames};
end

numSpec = length(FileNames);

ExpSpectra = cell(numSpec);
Exp = cell(numSpec,1);
Opt = cell(numSpec,1);

for Index = 1:numSpec
  
  load(FileNames{Index});
  
  ExpSpectra{Index} = abs(DataForFitting.Spectrum);
  
  %Fill known experimental parameters
  Exp{Index}.Sequence = 'HYSCORE';
  Exp{Index}.Field = DataForFitting.Field;
  Exp{Index}.tau = DataForFitting.TauValues;
  Exp{Index}.dt = DataForFitting.TimeStep1;
  Exp{Index}.nPoints = DataForFitting.nPoints;
  
  %Fill known optional parameters
  Opt{Index}.ZeroFillFactor = DataForFitting.ZeroFillFactor;
  Opt{Index}.FreqLim = DataForFitting.FreqLim;
  Opt{Index}.WindowType = DataForFitting.WindowType;
  Opt{Index}.WindowDecay = DataForFitting.WindowDecay;
  Opt{Index}.L2GParameters = DataForFitting.L2GParameters;
  Opt{Index}.Lorentz2GaussCheck = DataForFitting.Lorentz2GaussCheck;
end
  esfit_hyscorean('saffron',ExpSpectra,[],[],Exp,Opt)
end
