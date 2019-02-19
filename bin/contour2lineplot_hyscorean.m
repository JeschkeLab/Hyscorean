function  contour2lineplot(ContourHandle,ReductionStep,Colormap,LineWidth)
% Converts a contour plot to a normal plot by re-plotting the contour lines
% of a contour plot as simple plot lines. This heavily reduces the size of
% the plot making it easier (or even possible) to be exported as a high
% quality export. 
%
% Adapted from Nino Wili by Luis Fabregas for Hyscorean 2019. 



%Get contour data from given handle
ContourDataMatrix=ContourHandle.ContourMatrix;
Data=contourdata(ContourDataMatrix);
ancestor(ContourHandle,'figure','toplevel');

%Hold to be able to plot all contour lines
hold on


%Loop over all contours
for ContourIndex=1:numel(Data)
    
   if ~Data(ContourIndex).isopen
     Data(ContourIndex).xdata(end+1)=Data(ContourIndex).xdata(1);
     Data(ContourIndex).ydata(end+1)=Data(ContourIndex).ydata(1);     
   end
   
   if nargin > 1
       Data(ContourIndex).xdata=Data(ContourIndex).xdata([1:ReductionStep:end end]);
       Data(ContourIndex).ydata=Data(ContourIndex).ydata([1:ReductionStep:end end]);
   end
   
   %Get the colors of the current line
   RGB_colors = vals2colormap(Data(ContourIndex).level, Colormap, [Data(1).level Data(end).level ]);
  
   %Plot the current contour line
   plot(Data(ContourIndex).xdata,Data(ContourIndex).ydata,'Color',RGB_colors,'LineWidth',LineWidth)
   
end

hold off

end

