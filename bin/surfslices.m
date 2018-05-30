function surfslices(x1,x2,x3,y3d,options)
% Creates a plot that lets you slide trough your 3 dimensional data.
% various calls exist to this function

if ~exist('y3d','var')
    % move first argument to y2d
    y3d = x1;
%     % check for second argument
%     if exist('x2','var')
%         if length(x2) == 1
%             fignum = x2;
%         else
%             error('For the minimalistic call, the second argument is the figure number')
%         end
%     end
    x1 = 1:size(y3d,1);
    x2 = 1:size(y3d,2);
    x3 = 1:size(y3d,3);
end

if exist('fignum','var')
    if isstruct(fignum)
        options = fignum;
        if isfield(options,'fignum') && ~isempty(options.fignum)
            figure(options.fignum)
        else
            figure
        end
    else
        figure(fignum)
        options = [];
    end
else
    figure
    options = [];
end

clf


if nargin<5 || ~isfield(options,'type') || isempty(options.type)
    y3d = abs(y3d);
elseif strcmp(options.type,'abs')
    y3d = abs(y3d);
elseif strcmp(options.type,'real')
    y3d = real(y3d);
elseif strcmp(options.type,'imag')
    y3d = imag(y3d);
end


if isfield(options,'normalize')  && options.normalize == 1 
 norm = max(max(max(y3d)));
 y3d = y3d/norm;
end

surf(x2,x1,squeeze(y3d(:,:,1)));
shading flat

if isfield(options,'ylabel') && ~isempty(options.ylabel)
    ylabel(options.ylabel)
    setappdata(gca,'ylabel',options.ylabel);
else
    setappdata(gca,'ylabel',[]);
end

if isfield(options,'xlabel') && ~isempty(options.xlabel)
    xlabel(options.xlabel)
    setappdata(gca,'xlabel',options.xlabel);
else
    setappdata(gca,'xlabel',[]);
end

for ii=1:length(x3)
%     setappdata(gca,['dta' num2str(ii)],contourc(squeeze(y3d(:,:,ii))));
    setappdata(gca,['dta' num2str(ii)],(squeeze(y3d(:,:,ii))));
    % todo: adapt contour levels
end

maxval = max(max(max((y3d))));
minval = min(min(min((y3d))));
zlims= [minval maxval];
set(gca,'ZLim',zlims);
setappdata(gca,'x1',x1);
setappdata(gca,'x2',x2);
setappdata(gca,'x3',x3);
setappdata(gca,'XLim',get(gca,'XLim'))
setappdata(gca,'YLim',get(gca,'YLim'))
setappdata(gca,'ZLim',get(gca,'ZLim'))
setappdata(gca,'view',get(gca,'View'))
% ctlh.linedat = y2d;

% get handles and set figure props
fh = gcf;
ah = gca;

% This avoids flickering when updating the axis
set(fh,'doublebuffer','on');

% Generate constants for use in uicontrol initialization
pos=get(ah,'position');



% y text
ytext.pos = [pos(1)+pos(3)+0.005 pos(2) 0.06 0.05];
ytext.h = uicontrol(fh,'style','text', ...
    'units','normalized','position',ytext.pos,'String',num2str(x3(1)), ...
    'BackgroundColor',get(fh,'color'));
setappdata(gca,'ytext',ytext.h);

% yslide
yslide.pos=[pos(1)+pos(3)+0.02 pos(2)+0.1 0.03 pos(4)-0.2];
yslide.min = 1;
yslide.npts = 1000; % axis window dx by number of points
yslide.max = length(x3); % allows for overscaling
yslide.steps = length(x3)-1;

try
yslide.h=uicontrol(fh,'style','slider',...
    'units','normalized','position',yslide.pos,...
    'callback',@scroller,'min',yslide.min,'max',yslide.max,'SliderStep',[1 1]./yslide.steps,'value',1);

addlistener(yslide.h,'ContinuousValueChange',@scroller);
setappdata(gca,'yslide',yslide.h);
catch
end
zoomer=zoom;
zoomer.ActionPostCallback = @zoomcallback;

roter = rotate3d;
roter.ActionPostCallback = @rotatecallback;

setappdata(gca,'zoomer',zoomer.ActionPostCallback);
setappdata(gca,'roter',roter.ActionPostCallback);


set(gcf,'Toolbar','figure')

end

function scroller(obj,evd)
 xr = get(gca,'XLim');
 yr = get(gca,'YLim');
 zr = get(gca,'ZLim');
 
surf(getappdata(gca,'x2'),getappdata(gca,'x1'),getappdata(gca,['dta' num2str(floor(get(getappdata(gca,'yslide'),'value')))]))
shading flat
zoom reset
% set(gca,'YLim',getappdata(gca,'YLim'));
% set(gca,'XLim',getappdata(gca,'XLim'));
% set(gca,'ZLim',getappdata(gca,'ZLim'));
 set(gca,'YLim',yr);
 set(gca,'XLim',xr);
 set(gca,'ZLim',zr);
 xlabel(getappdata(gca,'xlabel'));
 ylabel(getappdata(gca,'ylabel'));
set(gca,'View',getappdata(gca,'view'));

set(getappdata(gca,'ytext'),'String',num2str(subsref(getappdata(gca,'x3'),struct('type','()','subs',{{(floor(get(getappdata(gca,'yslide'),'value')))}}))));
end


function zoomcallback(obj,evd)
set(gca,'View',getappdata(gca,'view'));
% setappdata(gca,'XLim',get(gca,'XLim'))
% setappdata(gca,'YLim',get(gca,'YLim'))
% setappdata(gca,'ZLim',get(gca,'ZLim'));
end


function rotatecallback(obj,evd)
newView = round(evd.Axes.View);
setappdata(gca,'view',newView);
end