function MountedData = mountHYSCOREdata(FileNames,handles)

%Check extension of file to know how to mount data
[~,~,FileExtension] = fileparts(FileNames{1});

set(handles.ProcessingInfo, 'String', 'Status: Preparing data...'); drawnow;
warning('off','all')

switch FileExtension
  
  %------------------------------------------------------------------------
  % BRUKER Spectrometer Files
  %------------------------------------------------------------------------
  case {'.DSC','.DTA'}
    
    %Load file with eprload from Easyspin
    File = FileNames{1};
    [~,~,BrukerParameters] = eprload(File);
    ExtractedData = eprload(File);
    
    %Get dimensionality
    [Dimension1,Dimension2] = size(ExtractedData);
    
    %Get time-resolution
    TimeStep1 = BrukerParameters.XWID/(BrukerParameters.XPTS - 1)/1000;
    TimeStep2 = BrukerParameters.YWID/(BrukerParameters.YPTS - 1)/1000;
    
    %Check for folded tau-dimensions
    if Dimension1 ~= Dimension2
      %Make default that second dimension is the largest
      if Dimension1 > Dimension2
        ExtractedData = ExtractedData';
        [Dimension1,Dimension2] = size(ExtractedData);
      end
      FoldingFactor = Dimension2/Dimension1;
      TauSignals = zeros(FoldingFactor,Dimension1,Dimension1);
      StartPosition = 1;
      %Extract the additional dimension from the folded dimension
      for FoldingIndex=1:FoldingFactor
        TauSignals(FoldingIndex,:,:)=ExtractedData(1:end,StartPosition:Dimension2/FoldingFactor*FoldingIndex);
        StartPosition = Dimension2/FoldingFactor*FoldingIndex + 1;
      end
    else
      TauSignals(1,:,:) = ExtractedData;
    end
    
    %Extract the PulseSpel code for the experiment
    PulseSpelProgram = BrukerParameters.PlsSPELPrgTxt;
    %Identify the tau definition lines
    TauDefinitionIndexes = strfind(PulseSpelProgram,'d1=');
    %Extract the tau-values
    for i=1:length(TauDefinitionIndexes)
      Shift = 3;
      while ~isspace(PulseSpelProgram(TauDefinitionIndexes(i) + Shift))
        TauString(Shift - 2) =  PulseSpelProgram(TauDefinitionIndexes(i) + Shift);
        Shift = Shift + 1;
      end
      TauValues(i)  = str2double(TauString);
    end
    TimeAxis1 = linspace(0,TimeStep1*size(TauSignals,2),size(TauSignals,2));
    TimeAxis2 = linspace(0,TimeStep2*size(TauSignals,2),size(TauSignals,2));

    %Construct output structure
    MountedData.TauSignals = TauSignals;
    MountedData.TauValues = TauValues;
    MountedData.BrukerParameters = BrukerParameters;
    MountedData.TimeStep1 = TimeStep1;
    MountedData.TimeStep2 = TimeStep2;
    MountedData.TimeAxis1 = TimeAxis1;
    MountedData.TimeAxis2 = TimeAxis2;
    MountedData.NUSflag = false;
    MountedData.isNotIntegrated  = false;


  %------------------------------------------------------------------------
  % AWG Spectrometer Files
  %------------------------------------------------------------------------
  case '.mat'
    NFiles = length(str2double(FileNames));
    %Preallocate first time axis vector
    TimeAxis1 = zeros(NFiles,1);
    % Preprocess measurement data of first file with uwb_eval and set up data container
    Measurement = load(FileNames{1});    
    %Check if data is NUS and proceed
    if isfield(Measurement.hyscore,'NUS')
        isNUS = true;
    else
      isNUS = false;
      MountedData.NUSflag = isNUS;
    end
    
    if isNUS
      %Extract time axes directly from the sampling grid
      TimeAxis1 = Measurement.hyscore.NUS.t1Timings;
      TimeAxis2 = Measurement.hyscore.NUS.t2Timings;
      SamplingGrid = Measurement.hyscore.NUS.SamplingGrid;
    else
    %Get timings and set up t_2 axis and zero time
    TimeAxis2 = (Measurement.hyscore.parvars{2}.axis - Measurement.hyscore.deadtime); % adjust t_2 axis to zero time
    TimeAxis1(1) = Measurement.hyscore.events{3}.t - Measurement.hyscore.hyscore_t1.strt(1);  % first element of t1 vector from file name
    end
    
    % Evaluate data from the AWG spectrometer
    options.plot = 0;
    OutputUWB = uwb_eval(FileNames{1},options);
    
    [Dimension1, Dimension2] = size(OutputUWB.dta_avg);
    % Get time axis of echo
    EchoAxis = OutputUWB.t_ax;
    %Get first tau value
    TauValues = zeros(1,NFiles);
    TauValues(1) = Measurement.hyscore.tau;

    set(handles.ProcessingInfo, 'String','Status: Checking data...'); drawnow;
    % Check consistency of echo dimension and get tau values 
    for iFile = 2:NFiles
      OutputUWB = uwb_eval(FileNames{iFile},options);
      if Dimension1 > size(OutputUWB.dta_avg,1) 
        %If a file should contain fewer points, reduce dimension 
        Dimension1 = size(OutputUWB.dta_avg,1);
      end
     %Get current tau value 
     TauValues(iFile) = OutputUWB.exp.tau;
    end
    %Get unique tau values and folding factor
    UniqueTaus = unique(TauValues);
    FoldingFactor = numel(UniqueTaus);

    OutputUWB = uwb_eval(FileNames{1},options);
    %Adjust to consistent dimensions
    OutputUWB.dta_avg = OutputUWB.dta_avg(1:Dimension1,:);
    if isNUS
    AverageEchos = zeros(Dimension1, size(SamplingGrid,2), size(SamplingGrid,1)*FoldingFactor);
    else
    AverageEchos = zeros(Dimension1, Dimension2, NFiles);
    end
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
      FilteredEchos = filtfilt(NumeratorCoefficients,DenominatorCoefficients,OutputUWB.dta_avg);
    else
      FilteredEchos = OutputUWB.dta_avg;
    end
      if isNUS
        currentT2SamplingScheme = SamplingGrid(:,1)==1;
        AverageEchos(:,currentT2SamplingScheme,1) = FilteredEchos;
      else
        AverageEchos(:,:,1) = FilteredEchos;
      end

    % Repeat for remaining files
    for iFile = 2:NFiles
      set(handles.ProcessingInfo, 'String', sprintf('Status: Mounting file %i/%i',iFile,NFiles)); drawnow;
      OutputUWB = uwb_eval(FileNames{iFile},options);
      %Get general AWG paremeters
      AWG_Parameters = OutputUWB.exp;
      OutputUWB.dta_avg = OutputUWB.dta_avg(1:Dimension1,:);
      % Write traces
      if Filtering
        FilteredEchos = filtfilt(NumeratorCoefficients,DenominatorCoefficients,OutputUWB.dta_avg);
      else
        FilteredEchos = OutputUWB.dta_avg;
      end
      currentT1 = AWG_Parameters.events{3}.t-AWG_Parameters.hyscore_t1.strt(1);
      if isNUS
        TauPosition = find(UniqueTaus == TauValues(iFile));
        GridPosition = find(TimeAxis1==currentT1);
        currentT2SamplingScheme = SamplingGrid(:,GridPosition)==1;
        AverageEchos(:,currentT2SamplingScheme,GridPosition + (TauPosition-1)*size(SamplingGrid,1)) = FilteredEchos;
      else
        AverageEchos(:,:,iFile) = FilteredEchos;
      end
      %If not NUS then keep constructing the t1-axis
      if ~isNUS
      TimeAxis1(iFile) = currentT1;
      end
      %Get tau values
      TauValues(iFile) =  OutputUWB.exp.tau;   % absolute time of first echo
    end   

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
%     options.fignum = 123213123;surfslices(EchoAxis,TimeAxis2,TimeAxis1,AverageEchos,options)

    %Integrate the echos
    options.status = handles.ProcessingInfo;
    [IntegratedData] = integrateEcho(DataForInegration,'gaussian',options);
    
    %Restructure the integrated data by sorting to corresponding taus
    [Dimension1,Dimension2] = size(IntegratedData.Integral);
    %Ensure that folded dimension is the second one
    if Dimension1 > Dimension2
      IntegratedData.Integral = IntegratedData.Integral';
      [Dimension1,~] = size(IntegratedData.Integral);
    end
    TauSignals = zeros(FoldingFactor,Dimension1,Dimension1);

    %Loop through all tau-values found in the data
    if isNUS
      StartPosition = 1;
      %Extract the additional dimensions from the folded dimension
      for FoldingIndex=1:FoldingFactor
        TauSignals(FoldingIndex,:,:)=IntegratedData.Integral(1:end,StartPosition:Dimension2/FoldingFactor*FoldingIndex);
        StartPosition = Dimension2/FoldingFactor*FoldingIndex + 1;
      end    
    else
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
    end
    
    %Mount data structure with integrated signals
    MountedData.TauSignals = TauSignals;
    MountedData.TauValues = unique(TauValues);
    MountedData.AWG_Parameters = AWG_Parameters;
    MountedData.TimeStep1 = DataForInegration.TimeStep1;
    MountedData.TimeStep2 = DataForInegration.TimeStep2;
    MountedData.NUSflag = isNUS;
    MountedData.NUS = AWG_Parameters.NUS;

end


end