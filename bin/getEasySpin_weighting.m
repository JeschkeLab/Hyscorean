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

%Set correct normalized size
set(figureHandle,'Units','normalized','Position',[0.3156 0.2942 0.5646 0.4508])

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
  'Position',[0.08 0.15 0.9 0.8],'FontSize',8,'Layer','top');
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
set(AxesHandle,'ytick',xticks,'FontSize',11)
colorbar 

%Construct UI elements
uicontrol('Style','pushbutton',...
  'Units','normalized',...
  'Position',[0.61 0.03 0.07 0.04],...
  'BackgroundColor',get(gcf,'Color'),...
  'String','Reset',...
  'HorizontalAl','left','Callback',@setAllOnes);

uicontrol('Style','pushbutton',...
  'Units','normalized',...
  'Position',[0.68 0.03 0.07 0.04],...
  'BackgroundColor',get(gcf,'Color'),...
  'String','Remove all',...
  'HorizontalAl','left','Callback',@setAllZeroes);

uicontrol('Style','pushbutton',...
  'Units','normalized',...
  'Position',[0.11 0.03 0.07 0.04],...
  'BackgroundColor',get(gcf,'Color'),...
  'String','Save',...
  'HorizontalAl','left','Callback',@SaveCallback);

uicontrol('Style','pushbutton',...
  'Units','normalized',...
  'Position',[0.18 0.03 0.07 0.04],...
  'BackgroundColor',get(gcf,'Color'),...
  'String','Cancel',...
  'HorizontalAl','left','Callback',@CancelCallback);

uicontrol('Style','slider',...
  'Units','normalized',...
  'Position',[0.80 0.03 0.15 0.04],...
  'Tag','GaussianSlider',...
  'BackgroundColor',get(gcf,'Color'),...
  'Min',0,'Max',0.25,'Value',0.05);

uicontrol('Style','text',...
  'Units','normalized',...
  'String','Width',...
  'Position',[0.75 0.02 0.05 0.04],...
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
      WeightsAdd = gaussian(XAxis,x,GaussianWidth*max(XAxis))'.*gaussian(YAxis,y,GaussianWidth*max(YAxis));
      WeightsAdd = WeightsAdd/max(max(WeightsAdd));
      Weights  = Weights + 0.5*Sign*WeightsAdd';
      Weights(Weights>2) =2;
      Weights(Weights<0) = 0;
      
      %Update graphics
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
%Before closing map the weights map on the hidden quadrants
Weights(Axis1==-abs(Axis1),:) = fliplr(fliplr(Weights(Axis1==abs(Axis1),:)')');


end