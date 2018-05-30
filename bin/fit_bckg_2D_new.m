function [Background,Data] = fit_bckg_2D_new(Data,options)

Data = real(Data(options.zt1:end,options.zt2:end));

[Dimension1,Dimension2] = size(Data);

FullAxis1 = 1:Dimension1;
FullAxis2 = 1:Dimension2;

% start=9;
options.start1 = 1;
options.start2 =1;
Axis1 = options.start1:Dimension1;
Axis2 = options.start2:Dimension2;
TruncatedData = Data(options.start1:end,options.start2:end);

 [GridX, GridY] = ndgrid(Axis1,Axis2);
% Set up fittype and options.
FitType = fittype( 'c*exp(-(w*y)-w2*x)', 'independent', {'x', 'y'}, 'dependent', 'z' );
opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
opts.Display = 'Off';
opts.StartPoint = [0.898774196993757 0.852057968728423 0.00450753762869271];

FitResults = fit([GridX(:),GridY(:)],real(((TruncatedData(:)))),FitType,opts);

[GridX, GridY] = ndgrid(FullAxis1,FullAxis2);

% Background = FitResults.p00 + FitResults.p10*GridX + FitResults.p01*GridY + FitResults.p20*GridX.^2 + FitResults.p11*GridX.*GridY + ...
%                      FitResults.p30*GridX.^3 + FitResults.p21*GridX.^2.*GridY + FitResults.p40*GridX.^4 + FitResults.p31*GridX.^3.*GridY +...
%                      FitResults.p50*GridX.^5 + FitResults.p41*GridX.^4.*GridY;                 
%                    
% Background = FitResults.p00 + FitResults.p10*GridX + FitResults.p01*GridY + FitResults.p20*GridX.^2 + FitResults.p11*GridX.*GridY ...
%   + FitResults.p02*GridY.^2 + FitResults.p30*GridX.^3 + FitResults.p21*GridX.^2.*GridY + FitResults.p12*GridX.*GridY.^2 + FitResults.p03*GridY.^3 + ...
%   FitResults.p40*GridX.^4 + FitResults.p31*GridX.^3.*GridY + FitResults.p22*GridX.^2.*GridY^2 + FitResults.p13*GridX.*GridY.^3 + FitResults.p04*GridY.^4 + ...
%   FitResults.p50*GridX.^5 + FitResults.p41*GridX.^4.*GridY + FitResults.p32*GridX.^3.*GridY.^2 + FitResults.p23*GridX.^2.*GridY.^3 + ...
%   FitResults.p14*GridX.*GridY.^4 + FitResults.p05*GridY.^5;

Background = FitResults(GridX,GridY);

 figure(1),clf,surface(GridX,GridY,(Background)),hold on, scatter3(GridX(:),GridY(:),real(Data(:)),1.5,'k')
view( -259.1, -1.2 );

Background = (Background);

figure(5),clf,surface(GridX,GridY,real(Data)-Background),title('2D-Background-corrected data')
view( -259.1, -1.2 );

Background = real(Background);

end

function rms = rms_stretched_private(v,x1,x2,exp,homdim)
%RMS_streched	Root mean square error of function exp(-k*t^ksi).
%	rms = rms_stretched(v,x,y).
%	
%  Parameter: v(2) Amplitude, v(1) Zeitkonstante, v(3) ksi

%	Copyright (c) 2004 by Gunnar Jeschke

if v(2)>0 || v(3)>0
    rms=1.0e6; 
    return 
end

if length(v) == 4
    homdim = v(4);
end

sim = decaynD_private(v,x1,x2,homdim);
diff = sim-exp;
rms = sum(sum(diff.*diff));


end

function sim=decaynD_private(v,x1,x2,homdim)

sim = zeros(length(x1),length(x2));

for k = 1 : length(x1)
    sim(k,:) = exp((v(2)*x1(k))^(homdim/3));
    for kk = 1 : length(x2)
        sim(k,kk) = sim(k,kk)*exp((v(3)*x2(kk))^(homdim/3));
    end
end

sim = sim*exp(v(1)); 
sim = real(sim);

end







