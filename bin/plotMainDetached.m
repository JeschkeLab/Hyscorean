function plotMainDetached(handles)

set(gcf,'NumberTitle','off','Name','TrierAnalysis: Main Plot','Units','pixels');
if get(handles.apt2dbutton,'Value')
  rmin = str2double(get(handles.APT_rmin,'string'));
  rmax = str2double(get(handles.APT_rmax,'string'));
  options.xaxs = [rmin rmax]; options.yaxs = [rmin rmax];
  options.xlabel = 'r_1 [nm]'; options.ylabel = 'r_2 [nm]';
else
  upperLimit=str2double(get(handles.Limit2,'string'));
  lowerLimit=str2double(get(handles.Limit1,'string'));
  options.xaxs = [lowerLimit upperLimit]; options.yaxs = [lowerLimit upperLimit];
  options.xlabel = '\nu_1 [MHz]'; options.ylabel = '\nu_2 [MHz]';
end
options.levels=handles.GraphicalSettings.Levels;
options.Linewidth=handles.GraphicalSettings.Linewidth;
options.nonewfig = true;
switch handles.GraphicalSettings.Colormap
  case 1
    colormap('parula')
  case 2
    colormap('jet')
  case 3
    colormap('hsv')
  case 4
    colormap('hot')
  case 5
    colormap('cool')
  case 6
    colormap('spring')
  case 7
    colormap('summer')
  case 8
    colormap('autumn')
  case 9
    colormap('winter')
  case 10
    colormap('gray')
end
if handles.GraphicalSettings.Absolute
  spectrum2 = abs(handles.Processed.spectrum);
elseif handles.GraphicalSettings.Real
  spectrum2 = abs(handles.Processed.spectrum);
elseif handles.GraphicalSettings.Imaginary
  spectrum2 = imag(handles.Processed.spectrum);
end
correlation_plot(handles.Processed.axis2,handles.Processed.axis1,spectrum2,options)