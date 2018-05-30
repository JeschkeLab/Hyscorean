function bckg = fit_bckg_2D(data,options)
%
% Fits background decay according to the model selected by
% options.model along dimension options.dim starting at data point
% options.start
%
% options   specifies the background model and background fit parameters
%  .model   0  fractal, n variable,  exp(-k*t^(n/3))
%           1  n-dimensional, n fixed, exp(-k*t^(n/3))
%           2  three-dimensional, exp(-k*t)
%           3  polynomial (fitted to logarithm)
% 
% the following options need to be defined only if the corresponding 
% model is requested
%   .homdim     fractal dimension for homogeneous distribution (model 1)
%   .order      order of polynomial (model 3)
%
% output:
% 
% bckg      background matrix with same dimensions as data
%
% G. Jeschke, 25.8.2016

bckg = zeros(size(data));
if isfield(options,'dim') && options.dim == 1,
    data = data.';
    bckg = bckg.'; 
end;
[m,n] = size(data);

for k = 1:m,
    ti = options.start:n;
    tf = 1:n;
    tr = data(k,options.start:end);
    poly = polyfit(ti,log(tr),1); % linear fit of logarithm
    switch options.model,
        case 0,
            v0=[abs(poly(1)) 1 3];
            v1=fminsearch(@rms_stretched_private,v0,[],ti,tr);
            bckg_tr =decaynD_private(v1(1:2),tf,v1(3));
        case 1,
            v0=[abs(poly(1)) 1];
            v1=fminsearch(@rms_stretched_private,v0,[],ti,tr,options.homdim);
            bckg_tr =decaynD_private(v1(1:2),tf,options.homdim);
        case 2,
            bckg_tr = exp(polyval(poly,tf)); % background is exponential of that
        case 3,
            poly = polyfit(ti,log(tr),options.order);
            bckg_tr = exp(polyval(poly,tf));
    end;
    bckg(k,:) = bckg_tr;
end;

bckg=real(bckg);
if isfield(options,'dim') && options.dim == 1,
    bckg = bckg.';
end;

function rms = rms_stretched_private(v,x,y,homdim)
%RMS_streched	Root mean square error of function exp(-k*t^ksi).
%	rms = rms_stretched(v,x,y).
%	
%  Parameter: v(2) Amplitude, v(1) Zeitkonstante, v(3) ksi

%	Copyright (c) 2004 by Gunnar Jeschke

if v(1)<0, rms=1.0e6; return; end;
if length(v) > 2,
    homdim = v(3);
end;

sim = decaynD_private(v(1:2),x,homdim);
diff = sim-y;
rms = sum(diff.*diff);

function sim=decaynD_private(v,x,hom_dim)
%
%

sim=real(v(2)*exp(-(v(1)*x).^(hom_dim/3)));
