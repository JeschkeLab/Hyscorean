function createReport(handles)

%Construct data-structure for ReportGenerator
reportdata.savename = handles.savename;
reportdata.filename = handles.filename;
reportdata.path = handles.path;
reportdata.sym2DFT = get(handles.sym2DFT,'value');
reportdata.RawTimeAxis1 = handles.Data.TimeAxis1;
reportdata.RawTimeAxis2 = handles.Data.TimeAxis2;
reportdata.FittingTime = str2double(get(handles.IntegrationTime,'string'));
reportdata.FittingTime = str2double(get(handles.IntegrationTime,'string'));
reportdata.DDS = str2double(get(handles.DDS,'string'));
reportdata.rmin = str2double(get(handles.APT_rmin,'string'));
reportdata.rmax = str2double(get(handles.APT_rmax,'string'));
reportdata.tauFactor1 = str2double(get(handles.L2G_tau,'string'));
reportdata.sigmaFactor1 = str2double(get(handles.L2G_sigma,'string'));
reportdata.zerofilling1 = str2double(get(handles.ZeroFilling1,'string'));
reportdata.tauFactor2 = str2double(get(handles.L2G_tau2,'string'));
reportdata.sigmaFactor2 = str2double(get(handles.L2G_sigma2,'string'));
reportdata.zerofilling1 = str2double(get(handles.ZeroFilling1,'string'));
reportdata.zerofilling2 = str2double(get(handles.ZeroFilling2,'string'));
reportdata.HammingDecay = str2double(get(handles.Hammingedit,'string'));
reportdata.Tau1 = max(handles.Processed.TimeAxis1)*reportdata.tauFactor1;
reportdata.Sigma1 = reportdata.sigmaFactor1/reportdata.Tau1 ;
reportdata.Tau2 = max(handles.Processed.TimeAxis2)*reportdata.tauFactor2;
reportdata.Sigma2 = reportdata.sigmaFactor2/reportdata.Tau2 ;
reportdata.Processed = handles.Processed;
%reportdata.levels = str2double(get(handles.LevelsEdit,'string'));
reportdata.boxcar= get(handles.BoxcarButton,'Value');
reportdata.BackgroundMethod2 = get(handles.BackgroundMethod2,'Value');
reportdata.BackgroundMethod1 = get(handles.BackgroundMethod1,'Value');
reportdata.BackgroundParameter1 = str2double(get(handles.BackgroundParameter1,'string'));
reportdata.BackgroundParameter2 = str2double(get(handles.BackgroundParameter2,'string'));
reportdata.BackgroundCorrection2D = 0;
reportdata.ZeroTimeTruncation = get(handles.ZeroTimeTruncation,'Value');
reportdata.InvertCorrection = get(handles.InvertCorrection,'Value');
reportdata.method= handles.tags.method;
reportdata.DDS = str2double(get(handles.DDS,'string'));
reportdata.rmin = str2double(get(handles.APT_rmin,'string'));
reportdata.rmax = str2double(get(handles.APT_rmax,'string'));
reportdata.SavitzkyGolayFrameLength = str2double(get(handles.FrameLength,'string'));
reportdata.SavitzkyGolayOrder = str2double(get(handles.FilterOrder,'string'));
reportdata.SavitzkyGolayFilter = get(handles.SavitzkyFilter,'Value');
if get(handles.apt2dbutton,'Value')
  reportdata.lim1 = reportdata.rmin;
  reportdata.lim2 = reportdata.rmax;
else
  reportdata.lim1 = str2double(get(handles.Limit1,'string'));
  reportdata.lim2 = str2double(get(handles.Limit2,'string'));
end
reportdata.GraphicalSettings = handles.GraphicalSettings;
reportdata.HammingWindow = get(handles.HammingWindow,'Value');
reportdata.ChebishevWindow = get(handles.ChebishevWindow,'Value');


if ishandle(3000)
  reportdata.PlotCorrectedBackground = 1;
end 

if isfield(handles,'ExperimentParameters')
  reportdata.ExperimentParameters = handles.ExperimentParameters;
  reportdata.PlotPulses= handles.PlotPulses;
end


if isfield(handles,'RegularizationParameters')
  reportdata.RegularizationParameters = handles.RegularizationParameters;
end



%Send structure to workspace
assignin('base', 'reportdata', reportdata);

%Cosntruct report
 report TrierAnalysis_report -fpdf;