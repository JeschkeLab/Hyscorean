function MountedData = mountHYSCOREdata(FileNames)

%Check extension of file to know how to mount data
[~,~,FileExtension] = fileparts(FileNames{1});

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
    
    %Construct output structure
    MountedData.TauSignals = TauSignals;
    MountedData.TauValues = TauValues;
    MountedData.BrukerParameters = BrukerParameters;
    MountedData.TimeStep1 = TimeStep1;
    MountedData.TimeStep2 = TimeStep2;
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
      %If NUS data, then launch appropiate mounter and return to main function
      [MountedData]=mountNUSdata(FileNames,options);
      return
    else
      MountedData.NUSflag = false;
    end
    % Evaluate data from the AWG spectrometer
    options.plot = 0;
    OutputUWB = uwb_eval(FileNames{1},options);
    
    [Dimension1, Dimension2] = size(OutputUWB.dta_avg);
    % Get time axis of echo
    EchoAxis = OutputUWB.t_ax;
    
    % Check consistency of Dimension1  
    for iFile = 2:NFiles
      OutputUWB = uwb_eval(FileNames{iFile},options);
      if Dimension1 > size(OutputUWB.dta_avg,1) 
        %If a file should contain fewer points, reduce dimension 
        Dimension1 = size(OutputUWB.dta_avg,1);
      end
    end
    % Check consistency of Dimension2
    for iFile = 2:NFiles
      OutputUWB = uwb_eval(FileNames{iFile},options);
      if Dimension2 > size(OutputUWB.dta_avg,2) 
        %If a file should contain fewer points, reduce dimension 
        Dimension2 = size(OutputUWB.dta_avg,2);
      end
    end
    OutputUWB = uwb_eval(FileNames{1},options);
    %Adjust to consistent dimensions
    OutputUWB.dta_avg = OutputUWB.dta_avg(1:Dimension1,1:Dimension2);
    AverageEcho = zeros(Dimension1, Dimension2, NFiles);
    EchoAxis = EchoAxis(1:Dimension1);
    
    %Get timings and set up t_2 axis and zero time
    Tau =  Measurement.hyscore.tau;   % absolute time of first echo    
    StartTimeAxis2 = Measurement.hyscore.parvars{2}.strt(1) - Measurement.hyscore.events{3}.t; % absolute time of second echo
    TimeAxis2 = (Measurement.hyscore.parvars{2}.axis - Measurement.hyscore.deadtime); % adjust t_2 axis to zero time
    TimeAxis1(1) = Measurement.hyscore.events{3}.t - Measurement.hyscore.hyscore_t1.strt(1);  % first element of t1 vector from file name
    TauValues(1) = Tau;
    
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
      OutputUWB = uwb_eval(FileNames{iFile},options);
      OutputUWB.dta_avg = OutputUWB.dta_avg(1:Dimension1,1:Dimension2);
      % Write traces
      if Filtering
        AverageEcho(:,:,iFile) = filtfilt(NumeratorCoefficients,DenominatorCoefficients,OutputUWB.dta_avg);
      else
        AverageEcho(:,:,iFile) = OutputUWB.dta_avg;
      end
      
      % Update t1 Time axis
      AWG_Parameters = OutputUWB.exp;
      TimeAxis1(iFile) = AWG_Parameters.events{3}.t - AWG_Parameters.hyscore_t1.strt(1);
      TauValues(iFile) =  AWG_Parameters.tau;   % absolute time of first echo

    end   
    
    % In case something goes wrong and NaNs are formed set them to void
    TimeAxis1(~any(~isnan(TimeAxis1), 1)) = [];
    
    
    %Mount Data structure for integration
    DataForInegration.AverageEcho = AverageEcho;
    DataForInegration.TimeAxis1 = TimeAxis1;
    DataForInegration.TimeAxis2 = TimeAxis2;
    DataForInegration.EchoAxis = EchoAxis;
    DataForInegration.TimeStep1 = (DataForInegration.TimeAxis1(2) - DataForInegration.TimeAxis1(1))/1000;
    DataForInegration.TimeStep2 = (DataForInegration.TimeAxis2(2) - DataForInegration.TimeAxis2(1))/1000;
    DataForInegration.isNotIntegrated  = true;
        options.fignum = 123213123;surfslices(EchoAxis,TimeAxis2,TimeAxis1,AverageEcho,options)

    %Integrate the echos
    [IntegratedData] = integrateEcho(DataForInegration,'gaussian');
    %Restructure the integrated data by sorting to corresponding taus
    [Dimension1,Dimension2] = size(IntegratedData.Integral);
    FoldingFactor = numel(unique(TauValues));
    TauSignals = zeros(FoldingFactor,Dimension1,Dimension2);
    StartPosition = 1;
    for FoldingIndex = 1:FoldingFactor
      TauSignals(FoldingIndex,:,:) = IntegratedData.Integral(:,StartPosition:Dimension2/FoldingFactor*FoldingIndex);
        StartPosition = Dimension2/FoldingFactor*FoldingIndex + 1;
    end
      
    %Mount data structure with integrated signals
    MountedData.TauSignals = IntegratedData.Integral;
    MountedData.TauValues = unique(TauValues);
    MountedData.AWG_Parameters = AWG_Parameters;
    MountedData.TimeStep1 = DataForInegration.TimeStep1;
    MountedData.TimeStep2 = DataForInegration.TimeStep2;
    
end


end