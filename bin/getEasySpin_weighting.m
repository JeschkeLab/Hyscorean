function  [Weights,Saved] = getEasySpin_weighting(Axis1,Axis2,ExpSpecScaled,CustomColormap,AxLim)

Saved = false;
figureHandle = figure(98123);
set(figureHandle,'Units','normalized','Position',[0.3156 0.2942 0.5646 0.4508])
XAxis = Axis1;
YAxis = Axis2;
Weights = 1 + 0*ExpSpecScaled;
ExperimentalSpec = ExpSpecScaled;

%Axis for main display
AxesHandle = axes('Parent',figureHandle,'Units','normalized',...
  'Position',[0.08 0.15 0.9 0.8],'FontSize',8,'Layer','top');
hold(AxesHandle,'on')

[pcolorhandle] = pcolor(AxesHandle,XAxis,YAxis,Weights);
CustomColormap = (fliplr(CustomColormap')');
colormap(pcolorhandle.Parent,CustomColormap)
shading(pcolorhandle.Parent,'interp')
caxis(pcolorhandle.Parent,[0 2])
contour(AxesHandle,XAxis,YAxis,ExperimentalSpec,80,'k');
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

 function mouseclick_callback(gcbo,eventdata)
      cP = get(gca,'Currentpoint');
      x = cP(1,1);
      y = cP(1,2);
      pos1 = find(XAxis>=round(x,1));
      pos2= (find(YAxis>=round(y,1)));
            pos1 = pos1(1);
      pos2 = pos2(1);
      switch get(gcf,'SelectionType')
          case 'normal' % Click left mouse button.
              Sign = +1;
          case 'alt'    % Control - click left mouse button or click right mouse button.
              Sign = -1;
          case 'extend' % Shift - click left mouse button or click both left and right mouse buttons.
              Sign = +10;
        otherwise
          Sign = 0;
      end
      GaussianWidth = get(findobj('Tag','GaussianSlider'),'Value');
      if iscell(GaussianWidth)
      GaussianWidth = GaussianWidth{1};
      end
      Zadd = gaussian(XAxis,x,GaussianWidth*max(XAxis))'.*gaussian(YAxis,y,GaussianWidth*max(YAxis));
      Zadd = Zadd/max(max(Zadd));
      Weights  = Weights + 0.5*Sign*Zadd';
      Weights(Weights>2) =2;
      Weights(Weights<0) = 0;
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
  close(figureHandle)
 end
 function SaveCallback(gcbo,eventdata)
   Saved = true;
  close(figureHandle)
 end
% now attach the function to the axes
set(pcolorhandle,'ButtonDownFcn', @mouseclick_callback)
% and we also have to attach the function to the children, in this
% case that is the line in the axes.
set(get(gca,'Children'),'ButtonDownFcn', @mouseclick_callback)

waitfor(figureHandle)
Weights(Axis1==-abs(Axis1),:) = fliplr(fliplr(Weights(Axis1==abs(Axis1),:)')');


end