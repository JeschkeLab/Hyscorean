function [Signal,Window1,Window2] = apodizationWin(Signal,WindowType,WindowDecay1,WindowDecay2)

[size1,size2]=size(Signal);

%------------------------------------------------------------------------
% Apodization of first dimension
%------------------------------------------------------------------------

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

%------------------------------------------------------------------------
% Apodization of second dimension
%------------------------------------------------------------------------

Window = getWindow(WindowType,round(WindowDecay2))';

%Apodization of second dimension

if length(Window)>=size2
  TruncatedWindow=Window(1:size2);
else
  TruncatedWindow=[Window' zeros(1,size2-WindowDecay2)]';
end

for k=1:size1
   Signal(k,:)=TruncatedWindow'.*Signal(k,:);
end

Window2 = Window';

end


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