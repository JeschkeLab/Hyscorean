function MountedData = mountHYSCOREdata(FileNames,handles)
%==========================================================================
% Hyscorean Mounter
%==========================================================================
% This function takes different data file extensions and converts their
% data into the format that will be used by Hyscorean further on.
%
% (see Hyscorean manual for further information)
%==========================================================================
%
% Copyright (C) 2019  Luis Fabregas, Hyscorean 2018-2019
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License 3.0 as published by
% the Free Software Foundation.
%==========================================================================

%Check extension of file to know how to mount data
[~,~,FileExtension] = fileparts(FileNames{1});

set(handles.ProcessingInfo, 'String', 'Status: Preparing data...'); drawnow;
warning('off','all')

switch FileExtension
    
    %------------------------------------------------------------------------
    % BRUKER Spectrometer BES3T Files
    %------------------------------------------------------------------------
    case {'.DSC','.DTA'}
        
        %Prepare containers to temporarily allocate the data of the individual files
        TauValuesVector = [];
        FirstTauValuesVector = [];
        TauSignalsVector = [];
        TimeStep1control = [];
        TimeStep2control = [];
        
        for fileIdx = 1:length(FileNames)
            
            %Load file with eprload from Easyspin
            File = FileNames{fileIdx};
            
            %Get file extension of loaded file and corresponding complementary
            [Path,Name,FileExtension] = fileparts(File);
            FullBaseName = fullfile(Path,Name);
            if strcmp(FileExtension,'.DSC')
                ComplementaryFileExtension = '.DTA';
            else
                ComplementaryFileExtension = '.DSC';
            end
            %Check that the complementary BES3T file is on the same folder
            if ~exist([FullBaseName ComplementaryFileExtension],'file')
                error('Error: Complementary %s file not found. Make sure it is on the same folder as the %s file.',ComplementaryFileExtension,FileExtension)
            end
            
            %Check if easyspin installed. If not use local eprload function copy
            if getpref('hyscorean','easyspin_installed')
                [~,~,BrukerParameters] = eprload(File);
                ExtractedData = eprload(File);
            else
                [~,~,BrukerParameters] = eprload_hyscorean(File);
                ExtractedData = eprload_hyscorean(File);
            end
            
            if isvector(ExtractedData)
                
                % Non-uniform sampled data
                %--------------------------------------------------------------------
                NUSflag = true;
                
                %Check that the additional .XGF file is on the same folder
                if ~exist([FullBaseName '.XGF'],'file')
                    error(sprtinf('Error: Complementary .XGF file not found. Make sure it is on the same folder as the %s file.',FileExtension))
                end
                
                %Check if easyspin installed. If not use local eprload function copy
                if getpref('hyscorean','easyspin_installed')
                    [Abscissa,Ordinate,BrukerParameters] = eprload(File);
                else
                    [Abscissa,Ordinate,BrukerParameters] = eprload_hyscorean(File);
                end
                %Decode the t1 and t2 timings from abscissa
                t2Timings = floor(Abscissa);
                t1Timings = round(10000*(Abscissa - t2Timings));
                
                %Get unique t1 and t2 timings
                t1Unique = unique(t1Timings);
                t2Unique = unique(t2Timings);
                
                %Get effective dwell time up to 1ns resolution
                DwellTime1 = min(round(diff(t1Unique)));
                DwellTime2 = min(round(diff(t2Unique)));
                %         EffectiveDwellTime = min(DwellTime1,DwellTime2);
                
                %Get grid dimensions from maximal timing
                MaximalTiming1 = max(round(t1Unique));
                MaximalTiming2 = max(round(t2Unique));
                Dimension1 = MaximalTiming1/DwellTime1;
                Dimension2 = MaximalTiming2/DwellTime2;
                
                %Construct NUS grid from timings
                Pos1 = 1 + t1Timings/DwellTime1;
                Pos2 = 1 + t2Timings/DwellTime2;
                NUSgrid = zeros(Dimension1,Dimension2);
                for i=1:length(t1Timings)
                    NUSgrid(Pos1(i),Pos2(i)) = 1;
                end
                SamplingDensity = length(find(NUSgrid==1))/numel(NUSgrid);
                %Get tau-values for this measurement
                CommentVar = BrukerParameters.CMNT;
                TauDefinition = CommentVar(findstr(CommentVar,'Tau values:'):end);
                StrPos = findstr(TauDefinition,'|');
                TauValues = zeros(length(StrPos)-1,1);
                for i=1:length(StrPos)-1
                    TauValues(i)  = str2double(TauDefinition(StrPos(i)+1:StrPos(i+1)-1));
                end
                if isempty(TauValues)
                    TauValues = inputdlg('Tau-values could not be extracted. Input:');
                    TauValues = str2double(TauValues{1});
                end
                %Construct 2D unfolded signals
                FoldingFactor = length(TauValues);
                TauSignals = nan(FoldingFactor,Dimension1,Dimension2);
                for TauIndex = 1:FoldingFactor
                    for i=1:length(t1Timings)
                        TauSignals(TauIndex,Pos1(i),Pos2(i)) = Ordinate(i);
                    end
                end
                
                %Construct time axes
                TimeStep1 = DwellTime1/1000;
                TimeStep2 = DwellTime2/1000;
                TimeAxis1 = 0:TimeStep1:MaximalTiming1/1000;
                TimeAxis2 = 0:TimeStep2:MaximalTiming1/1000;
                
                exptype = '4pHYSCORE NUS';
                
            else
                
                % Uniform sampled data
                %--------------------------------------------------------------------
                NUSflag  = false;
                
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
                
                try
                    [TauValues,FirstTauValues,exptype] = brukertaus(BrukerParameters);
                catch
                    TauValues = inputdlg('Tau-values could not be extracted. Input (only for 4P HYSCORE and 1 tau-value):');
                    TauValues = str2double(TauValues{1});
                end
                
                %Control consistency between files 
                if isempty(TimeStep1control)
                TimeStep1control =  TimeStep1;
                TimeStep2control =  TimeStep2;
                Size2control = size(TauSignals,2);
                Size1control = size(TauSignals,3);
                else
                    if TimeStep1control~=TimeStep1 || TimeStep2control~=TimeStep2
                        error('Time steps are not consistent between files.')
                    end
                    if Size1control~=size(TauSignals,2) || Size2control~=size(TauSignals,3)
                        error('Signal dimensions are not consistent between files.')
                    end
                end
                
                %Collect tau-values of multiple files
                TauValuesVector(end+1:end+length(TauValues)) = TauValues;
                FirstTauValuesVector(end+1:end+length(TauValues)) = FirstTauValues;
                TauSignalsVector(end+1:end+size(TauSignals,1),:,:) =  TauSignals;

            end
            
        end
        
        %If multiple files were loaded then the tau-values are in another array
        if ~isempty(TauValuesVector)
            TauValues = TauValuesVector;
            FirstTauValues = FirstTauValuesVector;
            TauSignals = TauSignalsVector;
        end
        
        TimeAxis1 = linspace(0,TimeStep1*size(TauSignals,2),size(TauSignals,2));
        TimeAxis2 = linspace(0,TimeStep2*size(TauSignals,2),size(TauSignals,2));
        
        %Construct output structure
        MountedData.TauSignals = TauSignals;
        MountedData.TauValues = TauValues;
        if exptype == '6pHYSCORE'
            MountedData.FirstTauValues = FirstTauValues;
        end
        MountedData.BrukerParameters = BrukerParameters;
        MountedData.TimeStep1 = TimeStep1;
        MountedData.TimeStep2 = TimeStep2;
        MountedData.TimeAxis1 = TimeAxis1;
        MountedData.TimeAxis2 = TimeAxis2;
        MountedData.exptype = exptype;
        if NUSflag
            MountedData.NUSgrid = NUSgrid;
            MountedData.NUS.SamplingDensity  = SamplingDensity;
            MountedData.NUS.Dimension1  = Dimension1;
            MountedData.NUS.Dimension2  = Dimension2;
            
        end
        MountedData.NUSflag = NUSflag;
        MountedData.isNotIntegrated  = false;
        
        
        %------------------------------------------------------------------------
        % AWG Spectrometer Files
        %------------------------------------------------------------------------
    case '.mat'
        
        %Initiate the status bar in the Hyscorean gui
        set(handles.ProcessingInfo, 'String','Status: Checking data...'); drawnow;
      
        
        NFiles = length(str2double(FileNames));
        %Preallocate first time axis vector
        TimeAxis1 = zeros(NFiles,1);
        % Preprocess measurement data of first file with uwb_eval and set up data container
        Measurement = load(FileNames{1});
        expstruct = eval(append('Measurement.',Measurement.expname));
        
        
        % Check if data is NUS and proceed
        if isfield(expstruct,'NUS')
            isNUS = true;
        else
            isNUS = false;
            MountedData.NUSflag = isNUS;
        end
        
        
        % Evaluate experiment type and set up the time axis
        if isNUS
            %Extract time axes directly from the sampling grid
            exptype = '4pHYSCORE NUS';
            TimeAxis1 = expstruct.NUS.t1Timings;
            TimeAxis2 = expstruct.NUS.t2Timings;
            SamplingGrid = expstruct.NUS.SamplingGrid; 
        elseif length(expstruct.events) > 5 % case for 6pHYSCORE
            %Get timings and set up t_2 axis and zero time
            exptype = '6pHYSCORE';
            TimeAxis2 = expstruct.parvars{2}.axis;                          % adjust t_2 axis to zero time
            TimeAxis1(1) = expstruct.events{4}.t - expstruct.events{3}.t;   % first element of t1 vector from file name
        else                                % case for 4pHYSCORE
            %Get timings and set up t_2 axis and zero time
            exptype = '4pHYSCORE';
            TimeAxis2 = expstruct.parvars{2}.axis;                          % adjust t_2 axis to zero time
            TimeAxis1(1) = expstruct.events{3}.t - expstruct.events{2}.t;   % first element of t1 vector from file name
        end
        % --- Note: other HYSCORE variants need to be established here ---
 
        
        % Evaluate data from the AWG spectrometer
        options.plot = 0;
        OutputUWB = uwb_eval(FileNames{1},options);                     
        [Dimension3, Dimension2] = size(OutputUWB.dta_avg);             % Dimension3: echo axis size, Dimension2: t2 axis size
        EchoAxis = OutputUWB.t_ax;                                      % time axis of echo
        TauValues = zeros(1,NFiles);                                    % Storage for tau-values of each file
        if exptype == '6pHYSCORE'
            FirstTauValues = zeros(1,NFiles);                               % Storage of tau-values between the first 2 pulses of each file
            FirstTauValues(1) = expstruct.events{2}.t;  
            TauValues(1) = expstruct.parvars{1,2}.strt(2) - expstruct.parvars{1,2}.strt(1);  
        else
            TauValues(1) = expstruct.events{2}.t;                              
        end
        TimeAxis2array = zeros(NFiles,Dimension2);
        TimeAxis2array(1,:) = TimeAxis2;
        
        % Check consistency of echo dimension, get tau values and t1-axis position for each file
        for iFile = 2:NFiles
            OutputUWB = uwb_eval(FileNames{iFile},options);
            if Dimension3 > size(OutputUWB.dta_avg,1)
                Dimension3 = size(OutputUWB.dta_avg,1);                 % If the echo axis has fewer points, reduce Dimension3
            end
            TimeAxis2array(iFile,:) = OutputUWB.exp.parvars{2}.axis;
            % Get the position of the trace in the t1-dimension and all tau-values
            if exptype == '6pHYSCORE'       % 6pHYSCORE
                TimeAxis1(iFile) = OutputUWB.exp.events{4}.t - OutputUWB.exp.events{3}.t;
                TauValues(iFile) = expstruct.parvars{1,2}.strt(2) - expstruct.parvars{1,2}.strt(1);
                FirstTauValues(iFile) = OutputUWB.exp.events{2}.t;   
            else                            % 4pHYSCORE (with and without NUS)
                TimeAxis1(iFile) = OutputUWB.exp.events{3}.t - OutputUWB.exp.events{2}.t;
                TauValues(iFile) = OutputUWB.exp.events{2}.t;
            end
            % ---- Note: other HYSCORE variants need to be implemented here -----
        end
        
		% Get unique tau values and folding factor										 
        UniqueTaus = unique(TauValues);                                 
        FoldingFactor = numel(UniqueTaus);                              % FoldingFactor = # of different TauValues
        correctprocessing = true;                                       % check variable, if processing can be performed correctly
        taumissing = '';                                                % String with tau values, which do not have all necessary traces stored
        entriespertau = zeros(FoldingFactor,1);                         % #traces stored for each tau value
        
        
        if  ~isNUS
            % sort Files with respect to tau values and t1 axis + Check for TimeAxis inconsistencies
            % sort with respect to tauvalues
            [TauValuessorted, fileposition] = sort(TauValues);          % store the sorting information in fileposition array
            TimeAxis1sorted = TimeAxis1(fileposition);                  % sort timeaxis points accordingly
            if exptype == '6pHYSCORE'
                FirstTauValues = FirstTauValues(fileposition);
                UniqueFirstTaus = [];
            end
            TimeAxis2array(:,:) = TimeAxis2array(fileposition,:);
            TimeAxis1construct = cell(FoldingFactor,1);                 % construct a virtual timeaxis for each tau value
            % sort each tau-value with respect to t1 axis
            strt = 1;
            for i = 1:FoldingFactor
                if exptype == '6pHYSCORE'
                    UniqueFirstTaus(i) = FirstTauValues(strt);
                end
                entriespertau(i) = sum(TauValues == UniqueTaus(i));     % determine the number of traces stored for the tau value
                last = strt + entriespertau(i) - 1;
                index = strt:last;                                      % select start and end position in the array for the tau value
                [TimeAxis1sorted(index),position] = sort(TimeAxis1sorted(index));   % sort the timeaxis1 entries of the tau value
                fileposition(index) = fileposition(index(position));                % store the information in the fileposition array

           % Create the virtual timeaxis for later mounting procedure
                if entriespertau(i) < Dimension2
                     taumissing = append(taumissing, ' ', num2str(UniqueTaus(i)));          % Store that traces are missing for warning              
                     if entriespertau(i) > 1                                                % Construct time axis from the first 2 t1 points
                        InitialTimeStep = TimeAxis1sorted(strt+1) - TimeAxis1sorted(strt);
                        TimeAxis1construct{i} = TimeAxis1sorted(strt):InitialTimeStep:(TimeAxis1sorted(strt)+InitialTimeStep*(Dimension2-1));
                     else                                                                   % Warning if only one trace is loaded
                        warnstr = append('Only one trace loaded for tau value ',num2str(UniqueTaus(i)), ' ns and t1 axis could not be constructed');
                        warndlg(warnstr,'Warning');
                        TimeAxis1construct{i} = TimeAxis1sorted(strt);
                        correctprocessing = false;
                     end
                else                                                                        % If all traces are loaded, use the existing t1 axis
                    TimeAxis1construct{i} = TimeAxis1sorted(index);
                end

                % Check if t1 axis has the same values as t2 timeaxis
                if sum(ismembertol(TimeAxis1sorted(index),TimeAxis2array(strt,:))) < entriespertau(i)
                    warnstr = append('t1 axis does not have the same values as the t2 axis for tau = ',num2str(UniqueTaus(i)), ' ns');
                    warndlg(warnstr,'Warning');
                    correctprocessing = false;
                end

                % Evaluate if all time axes start at the same value
                % if not -> FT transformation might lead to wrong results in processHYSCORE.m
                 if sum(ismembertol(TimeAxis2array(strt,:),TimeAxis2)) < Dimension2
                    warnstr = append('t2 axis for tau value ', num2str(UniqueTaus(i)), ' ns does not match with t2 axis of ', num2str(UniqueTaus(1)), ' ns');
                    warndlg(warnstr,'Warning');
                    correctprocessing = false;
                end
                strt = last + 1;
            end

            if ~strcmp(taumissing,'')                                       % Display warning if traces are missing
                 warnstr = append('Not enough traces for correct HYSCORE spectrum with tau-value',taumissing);
                 warndlg(warnstr,'Warning');
                 correctprocessing = false;
            end

            % Sort the stored FileNames as done before
            FileNamessorted = FileNames(fileposition);

        end

        % Set up arrays for uwb_eval output and filtering
        if isNUS
            AverageEchos = zeros(Dimension3, size(SamplingGrid,2), size(SamplingGrid,1)*FoldingFactor); % Storage for filtered Echos
        else
            UnfilteredEchos = cell(Dimension2*FoldingFactor,1);         % Storage of downconverted, unfiltered echos
            AverageEchos = cell(Dimension2*FoldingFactor,1);            % Storage of filtered echos
            corr_phase = zeros(Dimension2*FoldingFactor,1);             % Vector of phase corrections for each trace
            Echopos = zeros(Dimension2*FoldingFactor,1);                % Vector of the echo position from uwb_eval for each trace
            evlen = zeros(Dimension2*FoldingFactor,1);                  % Vector of the evaluation length from uwb_eval for each trace
            dta = cell(Dimension2*FoldingFactor,1);                     % Cell array for original echo data
            TimeAxis1ordered = zeros(Dimension2*FoldingFactor,1);       % TimeAxis1 with values only for existing traces, others have 0 entries
            FileNamesordered = cell(Dimension2*FoldingFactor,1);        % Cell array with the filenames sorted with respect to the tau and t1 value
            dim1indexlist = zeros(NFiles,1);                            % Vector of indices, which indicate where each file went during sorting
        end
        EchoAxis = EchoAxis(1:Dimension3);                              % Reduce EchoAxis dimension to Dimension3
        Filtering = true;
   

        %Set up filtering
        SamplingRateMHZ = 1/(EchoAxis(2) - EchoAxis(1))*1e3;            % sampling rate from time axis
        try
            CutoffFrequencyMHZ = filter_freq;
        catch
            CutoffFrequencyMHZ = SamplingRateMHZ/30;                    % cutoff frequency
        end
        %Butterworth IIR filter
        FilterCutoffFrequency = CutoffFrequencyMHZ/(SamplingRateMHZ/2);
        FilterOrder = 2;
        [NumeratorCoefficients,DenominatorCoefficients] = butter(FilterOrder,FilterCutoffFrequency);

        % Evaluation with uwb_eval and filtering of each trace, storing data in correct order in arrays for mountHYSCOREdata gui
        for iFile = 1:NFiles
            set(handles.ProcessingInfo, 'String', sprintf('Status: Mounting file %i/%i',iFile,NFiles)); drawnow;
            OutputUWB = uwb_eval(FileNamessorted{iFile},options);             % Evaluate file with uwb_eval
            AWG_Parameters = OutputUWB.exp;                             % Store general experiment parameters
			AWG_Parameters.nu_obs = OutputUWB.det_frq;								 
            OutputUWB.dta_avg = OutputUWB.dta_avg(1:Dimension3,:);      
            
            if Filtering                                                % Filtering
                FilteredEchos = filtfilt(NumeratorCoefficients,DenominatorCoefficients,OutputUWB.dta_avg);
            else
                FilteredEchos = OutputUWB.dta_avg;
            end
            
            if isNUS
                currentT1 = AWG_Parameters.events{3}.t-AWG_Parameters.hyscore_t1.strt(1);   % might not be stored in file
                TauPosition = find(UniqueTaus == TauValues(iFile));
                GridPosition = find(TimeAxis1==currentT1);
                currentT2SamplingScheme = SamplingGrid(:,GridPosition)==1;
                AverageEchos(:,currentT2SamplingScheme,GridPosition + (TauPosition-1)*size(SamplingGrid,1)) = FilteredEchos; % not corrected to cell
            else
                % store data in sorted order in the appropriate arrays for mountHYSCOREdata gui
                if NFiles < FoldingFactor * Dimension2
                    tauindex = find(TauValuessorted(iFile) == UniqueTaus);
                    t1index = find(abs(TimeAxis1construct{tauindex} - TimeAxis1sorted(iFile)) < 0.1);
                    if isempty(t1index)
                        errordlg('t1 axis was not constructed correctly, probably because one of the first two traces of one tau value is missing','error');
                    end
                    dim1index = (tauindex-1)*Dimension2 + t1index;
                else
                    dim1index = iFile;
                end
                dim1indexlist(iFile) = dim1index;
                UnfilteredEchos{dim1index} = OutputUWB.dta_avg;
                AverageEchos{dim1index} = FilteredEchos;
                corr_phase(dim1index) = OutputUWB.corr_phase;
                dtastruct = load(FileNamessorted{iFile},'dta');
                dta{dim1index} = dtastruct.dta;
                Echopos(dim1index) = OutputUWB.echopos;
                evlen(dim1index) = OutputUWB.evlen;
                FileNamesordered{dim1index} = FileNamessorted{iFile};
                TimeAxis1ordered(dim1index) = TimeAxis1sorted(iFile);
            end
        end
        
        
        % In case something goes wrong and NaNs are formed set them to void
        TimeAxis1(~any(~isnan(TimeAxis1), 1)) = [];             % Still necessary?
        
        
        % Mount Data structure for integration and integrate it with integrateEcho
        DataForIntegration.AverageEcho = AverageEchos;
        DataForIntegration.EchoAxis = EchoAxis;
        DataForIntegration.isNotIntegrated  = true;
        DataForIntegration.Dimension2 = Dimension2;
        options.status = handles.ProcessingInfo;
        [IntegratedData] = integrateEcho(DataForIntegration,'gaussian',options);
        if ~isstruct(IntegratedData) && isnan(IntegratedData)
            h = warndlg({'Default gaussian echo integration failed.',...
                ' Switching to boxcar echo integration.'},'Warning');
            waitfor(h);
            [IntegratedData] = integrateEcho(DataForIntegration,'boxcar',options); % use boxcar if gaussian fails
        end
        
        TauSignals = zeros(FoldingFactor,Dimension2,Dimension2); 
        %Loop through all tau-values and store integrated data at the correct position in TauSignals
        if isNUS
            StartPosition = 1;
            %Extract the additional dimensions from the folded dimension
            for FoldingIndex=1:FoldingFactor
                TauSignals(FoldingIndex,:,:)=IntegratedData.Integral(1:end,StartPosition:Dimension2/FoldingFactor*FoldingIndex);
                StartPosition = Dimension2/FoldingFactor*FoldingIndex + 1;
            end
        else
            for Index = 1:FoldingFactor
                TauSignals(Index,:,:) = IntegratedData.Integral(:,1+(Index-1)*Dimension2:Index*Dimension2)';
            end
            
            TimeAxis1 = TimeAxis1ordered;
            % Get the time axis for plotting the original echos before downconversion
            exp = load(FileNames{1},'conf');
            fsmp = exp.conf.std.dig_rate;
            dtatimeaxis = linspace(0,size(dta{1},1)-1,size(dta{1},1))./fsmp; 
        end
        
        % Mount data structure with integrated signals
        if ~isNUS
            MountedData.WindowFunction = IntegratedData.WindowFunction;
            MountedData.dta = dta;
            MountedData.EchoAxisfordta = dtatimeaxis;
            MountedData.FilterCutoffFrequency = FilterCutoffFrequency;
            MountedData.dim1indexlist = dim1indexlist;
            MountedData.corr_phase = corr_phase;
            MountedData.UnfilteredEchos = UnfilteredEchos;
            MountedData.evlen = evlen;
            MountedData.Echopos = Echopos;
            MountedData.Dimension3 = Dimension3;
        end
        MountedData.TauSignals = TauSignals;
        MountedData.TauValues = UniqueTaus;
        if exptype == '6pHYSCORE'
            MountedData.FirstTauValues = UniqueFirstTaus;
        end
        MountedData.AverageEchos = AverageEchos;
        MountedData.AWG_Parameters = AWG_Parameters;
        MountedData.TimeAxis1 = TimeAxis1;
        MountedData.TimeAxis2 = TimeAxis2;
        MountedData.TimeStep1 = (TimeAxis1(2) - TimeAxis1(1))/1000;
        MountedData.TimeStep2 = (TimeAxis2(2) - TimeAxis2(1))/1000;
        MountedData.EchoAxis = EchoAxis;
        MountedData.NUSflag = isNUS;
        MountedData.correctprocessing = correctprocessing;
        MountedData.exptype = exptype;
        MountedData.isNotIntegrated  = false;
        if MountedData.NUSflag
            MountedData.NUSgrid = AWG_Parameters.NUS.SamplingGrid;
            MountedData.NUS = AWG_Parameters.NUS;
        end
     
        
        % set up of mount AWG data gui here
        if ~isNUS
            setappdata(0,'MountedData',MountedData)
            setappdata(0,'FileNames',FileNamesordered)
            mountAWGdata();
            uiwait;
            MountedData = getappdata(0,'MountedData');
        end
        
        
        %------------------------------------------------------------------------
        % ASCII format
        %------------------------------------------------------------------------
    case '.txt'
        
        %Load data from ASCII file
        Measurement = dlmread(FileNames{1});
        t1Timings = Measurement(:,1);
        t2Timings = Measurement(:,2);
        RealPart = Measurement(:,3);
        ImagPart = Measurement(:,4);
        Taus = Measurement(:,5);
        
        %Get tau values
        TauValues = unique(Taus);
        
        %Get t1 and t2 time axes
        t1Unique = unique(t1Timings);
        t2Unique = unique(t2Timings);
        
        %Round time intervals to 1 ns resolution
        DwellTimes1 = round(diff(t1Unique));
        DwellTimes2 = round(diff(t2Unique));
        
        %Get effective dwell time for each  dimension
        DwellTime1 = min(DwellTimes1);
        DwellTime2 = min(DwellTimes2);
        
        %Get grid dimensions from maximal timing
        MaximalTiming1 = max(round(t1Unique));
        MaximalTiming2 = max(round(t2Unique));
        Dimension1 = MaximalTiming1/DwellTime1;
        Dimension2 = MaximalTiming2/DwellTime2;
        
        %Determine if timings are uniformly spaced
        UniformCheck1 = range(DwellTimes1);
        UniformCheck2 = range(DwellTimes2);
        
        if UniformCheck1 + UniformCheck2 == 0
            NUSflag = false;
        else
            NUSflag = true;
        end
        
        if NUSflag
            %Construct NUS grid from timings
            Pos1 = 1 + t1Timings/DwellTime1;
            Pos2 = 1 + t2Timings/DwellTime2;
            NUSgrid = zeros(Dimension1,Dimension2);
            for i=1:length(t1Timings)
                NUSgrid(Pos1(i),Pos2(i)) = 1;
            end
        else
            NUSgrid = ones(Dimension1,Dimension2);
        end
        
        %Construct time axes
        TimeStep1 = DwellTime1/1000;
        TimeStep2 = DwellTime2/1000;
        TimeAxis1 = 0:TimeStep1:MaximalTiming1/1000;
        TimeAxis2 = 0:TimeStep2:MaximalTiming1/1000;
        
        %Construct the signal matrix from the t1 and t2 timings
        FoldingFactor = length(TauValues);
        
        TauSignals = zeros(FoldingFactor,Dimension1,Dimension2);
        for j=1:FoldingFactor
            for i=1:length(t1Timings)/FoldingFactor
                Position = i + length(t1Timings)/FoldingFactor*(j - 1);
                t1Pos = 1 + (t1Timings(Position) - mod(t1Timings(Position),DwellTime1))/DwellTime1;
                t2Pos = 1 + (t2Timings(Position) - mod(t2Timings(Position),DwellTime2))/DwellTime2;
                TauSignals(j,t1Pos,t2Pos) = RealPart(Position) + 1i*ImagPart(Position);
            end
        end
        TauSignals = TauSignals(:,1:Dimension1,1:Dimension2);
        
        %Construct output structure
        MountedData.TauSignals = TauSignals;
        MountedData.TauValues = TauValues;
        MountedData.TimeStep1 = TimeStep1;
        MountedData.TimeStep2 = TimeStep2;
        MountedData.TimeAxis1 = TimeAxis1;
        MountedData.TimeAxis2 = TimeAxis2;
        MountedData.NUSgrid = NUSgrid;
        MountedData.NUSflag = NUSflag;
        MountedData.isNotIntegrated  = false;
        MountedData.exptype = 'HYSCORE';
        
    otherwise
        error('Unvalid extension: Please check your loaded files. Allowed extensions: .DSC .DTA .mat .txt')
end


end