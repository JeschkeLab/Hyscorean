function  [Weights,Saved] = getEasySpin_weighting(InputWeights,Axis1,Axis2,ExpSpecScaled,CustomColormap,AxLim)
%==========================================================================
% Hyscorean Weighting Map
%==========================================================================
% This function creates the interactive map for defining the weighting 
% function to be applied on the experimental spectra of the fitting module. 
%
% (see Hyscorean manual for further information)
%==========================================================================
%
% Copyright (C) 2019  Luis Fabregas, Hyscorean 2019
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License 3.0 as published by
% the Free Software Foundation.
%==========================================================================

%--------------------------------------------------------------------------
% Create figure
%--------------------------------------------------------------------------

%Check if another instance is open, close it and create new one
figureHandle = findobj('Tag','esfitWeightingMap_figure');
if isempty(figureHandle)
  figureHandle = figure('Tag','esfitWeightingMap_figure','WindowStyle','normal','NumberTitle','off','Name','Hyscorean: Weighting Map');
else
  figure(figureHandle);
  clf(figureHandle);
end

%Use Hyscorean window logo
warning('off','all')
Path =  fileparts(which('Hyscorean'));
jFrame=get(figureHandle,'javaframe');
jicon=javax.swing.ImageIcon(fullfile(Path, 'bin', 'logo.png'));
jFrame.setFigureIcon(jicon);
warning('on','all')

%Position new figure relative to fitting module
hFig = findobj('Tag','esfitFigure_hyscorean');
ScreenSize = get(0,'ScreenSize'); %Get screensize
Position = hFig.Position;
Position(1) = Position(1)/ScreenSize(3) + 0.02;
Position(2) = Position(2)/ScreenSize(4) + 0.02;
Position(3) = 0.5646;
Position(4) = 0.4508;

%Set correct normalized size
set(figureHandle,'Units','normalized','Position',Position,...
                 'DockControls','off','MenuBar','none')

%--------------------------------------------------------------------------
% Create app
%--------------------------------------------------------------------------

%Inititialize variables
Saved = false;
XAxis = Axis1;
YAxis = Axis2;
Weights = InputWeights;
ExperimentalSpec = ExpSpecScaled;

%Axis for main display
AxesHandle = axes('Parent',figureHandle,'Units','normalized',...
  'Position',[0.05 0.17 0.92 0.75],'FontSize',8,'Layer','top');
hold(AxesHandle,'on')

%Colormap for weights
[pcolorhandle] = pcolor(AxesHandle,XAxis,YAxis,Weights);
CustomColormap = (fliplr(CustomColormap')');
colormap(pcolorhandle.Parent,CustomColormap)
shading(pcolorhandle.Parent,'interp')
caxis(pcolorhandle.Parent,[0 2])

%Experimental contour plot
contour(AxesHandle,XAxis,YAxis,ExperimentalSpec,80,'k');

%Configurate axes
set(pcolorhandle.Parent,'xlim',[-AxLim AxLim])
set(pcolorhandle.Parent,'ylim',[0 AxLim])
xlabel('\nu_1 [MHz]')
ylabel('\nu_2 [MHz]')
plot(AxesHandle,Axis1,abs(Axis1),'k--')
plot(AxesHandle,0*Axis1,abs(Axis1),'k-')
grid(AxesHandle,'on')
box(AxesHandle,'on')
set(AxesHandle,'ytick',xticks,'FontSize',9)
colorbar 


%Construct UI elements
x0 = -0.15;
y0 = -0.005;
uicontrol('Style','pushbutton',...
  'Units','normalized',...
  'Position',[x0+0.54 y0+0.03 0.07 0.05],...
  'BackgroundColor',get(gcf,'Color'),...
  'String','Symmetrize',...
  'FontSize',9,...
  'HorizontalAl','left','Callback',@symmetrizeCallback);

uicontrol('Style','pushbutton',...
  'Units','normalized',...
  'Position',[x0+0.61 y0+0.03 0.07 0.05],...
  'BackgroundColor',get(gcf,'Color'),...
  'String','Reset',...
  'FontSize',9,...
  'HorizontalAl','left','Callback',@setAllOnes);

uicontrol('Style','pushbutton',...
  'Units','normalized',...
  'Position',[x0+0.68 y0+0.03 0.07 0.05],...
  'BackgroundColor',get(gcf,'Color'),...
  'String','Remove all',...
  'FontSize',9,...
  'HorizontalAl','left','Callback',@setAllZeroes);

uicontrol('Style','pushbutton',...
  'Units','normalized',...
  'Position',[0.11 0.03 0.07 0.05],...
  'BackgroundColor',get(gcf,'Color'),...
  'String','Save',...
  'FontSize',9,...
  'HorizontalAl','left','Callback',@SaveCallback);

uicontrol('Style','pushbutton',...
  'Units','normalized',...
  'Position',[0.18 0.03 0.07 0.05],...
  'BackgroundColor',get(gcf,'Color'),...
  'String','Cancel',...
  'FontSize',9,...
  'HorizontalAl','left','Callback',@CancelCallback);

uicontrol('Style','slider',...
  'Units','normalized',...
  'Position',[0.81 0.03 0.15 0.04],...
  'Tag','GaussianSlider',...
  'BackgroundColor',get(gcf,'Color'),...
  'Min',0.01,'Max',0.25,'Value',0.05);

uicontrol('Style','text',...
  'Units','normalized',...
  'String','Width',...
  'FontSize',9,...
  'Position',[0.77 0.025 0.04 0.04],...
  'BackgroundColor',get(gcf,'Color'));

x0 = 0.05;
uicontrol('Style','edit',...
  'Units','normalized',...
  'Position',[x0+0.68 0.03 0.04 0.04],...
  'Tag','GaussianEdit',...
  'String',0.5,...
  'BackgroundColor',get(gcf,'Color'),...
  'Min',0.01,'Max',0.25,'Value',0.05);

uicontrol('Style','text',...
  'Units','normalized',...
  'String','Increment',...
  'FontSize',9,...
  'Position',[x0+0.62 0.025 0.06 0.04],...
  'BackgroundColor',get(gcf,'Color'));


%--------------------------------------------------------------------------
% Callbacks
%--------------------------------------------------------------------------

 function mouseclick_callback(gcbo,eventdata)
      
      %Get current position of pointer on screen and axes
      PointerPosition = get(gca,'Currentpoint');
      x = PointerPosition(1,1);
      y = PointerPosition(1,2);
      pos1 = find(XAxis>=round(x,1));
      pos2= (find(YAxis>=round(y,1)));
            pos1 = pos1(1);
      pos2 = pos2(1);
      %Check type of mouse signal
      switch get(gcf,'SelectionType')
          case 'normal' % Left click
              Sign = +1;
          case 'alt'    % Control-left click or right click
              Sign = -1;
          case 'extend' % Shift-click left click
              Sign = +10;
        otherwise
          Sign = 0;
      end
      
      %Compute updated weights map
      GaussianWidth = get(findobj('Tag','GaussianSlider'),'Value');
      if iscell(GaussianWidth)
      GaussianWidth = GaussianWidth{1};
      end
      Increment = str2double(get(findobj('Tag','GaussianEdit'),'String'));
      WeightsAdd = gaussian(XAxis,x,GaussianWidth*max(XAxis))'.*gaussian(YAxis,y,GaussianWidth*max(YAxis));
      WeightsAdd = WeightsAdd/max(max(WeightsAdd));
      Weights  = Weights + Increment*Sign*WeightsAdd';
      Weights(Weights>2) =2;
      Weights(Weights<0) = 0;
      %Before exiting map the weights map on the hidden quadrants
      Weights(Axis1==-abs(Axis1),:) = fliplr(fliplr(Weights(Axis1==abs(Axis1),:)')');

      %Update graphics
      set(pcolorhandle,'Cdata',Weights,'visible','on')
 end

 function symmetrizeCallback(gcbo,eventdata)
   Weights = (Weights'.*Weights).^0.5;
   tmp = fliplr(Weights);
   Weights = fliplr(tmp'.*tmp).^0.5;
  set(pcolorhandle,'Cdata',Weights,'visible','on')
 end
 function setAllOnes(gcbo,eventdata)
  Weights = Weights*0 + 1;
  set(pcolorhandle,'Cdata',Weights,'visible','on')
 end
 function setAllZeroes(gcbo,eventdata)
  Weights = Weights*0;
  set(pcolorhandle,'Cdata',Weights,'visible','on')
 end
function CancelCallback(gcbo,eventdata)
  if all(Weights==0)
    messageBox = msgbox('Warning: All of the spectrum is weighted by zero.','modal');
    waitfor(messageBox)
  end
  close(figureHandle)
end
function SaveCallback(gcbo,eventdata)
  Saved = true;
  if all(Weights==0)
    messageBox = msgbox('Warning: All of the spectrum is weighted by zero.','modal');
    waitfor(messageBox)
  end
  close(figureHandle)
end

%--------------------------------------------------------------------------
% Mouse Functionality Attachment
%--------------------------------------------------------------------------

set(pcolorhandle,'ButtonDownFcn', @mouseclick_callback)
set(get(gca,'Children'),'ButtonDownFcn', @mouseclick_callback)

%Wait for figure to be closed
waitfor(figureHandle)

end