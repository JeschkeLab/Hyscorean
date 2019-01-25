function launch_Hyscorean_fit(FileNames,Paths,InputSystem)
%------------------------------------------------------------------------
% Hyscorean Fitting module external launcher 
%------------------------------------------------------------------------
% This function is responsible of loading the Hyscorean ouput files with the 
% (default) identifier sufix "DataForFitting" and constructing all structures
% required for EasySpin to work. These structures are the Exp and Opt structures
% which are constructed from the experimental parameters and processing
% parameters extracted/employed by Hyscorean. Once all structures are constructed,
% the Hyscorean fitting module is called. The Sys and Vary structures can also
% be given as input via the InputSystem input argument.
% (See the Hyscorean manual for further details) 
%------------------------------------------------------------------------
%
% Copyright (C) 2019  Luis Fabregas, Hyscorean 2019
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License 3.0 as published by
% the Free Software Foundation.
%------------------------------------------------------------------------

%Input arguments checks
if nargin < 3, InputSystem = []; end
if nargin < 2, Paths = {pwd}; end
if (nargin<1) || (nargin>3), error('Wrong number of input arguments.'); end
if (nargout<0), error('No output arguments are returned'); end
if (nargout>0) && isempty(FileNames), error('At least one filename is required.'); end
if ~iscell(Paths),  Paths = {Paths}; end
if ~iscell(FileNames), FileNames = {FileNames}; end

%If just one path is given, set that path to all files
if length(Paths) < length(FileNames) && length(Paths)==1
  for i=2:length(FileNames)
    Paths{i} = Paths{1};
  end
end

%Check if Sys and Vary are already defined by the user
if isfield(InputSystem,'Sys')
  Sys = InputSystem.Sys;
else
  Sys = [];
end
if isfield(InputSystem,'Vary')
  Vary = InputSystem.Vary;
else
  Vary = [];
end

%Get the number of files loaded
numSpec = length(FileNames);

%Construct the EasySpin structure cells according to that number
ExpSpectra = cell(numSpec);
Exp = cell(numSpec,1);
Opt = cell(numSpec,1);
SpectrumDimensions = zeros(numSpec,1);

%Run through each file and construct the corresponding structures
for Index = 1:numSpec
  
  %Load the DataForFitting Hyscorean output files
  load(fullfile(Paths{Index},FileNames{Index}));
  
  %Get the absolute value experimental spectrum
  ExpSpectra{Index} = abs(DataForFitting.Spectrum);
  
  %Store the filename and path for the report generator later
  Opt{Index}.FileNames = FileNames{Index};
  Opt{Index}.FilePaths = Paths{Index};

  %Fill known experimental parameters
  Exp{Index}.Sequence = 'HYSCORE';
  Exp{Index}.Field = DataForFitting.Field + DataForFitting.FieldOffset;
  Exp{Index}.tau = DataForFitting.TauValues;
  Exp{Index}.dt = DataForFitting.TimeStep1;
  Exp{Index}.nPoints = DataForFitting.nPoints;
  %Check for compatibility with older versions
  if isfield(DataForFitting,'ExciteWidth')
    Exp{Index}.ExciteWidth = DataForFitting.ExciteWidth;
  end
  if isfield(DataForFitting,'mwFreq')
    Exp{Index}.mwFreq = DataForFitting.mwFreq;
  end
  %Knots set to this minimum to ensure good fits of highly anysotropic spectra
  Opt{Index}.nKnots = 181;
  
  %Fill known signal processing parameters
  Opt{Index}.ZeroFillFactor = DataForFitting.ZeroFillFactor;
  Opt{Index}.FreqLim = DataForFitting.FreqLim;
  Opt{Index}.WindowType = DataForFitting.WindowType;
  %Check for compatibility with older versions
  if isfield(DataForFitting,'WindowDecay')
    Opt{Index}.WindowDecay1 = DataForFitting.WindowDecay;
    Opt{Index}.WindowDecay2 = DataForFitting.WindowDecay;
  else
    Opt{Index}.WindowDecay1 = DataForFitting.WindowLength1;
    Opt{Index}.WindowDecay2 = DataForFitting.WindowLength2;
  end
    if isfield(DataForFitting,'Symmetrization')
      Opt{Index}.Symmetrization = DataForFitting.Symmetrization;
    else
      Opt{Index}.Symmetrization = 'none';
    end
  Opt{Index}.L2GParameters = DataForFitting.L2GParameters;
  Opt{Index}.Lorentz2GaussCheck = DataForFitting.Lorentz2GaussCheck;
  
  %Check the expected spectral sizes
  SpectrumDimensions(Index) = length(ExpSpectra{Index});

end

%Get the largest spectrum and adjust the other zerofillings to match it
MaxDimension = max(SpectrumDimensions);
for Index = 1:numSpec
  if SpectrumDimensions(Index)<MaxDimension
    Opt{Index}.ZeroFillFactor = MaxDimension/SpectrumDimensions(Index)/Opt{Index}.ZeroFillFactor;
     ZeroFilling = MaxDimension - SpectrumDimensions(Index);
     ZeroFilledSpectrum = zeros(SpectrumDimensions(Index) + ZeroFilling1, SpectrumDimensions(Index) + ZeroFilling2);
     Pos = floor(ZeroFilling/2);
     ZeroFilledSpectrum(Pos:Pos + SpectrumDimensions(Index),Pos:Pos + SpectrumDimensions(Index)) = ExpSpectra{Index};
     ExpSpectra{Index} = ZeroFilledSpectrum;
  end
end

%Launch the Hyscorean fitting module with all loaded spectra
esfit_hyscorean('saffron',ExpSpectra,Sys,Vary,Exp,Opt)

end
