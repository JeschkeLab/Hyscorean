function [Signal,Window] = apodizationWin(Signal,WindowType,WindowDecay1,WindowDecay2)

[size1,size2]=size(Signal);

%------------------------------------------------------------------------
% Apodization of first dimension
%------------------------------------------------------------------------

WindowDecay = round(WindowDecay1);

switch WindowType
  case 'chebyshev'
    % Construct asymmetric Chebishev window
    Window = ifftshift(chebwin(WindowDecay*2));
    Window = Window(1:WindowDecay)';
  case 'hamming'
    %Construct asymmetric Hamming window
    arg=linspace(0,pi,WindowDecay);
    Window=0.54*ones(1,WindowDecay) + 0.46*cos(arg);
  case 'welch'
    %Construct asymmetric Welch window
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
end

if length(Window)>=size1
  TruncatedWindow = Window(1:size1);
else
  TruncatedWindow = [Window zeros(1,size1 - WindowDecay)];
end

for k=1:size2
   Signal(:,k)=TruncatedWindow'.*Signal(:,k);
end
  
%------------------------------------------------------------------------
% Apodization of second dimension
%------------------------------------------------------------------------

WindowDecay = round(WindowDecay2);


switch WindowType
  case 'chebyshev'
    % Construct asymmetric Chebishev window
    Window = ifftshift(chebwin(WindowDecay*2));
    Window = Window(1:WindowDecay)';
  case 'hamming'
    %Construct asymmetric Hamming window
    arg=linspace(0,pi,WindowDecay);
    Window=0.54*ones(1,WindowDecay) + 0.46*cos(arg);
  case 'welch'
    %Construct asymmetric Welch window
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
end

Window = Window';

%Apodization of second dimension

if length(Window)>=size2
  TruncatedWindow=Window(1:size2);
else
  TruncatedWindow=[Window' zeros(1,size2-WindowDecay)]';
end

for k=1:size1
   Signal(k,:)=TruncatedWindow'.*Signal(k,:);
end