function Hyscore_correlation_plot(x1,x2,y,options)
% this creates a two dimensional correlation plot, with the projections as
% the integral along the corresponding axes.
% Call should be 
%       correlation_plot(x1,x2,y,options)
% 
% Alternatively it is possible to call correlation plot without axes as
%       correlation_plot(y)
% or
%       correlation_plot(y,options)
% 
% x1    axis of the first dimension
% x2    axis of the second dimension
% 
% y     two dimensional data, can be complex valued, specify with options
%       whether you want real, imag, or abs plotted, default is abs
% 
% options       optional, structure with some parameters
% options.xaxs      vector, to set limits of x-axis
% options.yaxs      vector, to set limits of y-axis
% options.levels    number of levels in contourplot, default is 15
% options.xlabel    string for x-label
% options.ylabel    string for y-label
% options.type      can be 'abs', 'real' or 'imag', to decide what you want
%                   to be plotted of your complex data
% options.fignum    figure number

if nargin == 1
    y = x1;
    options = [];
elseif nargin ==2
    y = x1;
    options = x2;
end

if ~exist('options','var') || ~isstruct(options)
    options = [];
    levels = 15;
else
    if ~isempty(options) && isfield(options,'yaxs')
        yaxs = options.yaxs;
    end
    
    if ~isempty(options) && isfield(options,'xaxs')
        xaxs = options.xaxs;
    end

    if isempty(options) || ~isfield(options,'levels') || isempty(options.levels)
        levels = 15;
    else
        levels = options.levels;
    end
end


% 
% %setting up figure environment
if isfield(options,'nonnewfig')
  
  if isfield(options,'fignum') && ~isempty(options.fignum)
    figure(options.fignum)
    clf
  else
    figure
  end
end
plotsize = [73.8000   47.2000  434.0000  342.3000];
figsize = [680   678   450   420];


if isfield(options,'figsize')
  figsize = options.figsize;
  plotsize([1,2]) = 0.15*figsize([1,2]);
  plotsize(4) = 0.75*figsize(4);
  plotsize(3) = 0.82*figsize(3);

end
% stretch the figure vertically by a factor
horzstretch = 1.2;
figsize(3) = figsize(3) * horzstretch;
figsize(1) = figsize(1) - 0.5* figsize(3);

% calculate the position of the second subfigure
pixeloffset = 20;
insetsize = plotsize;
insetsize(1) = insetsize(1)+insetsize(3)+pixeloffset;
insetsize(3) = (horzstretch-1) * figsize(3) - pixeloffset;

% add an inset on the top
vertstretch = 1.2;
figsize(4) = figsize(4) * vertstretch;
figsize(2) = figsize(2) - 0.5 *figsize(4);


% calculate the position of the third subfig
pixeloffset = 20;
inset2size = plotsize;
inset2size(2) = inset2size(2)+inset2size(4)+pixeloffset;
inset2size(4) = (vertstretch-1) * figsize(4) - pixeloffset;

w1_projection = max(abs(y),[],2);
w1_projection = w1_projection/max(w1_projection);

w2_projection = max(abs(y),[],1);
w2_projection = w2_projection/max(w2_projection);

%% first plot


set(gcf,'Position',figsize);
ax1 = axes; %#ok<NASGU>
set(gca,'Units','pixels','Position',plotsize)

if isempty(options) || ~isfield(options,'type') || isempty(options.type)
    plotarea = abs(y');
elseif strcmp(options.type,'abs')
    plotarea = abs(y');
elseif strcmp(options.type,'real')
    plotarea = real(y');
elseif strcmp(options.type,'imag')
    plotarea = imag(y');
end
%Transpose to be according with Hyscorean display
plotarea = plotarea';
%Compute contour levels according to minimal contour level given by user
Levels=levels;
MinimalContourLevel = options.MinimalContourLevel;
MaximalContourLevel = options.MaximalContourLevel;
MinimalContourLevel = max(max(plotarea))*MinimalContourLevel/100;
MaximalContourLevel =  max(max(plotarea))*MaximalContourLevel/100;
ContourLevelIncrement = (MaximalContourLevel - MinimalContourLevel)/Levels;
ContourLevels = MinimalContourLevel:ContourLevelIncrement:MaximalContourLevel;

contour(x1,x2,plotarea,ContourLevels,'LineWidth',options.Linewidth)
hold on
plot(x1,abs(x1),'k-.');
plot(zeros(length(x1)),abs(x1),'k-');
grid on
ax(1)=gca;

if isfield(options,'xlabel') && ~isempty(options.xlabel)
    xlabel(options.xlabel)
else
    xlabel('\nu_1 [MHz]');
end

if isfield(options,'ylabel') && ~isempty(options.ylabel)
    ylabel(options.ylabel)
else
    ylabel('\nu_2 [MHz]');
end

try
    ylim(yaxs)
catch
    yaxs = get(gca,'YLim');
end

try
    xlim(xaxs)
catch
    xaxs = get(gca,'XLim');    
end
set(gca,'units','normalized');


ax2 = axes; %#ok<NASGU>
set(gca,'Units','pixels','Position',insetsize)
hold on
box on

% plot(gca,abs(w2_projection),x2,'k')

ax(2)=gca;

% remove axis ticks
set(gca,'xtick',[], 'xticklabel',{})
set(gca,'ytick',[], 'yticklabel',{})
set(gca,'units','normalized');
axis tight
ylim(yaxs)

ax3 = axes; %#ok<NASGU>
set(gca,'Units','pixels','Position',inset2size)
hold on
box on

% plot(x1,abs(w1_projection),'k');
ax(3) = gca;
axis tight
xlim(xaxs)
set(gca,'xtick',[], 'xticklabel',{})
set(gca,'ytick',[], 'yticklabel',{})
set(gca,'units','normalized');

setappdata(gca,'ax',ax)

linkaxes([ax(1),ax(2)],'y');
linkaxes([ax(1),ax(3)],'x');

zoomer=zoom;
zoomer.ActionPostCallback = @zoomcallback;


for i = 1 :  length(ax)
setappdata(ax(i),'ax',ax)
setappdata(ax(i),'x2',x2);
setappdata(ax(i),'x1',x1);
setappdata(ax(i),'y',y);
setappdata(ax(i),'fig_index',i);
setappdata(ax(i),'options',options);
setappdata(ax(i),'YLim',get(ax(i),'YLim'));
setappdata(ax(i),'XLim',get(ax(i),'XLim'));
end

 zoom(1)
end

function zoomcallback(obj,evd)
ax = getappdata(gca,'ax');
range.yaxs = get(ax(1),'YLim');
range.xaxs = get(ax(1),'XLim');

x1 = getappdata(gca,'x1');
index_x1 = [find(x1 > range.xaxs(1), 1)-1 find(x1 > range.xaxs(2), 1)];

if length(index_x1) == 1
    index_x1(2) = size(getappdata(gca,'y'),1);
end

x2 = getappdata(gca,'x2');
index_x2 = [find(x2 > range.yaxs(1), 1)-1 find(x2 > range.yaxs(2), 1)];

if length(index_x2) == 1
    index_x2(2) = size(getappdata(gca,'y'),2);
end

y = getappdata(gca,'y');

x1_range = index_x1(1):index_x1(2);
x2_range = index_x2(1):index_x2(2);

w1_projection = max(abs(y(x1_range,x2_range)),[],2);
w1_projection = w1_projection/max(w1_projection);

w2_projection = max(abs(y(x1_range,x2_range)),[],1);
w2_projection = w2_projection/max(w2_projection);
        
line_color = [0 0.4470 0.7410];
% line_color = [1 1 1];
axesHandlesToChildObjects = findobj(ax(3), 'Type', 'line');
delete(axesHandlesToChildObjects);


plot(ax(3),x1(x1_range),abs(w1_projection),'color','k')
% set(ax(3),'YLim',getappdata(ax(3),'YLim'));


axesHandlesToChildObjects = findobj(ax(2), 'Type', 'line');
delete(axesHandlesToChildObjects);

plot(ax(2),abs(w2_projection),x2(x2_range),'color','k')
% set(ax(2),'XLim',getappdata(ax(2),'XLim'));


end
