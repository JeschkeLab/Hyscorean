function [Data] = correctBackground_new(Data,options)
%%%%%%%%%%%%%%% For debugging background correction %%%%%%%%%%%%%%%%%%%%%%%

warning ('off','all');

TimeAxis1 = Data.TimeAxis1;
TimeAxis2 = Data.TimeAxis2;
Data.Integral = Data.Integral';
% BackGround Fitting
[ZeroTime1,ZeroTime2,Integral,~,~,~] = phase_zt(TimeAxis1,TimeAxis2,Data.Integral);
% Integral=Integral';
ZeroTimeAxis1 = TimeAxis1 - ZeroTime1;
ZeroTimeAxis2 = TimeAxis2 - ZeroTime2;

figure(90),surf(ZeroTimeAxis1,ZeroTimeAxis2,real(Integral)),shading flat
  az = 67.3000;el = 40.4000;view(az,el)
xlabel('t_1'),ylabel('t_2'),title('Integral before correction')

if options.nDimensional
  options.model = 1;
end

if options.Polynomial
  options.model = 3;
end

options.verbose = 1;

if options.BackgroundCorrection2D == 1
  TimeIndex1 = find(ZeroTimeAxis1 == 0);
  TimeIndex2 = find(ZeroTimeAxis2 == 0);
  
  options.zt1= TimeIndex1;
  options.zt2= TimeIndex2;
    [~,StartIndex1] = get_t_bckg_start(TimeAxis1,sum(Integral,2)',options);
  [~,StartIndex2] = get_t_bckg_start(TimeAxis2,sum(Integral,1)',options);
  options.start1 = StartIndex1;
  options.start2 = StartIndex2;

  [BackgroundNew,Integral] = fit_bckg_2D_new(Integral,options);
  Integral = real(Integral)-BackgroundNew;

  figure(91),surf(real(BackgroundNew)),shading flat
  az = 67.3000;el = 40.4000;view(az,el)
  title('2D-fitted Background')
  
else
  
  
  options.dim = 1;
  [~,StartIndex1] = get_t_bckg_start(TimeAxis1,sum(Integral,2)',options);
  % Inverted Background correction
  if options.InvertCorrection
    options.dim = 2;
    options.verbose = 1;
    [~,StartIndex1] = get_t_bckg_start(TimeAxis2,sum(Integral,1),options);
    options.start = StartIndex1;
    
    Background = fit_bckg_2D(Integral,options);
    Integral = real(Integral) - Background;
    
      figure(92),surf(real(Background)),shading flat
      az = 67.3000;el = 40.4000;view(az,el)
      title('(Inverted) Background along t2')
      
      figure(94),surf(real(Integral)),shading flat
      az = 67.3000;el = 40.4000;view(az,el)
      title('First-Background Correction')
      options.dim = 1;
      
      [~,StartIndex1] = get_t_bckg_start(TimeAxis1,sum(Integral,2),options);
      
      options.start = StartIndex1;
      
      Background = fit_bckg_2D(Integral,options);
      Integral = real(Integral) - Background;
      
      figure(93),surf(real(Background)),shading flat
      az = 67.3000;el = 40.4000;view(az,el)
      title('(Inverted) Background along t1')
      
      figure(95),surf(real(Integral)),shading flat
      az = 67.3000;el = 40.4000;view(az,el)
      title('Second-Background Correction')
      options.dim = 1;
  else
    options.start = StartIndex1;
    
    Background = fit_bckg_2D(Integral,options);
    Integral = real(Integral) - Background;
    
    figure(92),surf(real(Background)),shading flat
    az = 67.3000;el = 40.4000;view(az,el)
    title('Background along t1')
    options.dim = 2;
    figure(94),surf(real(Integral)),shading flat
    az = 67.3000;el = 40.4000;view(az,el)
    title('First-Background Correction')
    options.dim = 1;
    
    [~,StartIndex1] = get_t_bckg_start(TimeAxis2,sum(Integral,1),options);
    options.start = StartIndex1;
    
    Background = fit_bckg_2D(Integral,options);
    Integral = real(Integral) - Background;
    
    figure(93),surf(real(Background)),shading flat
    az = 67.3000;el = 40.4000;view(az,el)
    title('Background along t2')
    figure(95),surf(real(Integral)),shading flat
    az = 67.3000;el = 40.4000;view(az,el)
    title('Second-Background Correction')
    options.dim = 1;
  end
end
% Zero-time truncation
if options.ZeroTimeTruncation
  TimeIndex1 = find(ZeroTimeAxis1 == 0);
  TimeIndex2 = find(ZeroTimeAxis2 == 0);
else
  TimeIndex1 = 1;
  TimeIndex2 = 1;
end

Data.TimeAxis2 = ZeroTimeAxis1(TimeIndex1:end)';
Data.TimeAxis1 = ZeroTimeAxis2(TimeIndex2:end)';


%Truncate integral data
% Integral = Integral(TimeIndex2:end,TimeIndex1:end);
Data.PreProcessedSignal = Integral;


% If requested, display background corrected 2D-trace
if options.DisplayCorrected
  figure('NumberTitle','off','Name','TrierAnalysis: Background corrected','Units','pixels');        
  surf(TimeAxis2,TimeAxis1,Integral)
  xlabel('t_1')
  ylabel('t_2')
  az = 135;
  el = 40.4000; % view angle for 3d plot
  view(az,el),drawnow;
end
