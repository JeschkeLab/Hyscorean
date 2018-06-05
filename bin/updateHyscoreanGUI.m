function updateHyscoreanGUI(handles,Processed)

    set(handles.ProcessingInfo, 'String', 'Status: Rendering...'); drawnow;


set(handles.PreProcessedTrace,'visible','on')
set(handles.NonCorrectedTrace,'visible','on')
set(handles.PlotApodizationWindow,'visible','on')
set(handles.DetachSignalPlot,'visible','on')
set(handles.ChangeSignalPlotDimension,'visible','on')
set(handles.t1_Slider,'enable','on')

set(handles.PreProcessedTrace,'BackgroundColor','white')
set(handles.NonCorrectedTrace,'BackgroundColor','white')
set(handles.PlotApodizationWindow,'BackgroundColor','white')
set(handles.DetachSignalPlot,'BackgroundColor','white')


Processed.TimeAxis1 = linspace(0,handles.Data.TimeStep1*size(Processed.Signal,1),size(Processed.Signal,1));
Processed.TimeAxis2 = linspace(0,handles.Data.TimeStep2*size(Processed.Signal,2),size(Processed.Signal,2));
%activate sliders
Npoints = length(Processed.TimeAxis2) - str2double(get(handles.ZeroFilling2,'string'));
set(handles.t1_Slider,'Min', 1, 'Max',Npoints , 'SliderStep', [1/(Npoints - 1) 5/(Npoints - 1)], 'Value', 1)
handles.PlotProcessedSignal = true;
try
HyscoreanSignalPlot(handles,Processed);
catch
end

spectrum = Processed.spectrum;
axis1 = Processed.axis1;
axis2 = Processed.axis2;

  XupperLimit = str2double(get(handles.XUpperLimit,'string'));
  XlowerLimit = -XupperLimit;
  YupperLimit = XupperLimit;
  YlowerLimit = 0;

  GraphicalSettings = handles.GraphicalSettings;
%Levels for contour plot
levels=GraphicalSettings.Levels;

if GraphicalSettings.Absolute
  spectrum = abs(spectrum);
  
elseif GraphicalSettings.Real
  spectrum = abs(spectrum);

elseif GraphicalSettings.Imaginary
  spectrum = imag(spectrum);


end
  
  
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

if get(handles.ImposeBlindSpots,'Value')
[BlindSpotsMap,BlindSpotsAxis1,BlindSpotsAxis2] = imposeBlindSpots(handles);  
BlindSpotsMap = BlindSpotsMap/max(max(BlindSpotsMap))*max(max(spectrum)); colormap('hot')
BlindSpots = pcolor(handles.mainPlot,BlindSpotsAxis1,BlindSpotsAxis2,BlindSpotsMap);shading(handles.mainPlot,'flat'),
alpha(BlindSpots,0.7);
hold(handles.mainPlot,'on')
end

switch GraphicalSettings.PlotType
  case 1
    if get(handles.ImposeBlindSpots,'Value')
  MainContour = contour(handles.mainPlot,axis1,axis2,spectrum,ContourLevels,'LineWidth',GraphicalSettings.Linewidth,'Color','k');
    else
   MainContour = contour(handles.mainPlot,axis1,axis2,spectrum,ContourLevels,'LineWidth',GraphicalSettings.Linewidth);
    end
  case 2
  MainContour = contourf(handles.mainPlot,axis1,axis2,spectrum,ContourLevels);
%   set(MainContour,'LineWidth',GraphicalSettings.Linewidth)
  case 3
  pcolor(handles.mainPlot,axis1,axis2,spectrum),shading(handles.mainPlot,'interp')
end

hold(handles.mainPlot,'on')
lineAxis = linspace(-XupperLimit,XupperLimit,1000);
handles.Diagonals = plot(handles.mainPlot,lineAxis,abs(lineAxis),'k-.');
set(handles.mainPlot,'LineWidth',0.5)
handles.VerticalLine = plot(handles.mainPlot,zeros(length(lineAxis)),abs(lineAxis),'k-','LineWidth',0.5);
set(handles.mainPlot,'LineWidth',1)

hold(handles.mainPlot,'off')



grid(handles.mainPlot,'on')
set(handles.mainPlot,'ylim',[YlowerLimit YupperLimit],'xlim',[XlowerLimit XupperLimit])
  xlabel(handles.mainPlot,'\nu_1 [MHz]');
  ylabel(handles.mainPlot,'\nu_2 [MHz]');
  
  xt = xticks(handles.mainPlot);
yticks(handles.mainPlot,xt(xt>=0))
  
if isfield(handles,'AddedLines')
  for i=1:length(handles.AddedLines)
    hold(handles.mainPlot,'on')
    plot(handles.mainPlot,handles.AddedLines{i}.x,handles.AddedLines{i}.y,'k-.','LineWidth',0.5)
    hold(handles.mainPlot,'off')
  end
end
if isfield(handles,'AddedTags')
  for i=1:length(handles.AddedTags)
            text(handles.AddedTags{i}.x,handles.AddedTags{i}.y,handles.AddedTags{i}.Tag,'FontSize',14)
  end
end



set(handles.ProcessingInfo, 'String', 'Status: Finished');