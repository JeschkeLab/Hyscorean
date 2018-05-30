function [Processed] = ChebishevWin(Processed,WindowDecay)

[size1,size2]=size(Processed.Signal);

% Construct asymmetric Chebishev window
WindowDecay = round(WindowDecay);
ChebishevWindow = ifftshift(chebwin(WindowDecay*2));
ChebishevWindow = ChebishevWindow(1:WindowDecay)';

%Apodization of time-dimension 1
if length(ChebishevWindow)>=size1
  ChebishevWindow = ChebishevWindow(1:size1);
else
  ChebishevWindow = [ChebishevWindow zeros(1,size1 - WindowDecay)];
end

for k=1:size2
   Processed.Signal(:,k)=ChebishevWindow'.*Processed.Signal(:,k);
end

%Apodization of time-dimension 2
ChebishevWindow = ifftshift(chebwin(WindowDecay*2));
ChebishevWindow = ChebishevWindow(1:WindowDecay);
  
if length(ChebishevWindow)>=size2
  ChebishevWindow=ChebishevWindow(1:size2);
else
  ChebishevWindow=[ChebishevWindow' zeros(1,size2-WindowDecay)]';
end

for k=1:size1
   Processed.Signal(k,:)=ChebishevWindow'.*Processed.Signal(k,:);
end