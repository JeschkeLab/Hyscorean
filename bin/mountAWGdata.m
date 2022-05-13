function varargout = mountAWGdata(varargin)
%==========================================================================
% GUI to help mounting AWG data
%==========================================================================
% In this GUI the loaded AWG traces can be observed and manipulated at
% different steps in the loading procedure, even if traces are missing.
% For each tau-value the time-domain intensity spectrum is shown as well
% as the phase correction. Feach time point (t1,t2) the original echo data 
% and the downconverted echo with the integration window function can be
% observed.
%
% (See Hyscorean's manual for more information)
%==========================================================================
%
% Copyright (C) 2022 Julian Stropp, Hyscorean 2019
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License 3.0 as published by
% the Free Software Foundation.
%==========================================================================

gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @mountAWGdata_OpeningFcn, ...
                   'gui_OutputFcn',  @mountAWGdata_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end


% ========================================================================
function mountAWGdata_OpeningFcn(hObject, eventdata, handles, varargin)

handles.output = hObject;

% Get the data stored during the mounting procedure
handles.Data = getappdata(0,'MountedData');
handles.Filenames = getappdata(0,'FileNames');

% Initiate the Tau-selection UI menu
set(handles.tauselpopmenu,'enable','on');
set(handles.tauselpopmenu,'Value',1)
set(handles.tauselpopmenu,'String',handles.Data.TauValues);

% Initiate all UI elements
set(handles.integrationsel,'String',{'gauss','uwb_eval'});
set(handles.integrationsel,'Value',1);
set(handles.findecho_check,'Value',1);
set(handles.phase_input,'String','Default');
set(handles.echopos_input,'String','-');
set(handles.echopos_input, 'enable', 'off');
set(handles.evlen_input,'String','-');

% Show the contour plot for the selected (first) tau-value
Spectrum = real(squeeze(handles.Data.TauSignals(1,:,:)));   % get correct tau value
TimeAxis1 = handles.Data.TimeAxis1;                         % get the time axis for the spectrum
TimeAxis2 = handles.Data.TimeAxis2;
contourf(handles.surfplot,TimeAxis2/1000, TimeAxis2/1000, Spectrum,'EdgeColor', 'none');    % contour plot with no edges
xlabel(handles.surfplot,'t_2 [us]');
ylabel(handles.surfplot,'t_1 [us]');

% Show the phase correction plot in the processing plot window
index = handles.Data.dim1indexlist(handles.Data.dim1indexlist < size(TimeAxis2,1));           % indices of t1 points for first tau-value with stored echo data
plot(handles.processingplot, TimeAxis1(index)/1000, handles.Data.corr_phase(index),'.');    % point plot
xlabel(handles.processingplot,'t_1 [us]');
ylabel(handles.processingplot,'Phase correction');
handles.processplot = 'phase';

% Slider and corresponding description invisible for phase correction plot
set(handles.t1slider,'visible','off')   
set(handles.t2slider,'visible','off') 
set(handles.text3,'visible','off')
set(handles.text4,'visible','off')
% Set up slider step size and step number
dim = size(TimeAxis2,1);
set(handles.t1slider,'Min',1);
set(handles.t1slider,'Max',dim);
set(handles.t1slider, 'SliderStep',[1/(dim-1) 1/(dim-1)]);
set(handles.t2slider,'Min',1);
set(handles.t2slider,'Max',dim);
set(handles.t2slider, 'SliderStep', [1/(dim-1) 1/(dim-1)]);

% Setting up the storage of mounting details for each tau-value
numtau = size(handles.Data.TauValues,2);
handles.phase_corrtau = cell(numtau,1);
handles.evlen = cell(numtau,1);
handles.echopos = cell(numtau,1);
handles.echoaxis = cell(numtau,1);
handles.windowfunction = cell(numtau,1);
for i = 1:numtau
    handles.phase_corrtau{i} = 'Default';
    handles.evlen{i} = '-';
    handles.echopos{i} = '-';
    handles.echoaxis{i} = handles.Data.EchoAxis;
    handles.windowfunction{i} = handles.Data.WindowFunction;
end

% Update handles structure
guidata(hObject, handles);
% =========================================================================

% =========================================================================
function varargout = mountAWGdata_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;
% =========================================================================

% =========================================================================
function tauselpopmenu_Callback(hObject, eventdata, handles)
%  ------ Selection menu for tau-value to be observed and manipulated ----

tauindex = get(handles.tauselpopmenu,'Value');      % get the index of the selected tau-value

% plot contour plot of selected tau-value
Spectrum = real(squeeze(handles.Data.TauSignals(tauindex,:,:)));                
contourf(handles.surfplot,handles.Data.TimeAxis2/1000, handles.Data.TimeAxis2/1000, Spectrum, 'EdgeColor', 'none');
xlabel(handles.surfplot,'t_2 [us]');
ylabel(handles.surfplot,'t_1 [us]');

% Retrieve the mounting details of the selected tau-value for the UI elements
if handles.phase_corrtau{tauindex} == 'Default'
    set(handles.phase_input,'String','Default');
else
    set(handles.phase_input,'String',num2str(handles.phase_corrtau{tauindex}));
end
if handles.evlen{tauindex} == '-'
    set(handles.evlen_input,'String','-');
else
    set(handles.evlen_input,'String',num2str(handles.evlen{tauindex}));
end
if handles.echopos{tauindex} == '-'
    set(handles.echopos_input,'String','-');
    set(handles.echopos_input, 'enable', 'off');
    set(handles.findecho_check,'Value',1);
else
    set(handles.echopos_input,'String',num2str(handles.echopos{tauindex}));
    set(handles.echopos_input, 'enable', 'on');
    set(handles.findecho_check,'Value',0);
end

% Update processplot and UI data
processplot(handles);
guidata(hObject, handles);
return
% =========================================================================

% =========================================================================
function t2slider_Callback(hObject, eventdata, handles)
% Update processplot and UI data with changed t2 value
t2slidervalue = floor(get(hObject,'Value'));            % set it to nearest integer value
set(hObject,'Value',t2slidervalue);
processplot(handles);
guidata(hObject,handles);
return
% =========================================================================

% =========================================================================
function t1slider_Callback(hObject, eventdata, handles)
% Update processplot and UI data with changed t1 value
t1slidervalue = floor(get(hObject,'Value'));            % set it to nearest integer value
set(hObject,'Value',t1slidervalue);
processplot(handles);
guidata(hObject,handles);
return
% =========================================================================

% =========================================================================
function finishpush_Callback(hObject, eventdata, handles)
% Store the manipulated mounted data from the gui, so that Hyscorean can 
% retrieve it in mountHYSCOREdata.m and close the GUI 
setappdata(0,'MountedData',handles.Data);
uiresume();
closereq();
return
% =========================================================================

% =========================================================================
function findecho_check_Callback(hObject, eventdata, handles)
% En-/Disable echo position input depending checkbox value
echomode = get(handles.findecho_check,'Value');
if echomode
    set(handles.echopos_input, 'enable', 'off');
else
    set(handles.echopos_input, 'enable', 'on')
end
return
% =========================================================================

% =========================================================================
function reset_toggle_Callback(hObject, eventdata, handles)
% Set all mounting details to default values so that when 'process'-button
% is clicked again the tau-value is mounting as in the beginning
set(handles.phase_input,'String','Default');
set(handles.evlen_input,'String','-');
set(handles.echopos_input,'String','-');
set(handles.echopos_input, 'enable', 'off');
set(handles.findecho_check,'Value',1);
set(handles.integrationsel,'Value',1);
set(handles.reset_toggle,'value',0);
set(handles.reset_toggle,'Enable','on');
return
% =========================================================================

% =========================================================================
function remount_toggle_Callback(hObject, eventdata, handles)
% Mount the AWG data of the selected tau-value again with the chosen parameters

% Get parameters for new processing of echo data for the selected tau-value
tauindex = get(handles.tauselpopmenu,'Value');                      % get tau-value
inttype = get(handles.integrationsel,'Value');                      % integration type: with integrateEcho or uwb_eval
dimecho = handles.Data.Dimension3;
Dimension2 = size(handles.Data.TimeAxis2,1);
options.plot = 0;

% Phase correction inputs
try
    phaseinput = str2double(get(handles.phase_input,'String'));
end
if ~isnan(phaseinput)
    options.corr_phase = phaseinput;
    handles.phase_corrtau{tauindex} = phaseinput;
end

% Evaluation length inputs
try
    evlen = str2double(get(handles.evlen_input,'String'));
end
if ~isnan(evlen)
    options.evlen = evlen;
    dimecho = evlen;
    handles.evlen{tauindex} = evlen;
end

% Echo position inputs
options.find_echo = get(handles.findecho_check,'Value');
if options.find_echo == 0
    try 
        echopos = str2double(get(handles.echopos_input,'String'));
    end
    if ~isnan(echopos)
        options.echopos = echopos;
        handles.echopos{tauindex} = echopos;
    end
end

% Mount HYSCORE data for selected tauvalue again with the new parameters from the gui
if inttype == 1     % use of integrate_echo 
                     
    %Set up Butterworth IIR filter, no change to original data mounting
    FilterCutoffFrequency = handles.Data.FilterCutoffFrequency;
    FilterOrder = 2;
    [NumeratorCoefficients,DenominatorCoefficients] = butter(FilterOrder,FilterCutoffFrequency);
        
    % Evaluate each trace 
    listforselectedtau = (tauindex - 1)*Dimension2+1:tauindex*Dimension2;   % list of trace indices for selected tau
    for index = listforselectedtau
        if ismember(index,handles.Data.dim1indexlist)                       % check if there is a file available for this index
            % Use of uwb_eval to get echos + evaluation details and storing them
            OutputUWB = uwb_eval(handles.Filenames{index},options);
            handles.Data.corr_phase(index) = OutputUWB.corr_phase;
            handles.Data.evlen(index) = OutputUWB.evlen;
            handles.Data.Echopos(index) = OutputUWB.echopos;
            handles.Data.UnfilteredEchos{index} = OutputUWB.dta_avg(1:dimecho,:);
            handles.Data.AverageEchos{index} = filtfilt(NumeratorCoefficients,DenominatorCoefficients,OutputUWB.dta_avg(1:dimecho,:));
        end 
    end
    % Integration of all traces with integrateEcho.m
    DataForIntegration.AverageEcho = handles.Data.AverageEchos(listforselectedtau);
    DataForIntegration.EchoAxis = OutputUWB.t_ax(1:dimecho);
    DataForIntegration.Dimension2 = Dimension2;
    DataForIntegration.isNotIntegrated  = true;
    [IntegratedData] = integrateEcho(DataForIntegration,'gaussian',options);
    % Storing the signals of the integragtion, the window function and the echo axis 
    % (now maybe of a different length than before when all tau-values were processed together) 
    handles.Data.TauSignals(tauindex,:,:) = IntegratedData.Integral(:,:)';
    handles.windowfunction{tauindex} = IntegratedData.WindowFunction;
    handles.echoaxis{tauindex} = OutputUWB.t_ax(1:dimecho,1);
    
else        % use of uwb_eval integration
      listforselectedtau = (tauindex - 1)*Dimension2+1:tauindex*Dimension2;         %  list of trace indices for selected tau
    for index = listforselectedtau
        if ismember(index,handles.Data.dim1indexlist)                               % check if there is a file available for this index
            % Use of uwb_eval to get echos + evaluation details + integrated signals and storing them
            OutputUWB = uwb_eval(handles.Filenames{index},options);
            handles.Data.corr_phase(index) = OutputUWB.corr_phase;
            handles.Data.evlen(index) = OutputUWB.evlen;
            handles.Data.Echopos(index) = OutputUWB.echopos;
            handles.Data.UnfilteredEchos{index} = real(OutputUWB.dta_avg(1:dimecho,:));
            %handles.Data.AverageEchos(:,:,index) = OutputUWB.dta_ev;
            handles.Data.TauSignals(tauindex,index-(tauindex-1)*Dimension2,:) = OutputUWB.dta_ev;
        end
    end
    % Store echoaxis and window function from uwb_eval integration
    handles.echoaxis{tauindex} = OutputUWB.t_ax(1:dimecho);
    handles.windowfunction{tauindex} = chebwin(dimecho)*max(real(OutputUWB.dta_avg(1:dimecho,1)));
end

% Update processplot and intensity spectrum (contour plot)
processplot(handles);
Spectrum = real(squeeze(handles.Data.TauSignals(tauindex,:,:)));
contourf(handles.surfplot,handles.Data.TimeAxis2/1000, handles.Data.TimeAxis2/1000, Spectrum, 'EdgeColor', 'none');
xlabel(handles.surfplot,'t_2 [us]');
ylabel(handles.surfplot,'t_1 [us]');
guidata(hObject, handles);

%  Enable clicking process button again
% (maybe here one should disable clicking anything while data is remounted)
set(handles.remount_toggle,'value',0);
set(handles.remount_toggle,'Enable','on');
return
% =========================================================================

% =========================================================================
function plotphase_Callback(hObject, eventdata, handles)
% Shows Phase correction plot and makes sliders invisible
handles.processplot = 'phase';
processplot(handles);
guidata(hObject, handles);
set(handles.t1slider,'visible','off')
set(handles.t2slider,'visible','off')
set(handles.text3,'visible','off')
set(handles.text4,'visible','off')
return
% =========================================================================

% =========================================================================
function echoplot_Callback(hObject, eventdata, handles)
% Shows plot of echos with integration window and makes sliders visible
set(handles.t1slider,'Value',1);
set(handles.t2slider,'Value',1);
set(handles.t1slider,'visible','on')
set(handles.t2slider,'visible','on')
set(handles.text3,'visible','on')
set(handles.text4,'visible','on')
handles.processplot = 'echo';
processplot(handles);
guidata(hObject, handles);
return
% =========================================================================

% =========================================================================
function unprocessedplot_Callback(hObject, eventdata, handles)
% Shows plot with original echo and makes sliders visible
set(handles.t1slider,'Value',1);
set(handles.t2slider,'Value',1);
set(handles.t1slider,'visible','on')
set(handles.t2slider,'visible','on')
set(handles.text3,'visible','on')
set(handles.text4,'visible','on')
handles.processplot = 'unprocessed';
processplot(handles);
guidata(hObject, handles);
return
% =========================================================================

% =========================================================================
function processplot(handles)
% Function to show the processplot depending on the selected plottype and slider values
switch handles.processplot
    
    case 'phase'    % Phase correction plot
        TimeAxis1 = handles.Data.TimeAxis1;
        TimeAxis2 = handles.Data.TimeAxis2;
        % Get the indices with stored echos for the selected tau-value
        tauindex = get(handles.tauselpopmenu,'Value');
        index = handles.Data.dim1indexlist(handles.Data.dim1indexlist >(tauindex-1)*size(TimeAxis2,1));
        index = index(index < tauindex*size(TimeAxis2,1)+ 1);
        % Plot the phase vs. t1
        plot(handles.processingplot, TimeAxis1(index)/1000, handles.Data.corr_phase(index),'.');
        xlabel(handles.processingplot,'t1 [us]');
        ylabel(handles.processingplot,'Phase correction');
        xlim([0, max(TimeAxis1(index)/1000)]);
        ylim([min(handles.Data.corr_phase(index))-0.2, max(handles.Data.corr_phase(index))+0.2]);
        
    case 'echo'     % Downconverted echo plot
        % Get the index of the selected echo from tau-value and t1,t2 slider
        tauindex = get(handles.tauselpopmenu,'Value');
        t1index = get(handles.t1slider,'Value');
        t2index = get(handles.t2slider,'Value');
        dim = size(handles.Data.TimeAxis2,1);
        listinindex = (tauindex-1)*dim+t1index;
        % Check if echo is stored
        if ismember(listinindex,handles.Data.dim1indexlist)
            % If stored, plot unfiltered echo + integration window function
            plot(handles.processingplot, handles.echoaxis{tauindex}, handles.Data.UnfilteredEchos{listinindex}(:,t2index));
            hold on;
            plot(handles.processingplot, handles.echoaxis{tauindex}, handles.windowfunction{tauindex},'Color','r');
            hold off;
        else
            % If not, plot baseline
            plot(handles.processingplot, handles.echoaxis{tauindex}, zeros(size(handles.echoaxis{tauindex})));
        end
        xlabel(handles.processingplot,'t [ns]');
        ylabel(handles.processingplot,'Intensity');
        xlim([min(handles.echoaxis{tauindex}), max(handles.echoaxis{tauindex})]);
        
    case 'unprocessed'  % Plot of original echo
        % Get the index of the selected echo from tau-value and t1,t2 slider
        tauindex = get(handles.tauselpopmenu,'Value');
        t1index = get(handles.t1slider,'Value');
        t2index = get(handles.t2slider,'Value');
        dim = size(handles.Data.TimeAxis2,1);
        xaxisdta = handles.Data.EchoAxisfordta;
        listinindex = (tauindex-1)*dim+t1index;
        % Check if echo is stored
        if ismember(listinindex,handles.Data.dim1indexlist)
            % If stored, plot original echo data + echo position and evaluation length
            plot(handles.processingplot, xaxisdta, real(handles.Data.dta{listinindex}(:,t2index)));
            hold on;
            xechopos = xaxisdta(handles.Data.Echopos((tauindex-1)*dim+t1index));
            xevlen = xaxisdta(handles.Data.evlen((tauindex-1)*dim+t1index));
            plot(xechopos, 0, '.', 'MarkerSize', 30);
            plot([xechopos - xevlen/2, xechopos + xevlen/2],[0 0],'-','Linewidth',2,'Color','black');
            xlabel(handles.processingplot,'t [ns]');
            ylabel(handles.processingplot,'Intensity');
            xlim([min(handles.Data.EchoAxisfordta),max(handles.Data.EchoAxisfordta)]);
            hold off;
        else
            % If not, plot baseline
            plot(handles.processingplot,xaxisdta,zeros(size(xaxisdta)));
            xlabel(handles.processingplot,'t [ns]');
            ylabel(handles.processingplot,'Intensity');
            xlim([min(handles.Data.EchoAxisfordta),max(handles.Data.EchoAxisfordta)]);
            hold off;
        end
end
return
% =========================================================================
