function [Data]=mountNUSdata(FileNames,options)
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

    warning('off','all')
    NFiles = length(str2double(FileNames));  
    % Preprocess measurement data of first file with uwb_eval and set up data container
    Measurement = load(FileNames{1});   
      %Extract time axes directly from the sampling grid
      TimeAxis1 = Measurement.hyscore.NUS.t1Timings;
      TimeAxis2 = Measurement.hyscore.NUS.t2Timings;
      SamplingGrid = Measurement.hyscore.NUS.SamplingGrid;   
    % Evaluate data from the AWG spectrometer
    options.plot = 0;
    OutputUWB = uwb_eval(FileNames{1},options);
    
    [Dimension1, Dimension2] = size(OutputUWB.dta_avg);
    % Get time axis of echo
    EchoAxis = OutputUWB.t_ax;
    
    set(handles.ProcessingInfo, 'String','Status: Checking data...'); drawnow;
    % Check consistency of Dimension1  
    for iFile = 2:NFiles
      OutputUWB = uwb_eval(FileNames{iFile},options);
      if Dimension1 > size(OutputUWB.dta_avg,1) 
        %If a file should contain fewer points, reduce dimension 
        Dimension1 = size(OutputUWB.dta_avg,1);
      end
    end
%     % Check consistency of Dimension2
%     for iFile = 2:NFiles
%       OutputUWB = uwb_eval(FileNames{iFile},options);
%       if Dimension2 > size(OutputUWB.dta_avg,2) 
%         %If a file should contain fewer points, reduce dimension 
%         Dimension2 = size(OutputUWB.dta_avg,2);
%       end
%     end
    AverageEchos = zeros(Dimension1, size(SamplingGrid,2), NFiles);

    OutputUWB = uwb_eval(FileNames{1},options);
    %Adjust to consistent dimensions
    OutputUWB.dta_avg = OutputUWB.dta_avg(1:Dimension1,:);
    currentT2SamplingScheme = SamplingGrid(:,1)==1;
    AverageEchos(:,currentT2SamplingScheme,1) = OutputUWB.dta_avg;
    EchoAxis = EchoAxis(1:Dimension1);
    
    TauValues(1) = Measurement.hyscore.tau;

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
      AverageEchos(:,:,1) = filtfilt(NumeratorCoefficients,DenominatorCoefficients,OutputUWB.dta_avg);
    else
      AverageEchos(:,:,1) = OutputUWB.dta_avg;
    end

    % Repeat for remaining files
    for iFile = 2:NFiles
      set(handles.ProcessingInfo, 'String', sprintf('Status: Mounting file %i/%i',iFile,NFiles)); drawnow;
      OutputUWB = uwb_eval(FileNames{iFile},options);
      %OutputUWB.dta_avg = OutputUWB.dta_avg(1:Dimension1,1:Dimension2);
      % Write traces
      if Filtering
        AverageEchos(:,:,iFile) = filtfilt(NumeratorCoefficients,DenominatorCoefficients,OutputUWB.dta_avg);
      else
        AverageEchos(:,:,iFile) = OutputUWB.dta_avg;
      end
      
      %If not NUS then keep constructing the t1-axis
      if ~isNUS
      TimeAxis1(iFile) = OutputUWB.exp.events{3}.t - OutputUWB.exp.hyscore_t1.strt(1);
      end
      %Get tau values
      TauValues(iFile) =  OutputUWB.exp.tau;   % absolute time of first echo
    end   
    %Get general AWG paremeters
    AWG_Parameters = OutputUWB.exp;
    %In case something goes wrong and NaNs are formed set them to void
    TimeAxis1(~any(~isnan(TimeAxis1), 1)) = [];
    
    %Mount Data structure for integration
    DataForInegration.AverageEcho = AverageEchos;
    DataForInegration.TimeAxis1 = TimeAxis1;
    DataForInegration.TimeAxis2 = TimeAxis2;
    DataForInegration.EchoAxis = EchoAxis;
    DataForInegration.TimeStep1 = (DataForInegration.TimeAxis1(2) - DataForInegration.TimeAxis1(1))/1000;
    DataForInegration.TimeStep2 = (DataForInegration.TimeAxis2(2) - DataForInegration.TimeAxis2(1))/1000;
    DataForInegration.isNotIntegrated  = true;
    %Debugging (to be erased)
    options.fignum = 123213123;surfslices(EchoAxis,TimeAxis2,TimeAxis1,AverageEchos,options)

    %Integrate the echos
    options.status = handles.ProcessingInfo;
    [IntegratedData] = integrateEcho(DataForInegration,'gaussian',options);
    %Restructure the integrated data by sorting to corresponding taus
    [Dimension1,Dimension2] = size(IntegratedData.Integral);
    %Ensure that folded dimension is the second one
    if Dimension1 > Dimension2
      IntegratedData = IntegratedData';
      [Dimension1,~] = size(IntegratedData.Integral);
    end
    %Get unique tau values and folding factor
    UniqueTaus = unique(TauValues);
    FoldingFactor = numel(UniqueTaus);
    TauSignals = zeros(FoldingFactor,Dimension1,Dimension1);

    %Loop through all tau-values found in the data
    for Index = 1:FoldingFactor
      %Get all integrals corresponding to current tau-value
      CurrentTauIntegral = IntegratedData.Integral(:,TauValues == UniqueTaus(Index));
      %Check if the current integral matrix has the expected size 
      if size(CurrentTauIntegral,2) ~= Dimension1
        %If not, tau-value measurement is not consistent with rest
        ZeroFiller = size(squeeze(TauSignals(Index,:,:))) - size(IntegratedData.Integral(:,TauValues == UniqueTaus(Index)));
        %Just append zeroes to the signal to ensure consistency of dimensions
        CurrentTauIntegral(:,end+1:end+ZeroFiller(2)) = 0;
      end
      %Otherwise just save on corresponding matrix
      TauSignals(Index,:,:) = CurrentTauIntegral;
    end
    
    %Mount data structure with integrated signals
    MountedData.TauSignals = TauSignals;
    MountedData.TauValues = unique(TauValues);
    MountedData.AWG_Parameters = AWG_Parameters;
    MountedData.TimeStep1 = DataForInegration.TimeStep1;
    MountedData.TimeStep2 = DataForInegration.TimeStep2;
    MountedData.NUSflag = isNUS;
    
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