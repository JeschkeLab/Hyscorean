function [Data] = correctBackground(Data,options)
% Background correction of 2D-time datasets from TRIER experiments
% -----------INPUT------------------------------------------------
%       Data              Structure containing all relevant variables 
%           .TimeAxis1    
%             --> Time axis 1 provided by integrateEcho.m
%           .TimeAxis2    
%             --> Time axis 2 provided by integrateEcho.m
%           .Integral     
%             --> Integral provided by integrateEcho.m
%
%        options          Structure containing the different parameters
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
% TrierAnalysis, L. Fabregas, 2017

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
if ~isfield(options,'BackgroundMethod1')
  options.BackgroundMethod1 = 3;
end
if ~isfield(options,'BackgroundFractalDimension1')
  options.BackgroundMethod1 = 1;
end
if ~isfield(options,'BackgroundPolynomOrder1')
  options.BackgroundPolynomOrder2 = 1;
end
%Set defaults for 2nd background correction when not provided
if ~isfield(options,'BackgroundMethod2')
  options.BackgroundMethod1 = 3;
end
if ~isfield(options,'BackgroundFractalDimension2')
  options.BackgroundMethod1 = 1;
end
if ~isfield(options,'BackgroundPolynomOrder2')
  options.BackgroundPolynomOrder2 = 1;
end
if ~isfield(options,'DisplayCorrected')
  options.DisplayCorrected = false;
end
%Set defaults for Savitzky-Golay filter
if ~isfield(options,'SavitzkyOrder')
  options.SavitzkyOrder = 3;
end
if ~isfield(options,'SavitzkyFrameLength')
  options.SavitzkyFrameLength = 11;
end

options.BackgroundCorrection2D = false;

% Deactivate warnings to avoid the fitting functions to throw too many outputs
warning ('off','all');

% Sometimes something may be messed up during mountdata.m check that dimensions are consisten
if ~(size(Data.Integral,1) == length(Data.TimeAxis1) && size(Data.Integral,2) == length(Data.TimeAxis2))
    Data.Integral  = Data.Integral';
end


%Determine zero-times and adjust time axis
[ZeroTime1,ZeroTime2,Integral,~,~,~] = phase_zt(Data.TimeAxis1,Data.TimeAxis2,Data.Integral);
ZeroTimeAxis1 = Data.TimeAxis1 - ZeroTime1;
ZeroTimeAxis2 = Data.TimeAxis2 - ZeroTime2;
NonCorrectedIntegral = Integral();


TimeIndex1 = 1;
TimeIndex2 = 1;
Data.CorrectedTimeAxis2 = ZeroTimeAxis2(TimeIndex2:end);
Data.CorrectedTimeAxis1 = ZeroTimeAxis1(TimeIndex1:end);


%Option to show output of fitting functions
options.verbose = 1;

% 2D-Background correction not-working
if options.BackgroundCorrection2D
  
  TimeIndex1 = find(ZeroTimeAxis1 == 0);
  TimeIndex2 = find(ZeroTimeAxis2 == 0);
  options.zt1= TimeIndex1;
  options.zt2= TimeIndex2;
  BackgroundNew = fitBackground2D_new(Integral,options);
  Integral = Integral(TimeIndex1:end,TimeIndex2:end);
  Integral = real(Integral)-BackgroundNew;

else
  
  % Inverted Background correction (1st - t2 , 2nd - t1)
  if options.InvertCorrection
    % 1st Background correction
    Parameters.Dimension = 2;
    Parameters.BackgroundModel = options.BackgroundMethod1;
    Parameters.homdim = options.BackgroundFractalDimension1;
    Parameters.PolynomialOrder = options.BackgroundPolynomOrder1;
    [~,StartIndex1] = get_t_bckg_start(Data.CorrectedTimeAxis2,sum(Integral,1),Parameters);
    Parameters.start = StartIndex1;
    
    Background1 = fitBackground2D(Integral,Parameters);
    Integral = real(Integral) - Background1;
  
    % 2nd Background correction
    Parameters.Dimension = 1;
    Parameters.BackgroundModel = options.BackgroundMethod2;
    Parameters.homdim = options.BackgroundFractalDimension2;
    Parameters.PolynomialOrder = options.BackgroundPolynomOrder2;
    [~,StartIndex2] = get_t_bckg_start(Data.CorrectedTimeAxis1,sum(Integral,2),Parameters);
    
    Parameters.start = StartIndex2;
    Background2 = fitBackground2D(Integral,Parameters);
    Integral = real(Integral) - Background2;
    
  else  % Standard Background correction (1st - t1 , 2nd - t2)
    
    % 1st Background correction
    Parameters.Dimension = 1;
    Parameters.BackgroundModel = options.BackgroundMethod1;
    Parameters.homdim = options.BackgroundFractalDimension1;
    Parameters.PolynomialOrder = options.BackgroundPolynomOrder1;    
    [~,StartIndex1] = get_t_bckg_start(Data.CorrectedTimeAxis1,sum(Integral,2),Parameters);
    Parameters.start = StartIndex1;
      
    Background1 = fitBackground2D(Integral,Parameters);
    Integral = real(Integral) - Background1;
  
    % 2nd Background correction
    Parameters.Dimension = 2;
    Parameters.BackgroundModel = options.BackgroundMethod2;
    Parameters.homdim = options.BackgroundFractalDimension2;
    Parameters.PolynomialOrder = options.BackgroundPolynomOrder2;
    [~,StartIndex2] = get_t_bckg_start(Data.CorrectedTimeAxis2',sum(Integral,1),Parameters);
    Parameters.start = StartIndex2;
    
    Background2 = fitBackground2D(real(Integral),Parameters);
    Integral = real(Integral)-Background2;
    
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
Integral = Integral(TimeIndex1:end,TimeIndex2:end);
Data.NonCorrectedIntegral = NonCorrectedIntegral(TimeIndex1:end,TimeIndex2:end);
Data.Background1 = Background1;
Data.Background2 = Background2;
Data.BackgroundStartIndex1 = StartIndex1;
Data.BackgroundStartIndex2 = StartIndex2;
Data.BackgroundCorrected = real(Integral);
Data.CorrectedTimeAxis2 = ZeroTimeAxis2(TimeIndex2:end);
Data.CorrectedTimeAxis1 = ZeroTimeAxis1(TimeIndex1:end);

% Savitzky-Golay filtering of background-corrected integral
try
  if options.SavitzkyGolayFiltering
    Integral =  sgolayfilt(Integral,options.SavitzkyOrder,options.SavitzkyFrameLength,[],1); % along dimension 1
    Integral =  sgolayfilt(Integral,options.SavitzkyOrder,options.SavitzkyFrameLength,[],2); % along dimension 2
  end
catch
%If options.SavitzkyGolayFiltering is not given just continue
end

%Store final integral (a.k.a the signal) into data structure
Integral = Integral/max(max(Integral));

Data.PreProcessedSignal = Integral';

% If requested, display background corrected 2D-trace
if options.DisplayCorrected
  figure(3000)
  set(gcf,'NumberTitle','off','Name','TrierAnalysis: Background corrected','Units','pixels');   
  
  surf(Data.CorrectedTimeAxis2,Data.CorrectedTimeAxis1,Integral)
  colormap default
  shading flat
  xlabel('t_1'),ylabel('t_2')
  az = 135; el = 40.4000; 
  view(az,el),drawnow;
end



%Reactivate warnings
warning ('on','all');
