function [Processed] = HammingWin(Processed,HammingDecay)

[size1,size2]=size(Processed.Signal);

%Construct asymmetric Hamming window
HammingDecay=round(HammingDecay);
arg=linspace(0,pi,HammingDecay);
HammingWindow=0.54*ones(1,HammingDecay)+0.46*cos(arg);

%Apodization of time-dimension 1
if HammingDecay>=size1
  HammingWindow=HammingWindow(1:size1);
end

if HammingDecay<size1
  HammingWindow=[HammingWindow HammingWindow(end)+zeros(1,size1-HammingDecay)];
end

for k=1:size2
   Processed.Signal(:,k)=HammingWindow'.*Processed.Signal(:,k);
end

%Apodization of time-dimension 2
HammingWindow=0.54*ones(1,HammingDecay)+0.46*cos(arg);
if HammingDecay>=size2
  HammingWindow=HammingWindow(1:size2);
end

if HammingDecay<size2
  HammingWindow=[HammingWindow HammingWindow(end)+zeros(1,size2-HammingDecay)];
end

for k=1:size1
   Processed.Signal(k,:)=HammingWindow.*Processed.Signal(k,:);
end

