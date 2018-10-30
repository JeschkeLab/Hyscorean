function  projectionPlots(handles,spectrum,axis1,axis2,lim1,lim2)

GraphicalSettings = handles.GraphicalSettings;
%Levels for contour plot
levels=GraphicalSettings.Levels;

if GraphicalSettings.Absolute
  spectrum2 = abs(spectrum);
  inset1 = sum(abs(spectrum));
  inset2 = sum(abs(spectrum'));
  inset1 = max(abs(spectrum));
  inset2 = max(abs(spectrum'));
  
elseif GraphicalSettings.Real
  spectrum2 = abs(spectrum);
  inset1 = sum(real(spectrum));
  inset2 = sum(real(spectrum'));
%   inset1 = max(abs(spectrum));
%   inset2 = max(abs(spectrum'));
elseif GraphicalSettings.Imaginary
  spectrum2 = imag(spectrum);
  inset1 = sum(imag(spectrum));
  inset2 = sum(imag(spectrum'));
  inset1 = max(abs(spectrum));
  inset2 = max(abs(spectrum'));
end

% Get data for inset
inset1 = inset1/max(inset1);
inset2 = inset2/max(inset2);

% Plot inset #1
plot(handles.Inset1,axis1,inset1,'k','LineWidth',GraphicalSettings.Linewidth)
set(handles.Inset1,'xtick',[],'ytick',[],'ylim',[min(inset1) 1.05],'xlim',[lim1 lim2]);
% Plot inset #2
plot(handles.Inset2,axis2,inset2,'k','LineWidth',GraphicalSettings.Linewidth)
set(handles.Inset2,'xtick',[],'ytick',[],'ylim',[min(inset2) 1.05],'xlim',[lim1 lim2],'view',[90 270]);
% Plot 2D-data
switch GraphicalSettings.Colormap
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

  MinimalContourLevel = str2double(get(handles.MinimalContourLevel,'string'));
  MaximalContourLevel = max(max(abs(Processed.spectrum)));
  MinimalContourLevel = MaximalContourLevel*MinimalContourLevel/100;
  ContourLevelIncrement = (MaximalContourLevel - MinimalContourLevel)/levels;
  ContourLevels = MinimalContourLevel:ContourLevelIncrement:MaximalContourLevel;


switch GraphicalSettings.PlotType
  case 1
  contour(handles.main,axis1,axis2,spectrum2,ContourLevels,levels,'LineWidth',GraphicalSettings.Linewidth);
  case 2
  contourf(handles.main,axis1,axis2,spectrum2,ContourLevels,levels)
  set(handles.main,'LineWidth',GraphicalSettings.Linewidth)
  case 3
  pcolor(handles.main,axis1,axis2,spectrum2),shading(handles.main,'interp')
end

set(handles.main,'ylim',[lim1 lim2],'xlim',[lim1 lim2])


if get(handles.apt2dbutton,'Value')
  xlabel(handles.main,'r_1 [nm]');
  ylabel(handles.main,'r_2 [nm]');
else
  xlabel(handles.main,'\nu_1 [MHz]');
  ylabel(handles.main,'\nu_2 [MHz]');
end
end