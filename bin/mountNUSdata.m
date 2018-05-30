function [Data]=mountNUSdata(RawData,options)
% Mount Non-uniformly smapled (NUS) data into appropiate structures for further processing.
% -----------INPUT------------------------------------------------
%       options.type        'experimental'    Experimental data
%          -->RawData: cell array containing the full paths to files
%                           'simulation'      Simulated data
%          -->RawData: structure containing the loaded data
%            
% -----------Simulated data------------------------------------------------
% Simulated data from analytical simulation program is directly extracted 
% without further manipulation. Time axes are directly copied.
% -----------Experimental data---------------------------------------------
% Function mounts measured echos contained in different files into a single
% 3D-matrix of dimensions EchoAxis, TimeAxis2 and TimeAxis1. Echos are 
% filtered and averaged prior to storage. All time axes are constructed 
% from the experimental setup parameters.
%
% Luis Fabregas, TrierAnalysis2018 


% Experimental NUS data
%----------------------------------------------------------------------
switch options.type
  case 'experimental'
    
    NFiles = length(str2double(RawData));
    %Preallocate time axis1 vector
    TimeAxis1 = zeros(NFiles,1);
    % Preprocess measurement data of first file with uwb_eval and set up data container
    Measurement = load(RawData{1});
    PulseSequence = Measurement.trier.events;
    % Evaluate data from the AWG spectrometer
    options.plot = 0;
    OutputUWB = uwb_eval(RawData{1},options);
    
    [Dimension1, Dimension2] = size(OutputUWB.dta_avg);
    % Get time axis of echo
    EchoAxis = OutputUWB.t_ax;
    
    % Check consistency of Dimension1  
    for iFile = 2:NFiles
      OutputUWB = uwb_eval(RawData{iFile},options);
      if Dimension1 > size(OutputUWB.dta_avg,1) 
        %If a file should contain fewer points, reduce dimension 
        Dimension1 = size(OutputUWB.dta_avg,1);
      end
    end
    % Check consistency of Dimension2
    for iFile = 2:NFiles
      OutputUWB = uwb_eval(RawData{iFile},options);
      if Dimension2 > size(OutputUWB.dta_avg,2) 
        %If a file should contain fewer points, reduce dimension 
        Dimension2 = size(OutputUWB.dta_avg,2);
      end
    end
    OutputUWB = uwb_eval(RawData{1},options);
    %Adjust to consistent dimensions
    OutputUWB.dta_avg = OutputUWB.dta_avg(1:Dimension1,1:Dimension2);
    AverageEcho = zeros(Dimension1, Dimension2, NFiles);
    EchoAxis = EchoAxis(1:Dimension1);

    
    %Set up filtering
    SamplingRateMHZ = 1/(EchoAxis(2) - EchoAxis(1))*1e3; % sampling rate from time axis
    try
      CutoffFrequencyMHZ = filter_freq;
    catch
      CutoffFrequencyMHZ = SamplingRateMHZ/30; %cutoff frequency
    end
    %Butterworth IIR filter
    FilterCutoffFrequency = CutoffFrequencyMHZ/(SamplingRateMHZ/2);
    FilterOrder = 2;
    [NumeratorCoefficients,DenominatorCoefficients] = butter(FilterOrder,FilterCutoffFrequency);
    
    % write traces of the first file to matrix
    Filtering = true;
    if Filtering
      AverageEcho(:,:,1) = filtfilt(NumeratorCoefficients,DenominatorCoefficients,OutputUWB.dta_avg);
    else
      AverageEcho(:,:,1) = OutputUWB.dta_avg;
    end

    % Repeat for remaining files
    for iFile = 2:NFiles
      
      OutputUWB = uwb_eval(RawData{iFile},options);
      OutputUWB.dta_avg = OutputUWB.dta_avg(1:Dimension1,1:Dimension2);
      % Write traces
      if Filtering
        AverageEcho(:,:,iFile) = filtfilt(NumeratorCoefficients,DenominatorCoefficients,OutputUWB.dta_avg);
      else
        AverageEcho(:,:,iFile) = OutputUWB.dta_avg;
      end
      
      % Update t1 Time axis
      Measurement = load(RawData{iFile});
      TimeAxis1(iFile) = Measurement.trier.events{3}.t - tauAbsolute1;
    end   
    
    % In case something goes wrong and NaNs are formed set them to void
    TimeAxis1(~any(~isnan(TimeAxis1), 1)) = [];
    
    %Mount Data structure
    Data.AverageEcho = AverageEcho;
    Data.TimeAxis1 = TimeAxis1;
    Data.TimeAxis2 = TimeAxis2;
    Data.EchoAxis = EchoAxis;
    Data.TimeStep1 = (Data.TimeAxis1(2) - Data.TimeAxis1(1))/1000;
    Data.TimeStep2 = (Data.TimeAxis2(2) - Data.TimeAxis2(1))/1000;
    disp('Data mounted')
    
    % If requested, display all echos
    if options.DisplayEchos
      figure(4000)
      set(gcf,'NumberTitle','off','Name','TrierAnalysis: Echo traces','Units','pixels');
                options.type = 'abs';
      options.ylabel=('t_{echo} [ns]');
      options.xlabel=('t_2 [ns]');
      surfslices(EchoAxis,TimeAxis2,TimeAxis1,AverageEcho,options)
%       colormap jet
      assignin('base', 'AverageEcho2', AverageEcho);
      assignin('base', 'EchoAxis2', EchoAxis);

    end

% Simulated NUS data
%----------------------------------------------------------------------    
  case 'simulation'
    %Directly mount Data structure
    Data.NUSflag = true;
    Data.PreProcessedSignal = RawData.Signal;
    Data.SamplingGrid = RawData.SamplingMatrix;
    Data.TimeAxis1 = RawData.t1;
    Data.TimeAxis2 = RawData.t2;
    Data.TimeStep1 = Data.TimeAxis1(2) - Data.TimeAxis1(1);
    Data.TimeStep2 = Data.TimeAxis2(2) - Data.TimeAxis2(1);
end