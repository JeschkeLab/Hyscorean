function output = uwb_eval( arg1, arg2 )
%UWB_EVAL evaluates data from the AWG spectrometer. Experiments with up to
%two indirect dimensions are supported
% possible calls:
% output = UWB_EVAL('filename'), where filename is the path to stored data
% output = UWB_EVAL(), which evaluates the current experiment (currexp in workspace)
% output = UWB_EVAL(data), which evaluates the provided data, aided by
% additional variables obtained from the current experiment (currexp in
% workspace)
%
% The output is a structure of the following form:
%   output.dta_ev:          Integrated echo transients
%   output.dta_avg:         Full downconverted echo transient, all averages combined,
												 
%   output.nAvgs:           number of averages of experiment
%   output.dta_x:           Cell of indirect dimensions of the experiment
%   output.t_ax:            Time axis of the echo transients
%   output.exp:             The experiment data structure
%   output.det_frq:         The downconversion frequency/ies used by
%                           UWB_EVAL
%   output.echopos:         The final position of the echo in trace of length evlen
%   output.echopos_org:     The position of the echo in the measured transient
%   output.corr_phase:      The phase used to correct the echo
%   output.dig_level:       Fraction of fullscale vertical digitizer level 
%                           required to digitize the echo. 
%   output.evlen:           Length of the window to store the echo
%                           transient and perform the integration.
% 
% Options may be provided, which facilitates the calls
% UWB_EVAL('filename',options), UWB_EVAL(options), UWB_EVAL(data,options)
% The variable options is a structure with the following optional fields
%   options.plot:           1, default: produce simplistic plots, 0: no
%                           plots
%   options.elim_pcyc:      Elimination of remaining phase cycles. Default
%                           is 1 for eliminiation. No elimination for 0
%   options.evlen:          Length of the window to store the echo
%                           transient and perform the integration. By
%                           default, UWB_EVAL searches the best range
%   options.det_frq:        Force a certain frequency to downconvert
%                           echoes. By default, UWB_EVAL automatically
%                           determines the downconversion frequency based
%                           on the experimental parameters.
%   options.corr_phase:     To enforce a fixed phase for phase-correction
%                           of downconverted echo transients.
%   options.phase_all:      To enforce that each individual echo is
%                           phase-corrected by its angle. For the echo
%                           integrals in dta_ev, that is equivalent to
%                           taking the absolute value. For the echo
%                           transients, however, it may be relevant for
%                           further processing.
%   options.find_echo:      Wether (1) or not (0) to search for the echo
%                           window. 
%   options.echopos:        Use fixed echo position. Requires find_echo = 0																		   
%   options.ref_echo:       Automatic search of the echo window and phasing
%                           of data is performed based on the echo at
%                           datapoint ref_echo. UWB_EVAL chooses ref_echo
%                           based on the maximum echo intensity found. If a
%                           different echo is requested, this can be
%                           provided by ref_echo. For the last echo in the
%                           series, one can provide the string 'end'
%   options.ref_echo_2D_idx options.ref_echo has its limitations for 2D
%   options.ref_echo_2D_dim data, such that ref_echo_2D_idx is useful in
%                           this case. Here, ref_echo will be chosen based
%                           on the maximum echo for a fixed ref_echo_2D_idx
%                           at dimension specified by ref_echo_2D_dim. A
%                           frequent case is nutation with a frequency
%                           step, where ref_echo_2D_dim = 1 and
%                           ref_echo_2D_idx = 1, so as to use the maximum
%                           echo found for the first point of the nutation
%                           for finding the echo window and phase. Also
%                           here, the last echo along the dimension may be
%                           specified by the string 'end'.
% Andrin Doll, 2016

% parse function
if exist('arg1','var')
    if isstr('arg1')
        filename = arg1;
    elseif isstruct('arg1')
        options = arg1;
    else
        RawData = {double(arg1)};
    end
end

if exist('arg2','var')
    if isstruct(arg2)
        options = arg2;
    elseif ~isempty(arg2)
        error('invalid second argument for uwb_eval');
    end
end

if ~exist('options','var')
    options = [];
end

%% get all the data required for evaluation
if exist('filename','var') % by file
    SavedData = load(filename);
    estr = eval(['SavedData.' SavedData.expname]);
    [RawData,Averages,ErrorText] = extractdata(SavedData,estr,filename);
    if ~isempty(ErrorText)
        error(ErrorText);
    end
    
    conf = SavedData.conf;
else
    % get everything from workspace
    % conf
    if evalin('base','exist(''conf'',''var'')');
        conf = evalin('base','conf');
    else
        error('Could not find conf in workspace');
    end
    % current experiment
    if evalin('base','exist(''currexp'',''var'')');
        estr = evalin('base','currexp');
    else
        error('Could not find currexp in workspace');
    end
    % try to get data, unless already provided
    if ~exist('dta','var')
        % first look for already runnig averages
        filelist = ls([estr.savepath filesep '*' estr.savename '.mat' ]);
        datenr = str2num(filelist(:,1:8))*10000 + str2num(filelist(:,10:13));
        [~,maid] = max(datenr);
        dig_interface('savenow'); % go for another save before reading
        SavedData = load([estr.savepath filesep filelist(maid,:)]);
        [RawData,Averages,ErrorText] = extractdata(SavedData,estr,filelist(maid,:));
        if ~isempty(ErrorText)
            warning(ErrorText);
            return
        end
    end
end

%% go through parvars and eliminate phase cycles
if ~isfield(estr,'postsigns')
    [estr.postsigns, ~] = exp_signprog(estr);
end

cycled = cellfun('length',estr.postsigns.signs) > 1;

% decide on wheteher the phase cycle should be eliminated or not
if any(cycled == 0)
    elim_pcyc = 1; % if there is any non-phasecycling parvar
else
    elim_pcyc = 0; % if all parvars cycle phases, do not reduce them
end

if isfield(options,'elim_pcyc')
    elim_pcyc = options.elim_pcyc;
end

% Get the cycles out
if elim_pcyc
    for ii=1:length(cycled)
        if cycled(ii)
            if ii > 1
                n_skip = prod(estr.postsigns.dims(1:ii-1));
            else
                n_skip = 1;
            end
            plus_idx = find(estr.postsigns.signs{ii} == 1);
            minus_idx = find(estr.postsigns.signs{ii} == -1);
            plus_mask = (1:n_skip)+(plus_idx-1)*n_skip;
            minus_mask = (1:n_skip)+(minus_idx-1)*n_skip;
            n_rep = size(RawData{1},2)/(n_skip*estr.postsigns.dims(ii));
            for kk=1:length(RawData)
                %re-allocate
                tmp = RawData{kk};
                RawData{kk} = zeros(size(tmp,1),n_rep*n_skip);
                % substract out
                for jj = 1:n_rep
                    curr_offset = (jj-1)*n_skip;
                    full_offset = (jj-1)*n_skip * estr.postsigns.dims(ii);
                    RawData{kk}(:,(1:n_skip)+curr_offset) = tmp(:,plus_mask+full_offset) - tmp(:,minus_mask+full_offset);
                end
            end
        end
    end
end

%% get all axes out
dta_x = {}; ii_dtax = 1;
RelevantSweptVariables = [];
for ii = 1:length(cycled)
    if elim_pcyc && cycled(ii)
        continue
    end
    dta_x{ii_dtax} = estr.parvars{estr.postsigns.ids(ii)}.axis;
    RelevantSweptVariables(ii_dtax) = estr.postsigns.ids(ii);
    ii_dtax = ii_dtax + 1;
end

if ii_dtax - 1 == 2
    ExperimentDimensions = 2;
elseif ii_dtax - 1 == 1
    ExperimentDimensions = 1;
elseif ii_dtax - 1 == 0
    error('Your dataset does not have any swept dimensions. Uwb_eval does not work for experiments without any parvars');
else
    error('Uwb_eval cannot handle more than two dimensions');
end
    

% important frequencies
DetectionFrequency = estr.events{estr.det_event}.det_frq;
det_frq_dim = 0;
fsmp = conf.std.dig_rate;

% automatic search for frequency change, unless enforced to really use only
% a fixed frequency
if isfield(options,'det_frq')
    DetectionFrequency = options.det_frq;
else
    
    % is there any frequency change due to the parvars?
    det_frq_dim = 0; % the dimension which makes the frequency change
    for ii=1:length(RelevantSweptVariables)
        act_par = estr.parvars{RelevantSweptVariables(ii)};
        frq_change = zeros(length(act_par.variables),1);
        for jj = 1:length(act_par.variables)
            if ~isempty(strfind(act_par.variables{jj},'nu_'))
                frq_change(jj) = 1;
            end
        end
        
        % was there a change in a frequency?
        if any(frq_change)
            % is the frequency change relevant, i.e. on the pulse at event det_frq_id?
            if isfield(estr.events{estr.det_event},'det_frq_id')
                frq_pulse = estr.events{estr.det_event}.det_frq_id;
                nu_init_change = 0; nu_final_change = 0;
                for jj = 1:length(act_par.variables)
                    if ~isempty(strfind(act_par.variables{jj},['events{' num2str(frq_pulse) '}.pulsedef.nu_i']));
                        nu_init_change = jj;
                    elseif ~isempty(strfind(act_par.variables{jj},['events{' num2str(frq_pulse) '}.pulsedef.nu_f']));
                        nu_final_change = jj;
                    end
                end
                
                if any([nu_init_change,nu_final_change])
                    % so there is a frequency change on the frequency encoding
                    % pulse
                    
                    det_frq_dim = ii; % the dimension that will determine the detection frequency
                    
                    % which type of pulse are we dealing with?
                    if ~isfield(estr.events{frq_pulse}.pulsedef,'nu_final')
                        % rectangular pulse, where only nu_init is given
                        
                        % catch case XX
                        if nu_init_change == 0
                            warning(['uwb_eval has no idea how to guess your detection frequency. You were setting a rectangular pulse in event ' num2str(frq_pulse) ', but are now increasing its end frequency. You may obtain unexpected results.']);
                        end
                        % get the frequencies, either from the vectorial
                        % definition
                        if isfield(act_par,'vec')
                            DetectionFrequency = act_par.vec(:,nu_init_change);
                        else
                            % or from the parametric definition
                            nu_init = estr.events{frq_pulse}.pulsedef.nu_init;
                            if isnan(act_par.strt(nu_init_change))
                                DetectionFrequency = (0:act_par.dim-1).'*act_par.inc(nu_init_change) + nu_init;
                            else
                                DetectionFrequency = (0:act_par.dim-1).'*act_par.inc(nu_init_change) + act_par.strt(nu_init_change);
                            end
                        end
                    else
                        % chirp pulse, where we need to consider both nu_init
                        % and nu_final and use the middle frequency as det_frq
                        nu_init = estr.events{frq_pulse}.pulsedef.nu_init;
                        nu_final = estr.events{frq_pulse}.pulsedef.nu_final;
                        % get the frequencies, either from the vectorial
                        % definition
                        if isfield(act_par,'vec')
                            if nu_init_change ~= 0
                                nu_init = act_par.vec(:,nu_init_change);
                            end
                            if nu_final_change ~= 0
                                nu_final = act_par.vec(:,nu_final_change);
                            end
                        else
                            % or from the parametric definition
                            if nu_init_change ~= 0
                                if isnan(act_par.strt(nu_init_change))
                                    nu_init = (0:act_par.dim-1).'*act_par.inc(nu_init_change) + nu_init;
                                else
                                    nu_init = (0:act_par.dim-1).'*act_par.inc(nu_init_change) + act_par.strt(nu_init_change);
                                end
                            end
                            if nu_final_change ~= 0
                                if isnan(act_par.strt(nu_final_change))
                                    nu_final = (0:act_par.dim-1).'*act_par.inc(nu_final_change) + nu_final;
                                else
                                    nu_final = (0:act_par.dim-1).'*act_par.inc(nu_final_change) + act_par.strt(nu_final_change);
                                end
                            end
                        end
                        % so now we can combine these to get the detection
                        % frequency
                        DetectionFrequency = (nu_init+nu_final)/2;
                    end
                end
            else
                % we can only land here, if there was no det_frq_id given, but
                % det_frq was explicitly provided in the experiment. This could
                % be intentional, but could even so be a mistake of the user.
                warning(['uwb_eval has no idea how to guess your detection frequency. You were changing some pulse frequencies, but did not provide det_frq_id for your detection event. I will use det_frq, as you provided it in the experiment.']);
            end
        end
    end
end

%% determine the maximum level of the digitzer for the current experiment setting

% get the total number of datapoints
parvar_pts = zeros(size(estr.parvars));
for ii = 1:length(estr.parvars)
    if isfield(estr.parvars{ii},'vec')
        parvar_pts(ii) = size(estr.parvars{ii}.vec,1);
    else
        parvar_pts(ii) = estr.parvars{ii}.dim;
    end
end

% the number of data points entering one echo transient (due to reduction
% during acquisition or reduction of phasecycles just above)
n_traces = prod(parvar_pts) / prod(cellfun(@length,dta_x));

if isfield(conf,'dig_max')
    trace_maxlev = n_traces * estr.shots * conf.dig_max;
else
    trace_maxlev = n_traces * estr.shots * 2^11;
end


%% get out all echoes
% where is the echo expected?
%   -> make a symmetric window about it to search for it (ran_echomax)
if isfield(options,'find_echo') && options.find_echo == 0 && isfield(options,'echopos') && options.echopos ~= 0
    EchoPosition = options.echopos;
else
    EchoPosition = estr.events{estr.det_event}.det_len/2 - estr.events{estr.det_event}.det_pos*fsmp;
end
Distance2Position = min([EchoPosition,estr.events{estr.det_event}.det_len-EchoPosition]);
EchoMaxRange = (EchoPosition-Distance2Position+1:EchoPosition+Distance2Position).';

% get the downconversion LO
FullTimeAxis = (0:(length(EchoMaxRange)-1)).'/fsmp;
LO = exp(-2*pi*1i*FullTimeAxis*DetectionFrequency.');

flipback = 0;
% 1D or 2D?
if ExperimentDimensions == 2 
    dta_ev = zeros(length(dta_x{1}),length(dta_x{2}));
    DataAveraged = zeros(length(EchoMaxRange),length(dta_x{1}),length(dta_x{2}));
    perm_order = [1 2 3];
    if det_frq_dim == 2
        perm_order = [1 3 2];
        flipback = 1;
        dta_ev = dta_ev.';
        DataAveraged = permute(DataAveraged,perm_order);
    end
elseif ExperimentDimensions == 1
    dta_ev = zeros(size(RawData{1},2),1).';
    DataAveraged = zeros(length(EchoMaxRange),size(RawData{1},2));
end

for ii=1:length(RawData)
    
    % Truncate data according to range of echo 
    TruncatedData = RawData{ii}(EchoMaxRange,:);
    % Calculate analytical signal by Hilbert transform
    HilbertData = conj(hilbert(TruncatedData));

    %  Reshape 2D data
    if ExperimentDimensions == 2
       DataResort = reshape(HilbertData, length(EchoMaxRange),length(dta_x{1}),length(dta_x{2}));
       DataResort = permute(DataResort,perm_order);
    else
        DataResort = HilbertData;
    end
    
    % downconvert
    DownconvertedData = bsxfun(@times,DataResort,LO);
    
    % refine the echo position for further evaluation, based on the first average
    if ii == 1
    
        % put a symmetric window to mask the expected echo position
        WindowedData = bsxfun(@times,DownconvertedData,chebwin(size(DownconvertedData,1)));

        % absolute part of integral, since phase is not yet determined
        SumIntegral = squeeze(abs(sum(WindowedData)));

        % get the strongest echo of that series
        [~,ReferenceEcho] = max(SumIntegral(:));
        
        % use this echo to inform about the digitizer scale
        MaximalAmplitude = max(RawData{ii}(EchoMaxRange,ReferenceEcho));
        DigitizerLevel = MaximalAmplitude / trace_maxlev;
        
        if isfield(conf.std,'IFgain_levels')
            % and check about eventual improvement by changing the IFgain
            PossibleLevels = DigitizerLevel * conf.std.IFgain_levels / conf.std.IFgain_levels(estr.IFgain+1);
            
            % crop the too large levels
            PossibleLevels(PossibleLevels > 0.75) = 0;
            [BestLevel,BestIndex] = max(PossibleLevels);
            if BestIndex-1 ~= estr.IFgain
                warning(['You are currently using ' num2str(DigitizerLevel) ...
                    ' of the maximum possible level of the digitizer at an IFgain setting of ' num2str(estr.IFgain) ...
                    '. It may be advantageous to use an IFgain setting of ' num2str(BestIndex-1) ...
                    ', where the maximum level will be on the order of ' num2str(BestLevel) '.']);
            end
        end
        
        
        % for 2D data, only a certain slice may be requested
        if isfield(options,'ref_echo_2D_idx') && ~isempty(options.ref_echo_2D_idx)
            % eventually set standard value of dimension, i.e. 1
            if ~isfield(options,'ref_echo_2D_dim')
                options.ref_echo_2D_dim = 1;
            end
            % eventually adjust for flipping of data
            if flipback
                if options.ref_echo_2D_dim == 1
                    options.ref_echo_2D_dim = 2;
                else
                    options.ref_echo_2D_dim = 1;
                end
            end
            % eventually substitute the 'end' keyword
            if strcmp(options.ref_echo_2D_idx,'end')
                options.ref_echo_2D_idx = size(SumIntegral,options.ref_echo_2D_dim);
            else
                options.ref_echo_2D_idx = options.ref_echo_2D_idx;
            end
            
            % now get the actual maximum
            if options.ref_echo_2D_dim == 1
                Index1Reference = options.ref_echo_2D_idx;
                [~,Index2Reference] = max(SumIntegral(Index1Reference,:));
            else
                Index2Reference = options.ref_echo_2D_idx;
                [~,Index1Reference] = max(SumIntegral(:,Index2Reference));
            end
            
            % convert the ii_ref,jj_ref to a linear index, as this is how
            % the convolution is done a few lines below
            ReferenceEcho = sub2ind(size(SumIntegral),Index1Reference,Index2Reference);
            
        end
        
        if isfield(options,'ref_echo')
            if strcmp(options.ref_echo,'end')
                ReferenceEcho = length(SumIntegral(:));
            else
                ReferenceEcho = options.ref_echo;
            end
        end

        % look for zerotime by crosscorrelation with echo-like window (chebwin..),
        % use conv istead of xcorr, because of the life-easy-making 'same' option
        convshape = chebwin( min([100,length(EchoMaxRange)]) ); % this is where one could use a matched echo shape (matched filtering)
        
        [~,e_idx] = max(conv(abs(DownconvertedData(:,ReferenceEcho)),convshape,'same'));
        
        % now get the final echo window, which is centered around the
        % maximum position just found
        Distance2Position = min([e_idx,size(DownconvertedData,1)-e_idx]);
        WindowLength = 2* Distance2Position;
        
        % eventually get the parameters enforced by the user
        if isfield(options,'evlen')
            WindowLength = options.evlen;
        end
        if isfield(options,'find_echo') && options.find_echo == 0
            e_idx = floor(size(DownconvertedData,1)/2);
        end
        if isfield(options,'echopos') && isfield(options,'find_echo') && options.find_echo == 0
            e_idx = options.echopos;
        end
        
        % here the final range...
        RangeEcho = (e_idx-WindowLength/2+1:e_idx+WindowLength/2).';        % position in the original data
        % shift to fit RangeEcho at the into the already symmetrically windowed DownconvertedData
        shiftRangeEcho = EchoMaxRange(1) - 1;                               
        RangeEcho = RangeEcho - shiftRangeEcho;
        % ... and a check wether this is applicable
        if ~(RangeEcho(1) > 0 && RangeEcho(end) - RangeEcho(1) <= size(DownconvertedData,1))
            error(['Echo position at ' num2str(e_idx) ' with evaluation length of ' num2str(WindowLength) ' is not valid, since the dataset has only ' num2str(size(DownconvertedData,1)) ' points.']);
        end
        
        % here the final time axis of the dataset
        EchoTimeAxis = (-WindowLength/2:(WindowLength/2-1)).'/fsmp;
        
        % get also indices of reference echo in case of 2D data
        [Index1Reference,Index2Reference] = ind2sub(size(SumIntegral),ReferenceEcho);
    end
    
    % window the echo
    WindowedData = bsxfun(@times,DownconvertedData(RangeEcho,:,:),chebwin(WindowLength));
    
    % get all the phases and use reference echo for normalization
    DataAngles = angle(sum(WindowedData));
    
    % for frequency changes, we phase each frequency
    if det_frq_dim ~= 0
        if ExperimentDimensions == 2
            CorrectionPhase = DataAngles(:,:,Index2Reference);
        else
            CorrectionPhase = DataAngles;
        end
    else
        CorrectionPhase = DataAngles(ReferenceEcho);
    end
    % check if a fixed phase was provided
    if isfield(options,'corr_phase')
        CorrectionPhase = options.corr_phase;
    end
    % check if any datapoint needs to be phased individually
    if isfield(options,'phase_all') && options.phase_all == 1
        CorrectionPhase = DataAngles;
    end
        
    DataPhased = bsxfun(@times,WindowedData,exp(-1i*CorrectionPhase));
    
    dta_ev = dta_ev + squeeze(sum(DataPhased))/sum(chebwin(WindowLength));
    
    DataAveraged(1:WindowLength,:,:) = DataAveraged(1:WindowLength,:,:) + bsxfun(@times,DownconvertedData(RangeEcho,:,:),exp(-1i*CorrectionPhase));
    
end
% keyboard
% flip back 2D data?
if flipback
    DataAveraged = permute(DataAveraged,perm_order);
    dta_ev = dta_ev.';
end

%% put variables back
output.nAvgs = Averages;
output.dta_avg = DataAveraged(1:WindowLength,:,:);
output.dta_x = dta_x;
output.t_ax = EchoTimeAxis;
output.dta_ev = dta_ev;
output.exp = estr;
output.det_frq = DetectionFrequency;
output.echopos = e_idx;
output.echopos_org = EchoPosition;
output.corr_phase = CorrectionPhase;
output.dig_level = DigitizerLevel;
output.evlen = WindowLength;

plotresult = 1;
if isfield(options,'plot')
    plotresult = options.plot;
end
    
if plotresult
    if ExperimentDimensions == 1
        figure(1); clf; pcolor(output.t_ax,output.dta_x{1},real(output.dta_avg).'); shading flat
        xlabel('time [ns]')
        ylabel('sweep axis')
                
        figure(3); clf; hold on; 
        plot(output.dta_x{1},real(output.dta_ev));
        plot(output.dta_x{1},imag(output.dta_ev),'r');
        xlabel('sweep axis')
        ylabel('echo')
        legend('Re','Im')
        xlim(output.dta_x{1}([1 end]));
        
    elseif ExperimentDimensions == 2
        figure(1); clf; pcolor(output.dta_x{1},output.dta_x{2},real(output.dta_ev).'); shading flat
        xlabel('dim 1')
        ylabel('dim 2')
        
        i2Dcut_overlay_nox({output.dta_x{1} output.dta_x{1}},output.dta_x{2},{real(output.dta_ev) imag(output.dta_ev)},2);
        xlabel('dim 1')
        ylabel('dim 2')
    end
end
end

% get data from stored data
function [dta, nAvgs, errtxt] = extractdata(savedta,estr,filename)

errtxt = '';

if isfield(savedta,'dta')
    nAvgs = savedta.nAvgs;
    dta = {double(savedta.dta)};
elseif isfield(savedta,'dta_001')
    for ii = 1:estr.avgs
        actname = ['dta_'  num2str(ii,'%03u')];
        if isfield(savedta,actname)
            dta{ii} = double(eval(['savedta.' actname]));
            % only keep it if the average is complete, unless it is the
            % first
            if sum(dta{ii}(end-estr.events{estr.det_event}.det_len:end)) == 0 && ii > 1
                dta = dta(1:end-1);
            else
                nAvgs = ii;
            end
        end
    end
else
    errtxt = ['Unable to read any data from file' filename];
    dta = [];
    nAvgs = 0;
end

end