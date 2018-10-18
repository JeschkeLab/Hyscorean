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
    if isfield(Measurement.trier,'NUS')
      %If NUS data, then launch appropiate mounter and return to main function
      [MountedData]=mountNUSdata(FileNames,options);
      return
    else
      MountedData.NUSflag = false;
    end
    PulseSequenceInfo = Measurement.hyscore.events;
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
    Tau =  PulseSequenceInfo{2}.t;   % absolute time of first echo    
    StartTimeAxis2 = Tau + Measurement.hyscore.events{3}.t; % absolute time of second echo
    TimeAxis2 = -(Measurement.hyscore.parvars{2}.axis - StartTimeAxis2); % adjust t_2 axis to zero time
    TimeAxis1(1) = PulseSequenceInfo{3}.t - tauAbsolute1;  % first element of t1 vector from file name
    
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
      TimeAxis1(iFile) = Measurement.hyscore.events{3}.t - tauAbsolute1;
    end   
    
    % In case something goes wrong and NaNs are formed set them to void
    TimeAxis1(~any(~isnan(TimeAxis1), 1)) = [];
    
    %Mount Data structure
    MountedData.AverageEcho = AverageEcho;
    MountedData.TimeAxis1 = TimeAxis1;
    MountedData.TimeAxis2 = TimeAxis2;
    MountedData.EchoAxis = EchoAxis;
    MountedData.TimeStep1 = (MountedData.TimeAxis1(2) - MountedData.TimeAxis1(1))/1000;
    MountedData.TimeStep2 = (MountedData.TimeAxis2(2) - MountedData.TimeAxis2(1))/1000;
    MountedData.isNotIntegrated  = true;
end


end