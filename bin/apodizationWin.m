function [Signal,Window1,Window2] = apodizationWin(Signal,WindowType,WindowDecay1,WindowDecay2)
%==========================================================================
% Apodization function
%==========================================================================
% This function performs the aopdization of the 1D or 2D time-domain signal
% given in the input along the first and second dimension. The apodization 
% window is selected via the WindowType string from the list below. 
% The WindowDecay input variables indicate the number of points after which
% the apodization window has decayed completely.
% The function returns the signal as well as the apodization windows used. 
% The same window type is used for both dimensions. 
%==========================================================================
%
% Copyright (C) 2019  Luis Fabregas, Hyscorean 2019
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License 3.0 as published by
% the Free Software Foundation.
%==========================================================================

if nargin<2
  error('The function requires at least 2 input arguments')
end

[size1,size2]=size(Signal);

if nargin<3
  WindowDecay1 = size1;
  WindowDecay2 = size2;
end


%------------------------------------------------------------------------
% Apodization of first dimension
%------------------------------------------------------------------------

%Do apodization along the first dimension if exists
if size1>1
  Window = getWindow(WindowType,round(WindowDecay1)); 
  if length(Window)>=size1
    TruncatedWindow = Window(1:size1);
  else
    TruncatedWindow = [Window zeros(1,size1 - WindowDecay1)];
  end 
  for k=1:size2
    Signal(:,k)=TruncatedWindow'.*Signal(:,k);
  end 
  Window1 = Window; 
else
  Window1 = [];
end

%------------------------------------------------------------------------
% Apodization of second dimension
%------------------------------------------------------------------------

%Do apodization along the second dimension if exists
if size2>1
  Window = getWindow(WindowType,round(WindowDecay2))';
  if length(Window)>=size2
    TruncatedWindow=Window(1:size2);
  else
    TruncatedWindow=[Window' zeros(1,size2-WindowDecay2)]';
  end
  for k=1:size1
    Signal(k,:)=TruncatedWindow'.*Signal(k,:);
  end 
  Window2 = Window';  
else
  Window2 = [];
end

end

%------------------------------------------------------------------------
%Local function to generate the windows
%------------------------------------------------------------------------
  function Window = getWindow(WindowType,WindowDecay)
    
    switch WindowType
      case 'chebyshev'
        Window = ifftshift(chebwin(WindowDecay*2));
        Window = Window(1:WindowDecay)';
      case 'hamming'
        arg=linspace(0,pi,WindowDecay);
        Window=0.54*ones(1,WindowDecay) + 0.46*cos(arg);
      case 'welch'
        arg=linspace(0,1,WindowDecay);
        Window = 1 - arg.^2;
      case 'blackman'
        arg=linspace(0,1,WindowDecay);
        Window = 0.42 + 0.5*cos(pi*arg) + 0.08*cos(2*pi*arg);
      case 'bartlett'
        arg=linspace(0,1,WindowDecay);
        Window = 1 - abs(arg);
      case 'connes'
        arg=linspace(0,1,WindowDecay);
        Window = (1 - arg.^2).^2;
      case 'cosine'
        arg=linspace(0,1,WindowDecay);
        Window = cos(pi*arg/2);
      case 'none'
        Window = ones(1,WindowDecay);
      case 'tukey25'
        alpha = 0.25;
        Window = tukeywin(2*WindowDecay,alpha);
        Window = Window(WindowDecay+1:end)';
      case 'tukey50'
        alpha = 0.5;
        Window = tukeywin(2*WindowDecay,alpha);
        Window = Window(WindowDecay+1:end)';
      case 'tukey75'
        alpha = 0.75;
        Window = tukeywin(2*WindowDecay,alpha);
        Window = Window(WindowDecay+1:end)';
      case 'hann'
        alpha = 1.5;
        Window = tukeywin(2*WindowDecay,alpha);
        Window = Window(WindowDecay+1:end)';
    end
    
  end