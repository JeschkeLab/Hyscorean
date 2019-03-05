function [Data] = correctBackground(Data,options)
%==========================================================================
% Background correction of 2D time-domain signals
%==========================================================================
% This function performs the background correction of two-dimensional
% time-domain signals obtained from any experiment. The correction is
% performed by two sequential one-dimensional background corrections.
%
% (see Hyscorean manual for more information)
%==========================================================================
% If used programaticaly outside of Hyscorean the input variables required
% are the following:
%
%       Data       Structure containing all relevant variables
%           .TimeAxis1
%             --> Time axis 1 provided by integrateEcho.m
%           .TimeAxis2
%             --> Time axis 2 provided by integrateEcho.m
%           .Integral
%             --> Integral provided by integrateEcho.m
%
%        options   Structure containing the different parameters
%
%           .InvertCorrection
%            --> Invert the order in which dimension are corrected (i.e first t2, then t1)
%
%           .BackgroundMethod1 / BackgroundMethod2
%            --> Model to be fitted along the first/second corrected dimension
%                       0  fractal, n variable,  exp(-k*t^(n/3))
%                       1  n-dimensional, n fixed, exp(-k*t^(n/3))
%                       2  three-dimensional, exp(-k*t)
%                       3  polynomial (fitted to logarithm)
%
%           .BackgroundFractalDimension1 / BackgroundFractalDimension1
%            --> Fractal dimension to be employed in model 1 for first/second correction
%
%           .BackgroundFractalDimension1 / BackgroundFractalDimension2
%            --> Fractal dimension to be employed in model 1 for first/second correction
%
%           .BackgroundPolynomOrder1 / BackgroundPolynomOrder2
%            --> Polynomial order to be employed in model 3 for first/second correction
%
%           .SavitzkyGolayFiltering (true/false)
%            --> Employ Savitzky-Golay filter after correction
%
%           .SavitzkyOrder
%            --> Order of the Savitzky-Golay Filter (must be even integer number)
%
%           .SavitzkyFrameLength
%            --> Frame length Savitzky-Golay Filter (must be even integer number larger larger than order)
%
%==========================================================================
%
% Copyright (C) 2019  Luis Fabregas, Hyscorean 2019
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License 3.0 as published by
% the Free Software Foundation.
%==========================================================================

%Error messages for required variables
if ~isfield(Data,'TimeAxis1')
  error('Field TimeAxis1 is not provided in the Data structure')
end
if ~isfield(Data,'TimeAxis2')
  error('Field TimeAxis2 is not provided in the Data structure')
end
if ~isfield(Data,'Integral')
  error('Field Integral is not provided in the Data structure')
end
%Set defaults for 1st background correction when not provided
if ~isfield(options,'InvertCorrection')
  options.InvertCorrection = false;
end
if ~isfield(options,'BackgroundMethod1')
  options.BackgroundMethod1 = 2;
end
if ~isfield(options,'BackgroundFractalDimension1')
  options.BackgroundFractalDimension1 = 1;
end
if ~isfield(options,'BackgroundPolynomOrder1')
  options.BackgroundPolynomOrder1 = 1;
end
%Set defaults for 2nd background correction when not provided
if ~isfield(options,'BackgroundMethod2')
  options.BackgroundMethod2 = 2;
end
if ~isfield(options,'BackgroundFractalDimension2')
  options.BackgroundFractalDimension2 = 1;
end
if ~isfield(options,'BackgroundPolynomOrder2')
  options.BackgroundPolynomOrder2 = 1;
end
if ~isfield(options,'DisplayCorrected')
  options.DisplayCorrected = false;
end
%Set defaults for Savitzky-Golay filter
if ~isfield(options,'SavitzkyGolayFiltering')
  options.SavitzkyGolayFiltering = false;
end
if ~isfield(options,'SavitzkyOrder')
  options.SavitzkyOrder = 3;
end
if ~isfield(options,'SavitzkyFrameLength')
  options.SavitzkyFrameLength = 11;
end
if ~isfield(options,'BackgroundCorrection2D')
  options.BackgroundCorrection2D = false;
end
if ~isfield(options,'AutomaticBackgroundStart')
  options.AutomaticBackgroundStart = false;
end
if ~isfield(options,'ZeroTimeTruncation')
  options.ZeroTimeTruncation = false;
end

%==========================================================================
% Preparations
%==========================================================================

%Check if data is complex
isComplex = ~isreal(Data.Integral);

% Deactivate warnings to avoid the fitting functions to throw too many outputs
warning ('off','all');

% Sometimes something may be messed up during mountdata.m check that dimensions are consisten
if ~(size(Data.Integral,1) == length(Data.TimeAxis1) && size(Data.Integral,2) == length(Data.TimeAxis2))
  Data.Integral  = Data.Integral';
end

%If complex do phase correction by maximizing real component
if isComplex
  RawSignal = correctPhaseEchoes(Data.Integral);
else
  RawSignal = Data.Integral;
end
%Save signal before correction for later display
NonCorrectedIntegral = RawSignal;
Data.CorrectedTimeAxis2 = Data.TimeAxis2;
Data.CorrectedTimeAxis2 = Data.CorrectedTimeAxis2  - min(Data.CorrectedTimeAxis2);
Data.CorrectedTimeAxis1 = Data.TimeAxis1;
Data.CorrectedTimeAxis1 = Data.CorrectedTimeAxis1  - min(Data.CorrectedTimeAxis1);

%Option to show output of fitting functions
options.verbose = 0;

% 2D-Background correction not-working
if options.BackgroundCorrection2D
  options.zt1= 1;
  options.zt2= 1;
  BackgroundNew = fitBackground2D_new(RawSignal,options);
  RawSignal = RawSignal(TimeIndex1:end,TimeIndex2:end);
  RawSignal = (RawSignal)-BackgroundNew;
  
else
  
    if options.InvertCorrection
%==========================================================================
% Inverted Background correction (1st - t2 , 2nd - t1)
%==========================================================================

    % 1st Background correction
    Parameters.Dimension = 2;
    Parameters.BackgroundModel = options.BackgroundMethod1;
     if Parameters.BackgroundModel == 2 || Parameters.BackgroundModel == 3
        Parameters.PolynomialOrder = options.BackgroundPolynomOrder1;
     else
        Parameters.homdim = options.BackgroundFractalDimension1;
    end
    StartIndex1 = options.BackgroundStart1;
    Parameters.start = StartIndex1;
    %If complex then fit real/imaginary separately
    if isComplex
      RealBackground1 = fitBackground2D(real(RawSignal),Parameters);
      RealIntegral = real(RawSignal)-RealBackground1;
      ImagBackground1 = fitBackground2D(imag(RawSignal),Parameters);
      ImagIntegral = imag(RawSignal)-ImagBackground1;
      RawSignal = RealIntegral + 1i*ImagIntegral;
      Background1 = RealBackground1 +  1i*ImagBackground1;
    else
      Background1 = fitBackground2D(RawSignal,Parameters);
      RawSignal = (RawSignal)-Background1;
    end
    
    Data.FirstBackgroundCorrected = real(RawSignal);
    
    
    % 2nd Background correction
    Parameters.Dimension = 1;
    Parameters.BackgroundModel = options.BackgroundMethod2;
     if Parameters.BackgroundModel == 2 || Parameters.BackgroundModel == 3
        Parameters.PolynomialOrder = options.BackgroundPolynomOrder2;
     else
        Parameters.homdim = options.BackgroundFractalDimension2;
    end
    if options.AutomaticBackgroundStart
      [~,StartIndex2] = get_t_bckg_start(Data.CorrectedTimeAxis1,sum(RawSignal,2),Parameters);
    else
      StartIndex2 = options.BackgroundStart2;
    end
    Parameters.start = StartIndex2;
    %If complex then fit real/imaginary separately
    if isComplex
      RealBackground2 = fitBackground2D(real(RawSignal),Parameters);
      RealIntegral = real(RawSignal)-RealBackground2;
      ImagBackground2 = fitBackground2D(imag(RawSignal),Parameters);
      ImagIntegral = imag(RawSignal)-ImagBackground2;
      RawSignal = RealIntegral + 1i*ImagIntegral;
      Background2 = RealBackground2 +  1i*ImagBackground2;
    else
      Background2 = fitBackground2D(RawSignal,Parameters);
      RawSignal = (RawSignal)-Background2;
    end
    
  else
    
%==========================================================================
% Standard Background correction (1st - t1 , 2nd - t2)
%==========================================================================
    
    % 1st Background correction
    Parameters.Dimension = 1;
    Parameters.BackgroundModel = options.BackgroundMethod1;
    if Parameters.BackgroundModel == 2 || Parameters.BackgroundModel == 3
        Parameters.PolynomialOrder = options.BackgroundPolynomOrder1;
     else
        Parameters.homdim = options.BackgroundFractalDimension1;
    end
    if options.AutomaticBackgroundStart
      [~,StartIndex1] = get_t_bckg_start(Data.CorrectedTimeAxis1,sum(RawSignal,2),Parameters);
    else
      StartIndex1 = options.BackgroundStart1;
    end
    Parameters.start = StartIndex1;
    %If complex then fit real/imaginary separately
    if isComplex
      RealBackground1 = fitBackground2D(real(RawSignal),Parameters);
      RealIntegral = real(RawSignal)-RealBackground1;
      ImagBackground1 = fitBackground2D(imag(RawSignal),Parameters);
      ImagIntegral = imag(RawSignal)-ImagBackground1;
      RawSignal = RealIntegral + 1i*ImagIntegral;
      Background1 = RealBackground1 +  1i*ImagBackground1;
    else
      Background1 = fitBackground2D(RawSignal,Parameters);
      RawSignal = (RawSignal)-Background1;
    end
    Data.FirstBackgroundCorrected = RawSignal;
    
    % 2nd Background correction
    Parameters.Dimension = 2;
    Parameters.BackgroundModel = options.BackgroundMethod2;
    if Parameters.BackgroundModel == 2 || Parameters.BackgroundModel == 3
        Parameters.PolynomialOrder = options.BackgroundPolynomOrder2;
     else
        Parameters.homdim = options.BackgroundFractalDimension2;
    end
    if options.AutomaticBackgroundStart
      [~,StartIndex2] = get_t_bckg_start(Data.CorrectedTimeAxis2',sum(RawSignal,1),Parameters);
    else
      StartIndex2 = options.BackgroundStart2;
    end
    Parameters.start = StartIndex2;
    %If complex then fit real/imaginary separately
    if isComplex
      RealBackground2 = fitBackground2D(real(RawSignal),Parameters);
      RealIntegral = real(RawSignal)-RealBackground2;
      ImagBackground2 = fitBackground2D(imag(RawSignal),Parameters);
      ImagIntegral = imag(RawSignal)-ImagBackground2;
      RawSignal = RealIntegral + 1i*ImagIntegral;
      Background2 = RealBackground2 +  1i*ImagBackground2;
    else
      Background2 = fitBackground2D(RawSignal,Parameters);
      RawSignal = (RawSignal)-Background2;
    end
  end
end

% Zero-time truncation of time axis and integral if requested
if options.ZeroTimeTruncation
  TimeIndex1 = find(ZeroTimeAxis1 == 0);
  TimeIndex2 = find(ZeroTimeAxis2 == 0);
else
  TimeIndex1 = 1;
  TimeIndex2 = 1;
end
RawSignal = RawSignal(TimeIndex1:end,TimeIndex2:end);

% Savitzky-Golay filtering of background-corrected integral
if options.SavitzkyGolayFiltering
  RawSignal =  sgolayfilt(RawSignal,options.SavitzkyOrder,options.SavitzkyFrameLength,[],1); % along dimension 1
  RawSignal =  sgolayfilt(RawSignal,options.SavitzkyOrder,options.SavitzkyFrameLength,[],2); % along dimension 2
end

%Normalize the signal
RawSignal = RawSignal/max(max(RawSignal));

%Save everything back to the input structure and return it
Data.NonCorrectedIntegral = NonCorrectedIntegral(TimeIndex1:end,TimeIndex2:end);
Data.Background1 = Background1;
Data.Background2 = Background2;
Data.BackgroundStartIndex1 = StartIndex1;
Data.BackgroundStartIndex2 = StartIndex2;
Data.BackgroundCorrected = RawSignal;
Data.PreProcessedSignal = RawSignal;

%Reactivate warnings
warning ('on','all');

return
