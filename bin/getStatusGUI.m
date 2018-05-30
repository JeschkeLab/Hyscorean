function [ToolBox] = getStatusGUI(handles)

%Get status of tags
ToolBox.BoxcarIntegration = get(handles.BoxcarButton,'Value');
ToolBox.GaussIntegration = get(handles.GaussIntegration,'Value');
ToolBox.ExperimentalData = get(handles.Experimental,'Value');
ToolBox.SimulatedData = get(handles.SimulationTag,'Value');
ToolBox.Method2DFT = get(handles.ft2dbutton,'Value');
ToolBox.MethodSym2DFT = get(handles.sym2DFT_Button,'Value');
ToolBox.Method2DAPT = get(handles.apt2dbutton,'Value');



%Get status of edit boxes
ToolBox.FittingTime = str2double(get(handles.IntegrationTime,'string'));
ToolBox.DDS = str2double(get(handles.DDS,'string'));
ToolBox.rmin = str2double(get(handles.APT_rmin,'string'));
ToolBox.rmax = str2double(get(handles.APT_rmax,'string'));
ToolBox.tauFactor = str2double(get(handles.L2G_tau,'string'));
ToolBox.sigmaFactor = str2double(get(handles.L2G_sigma,'string'));
ToolBox.ZeroFilling1 = str2double(get(handles.ZeroFilling1,'string'));
ToolBox.ZeroFilling2 = str2double(get(handles.ZeroFilling2,'string'));
ToolBox.HammingDecay = str2double(get(handles.Hammingedit,'string'));