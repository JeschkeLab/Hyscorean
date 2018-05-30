function [t01,t02,data,phi,n01,n02] = phase_zt(t1,t2,data)
% Automatic phase correction of a 1D DEER or 2D TRIER data set and
% determination of the zero-time in one or two dimensions
% data is also normalized to the global maximum of the real part after
% phase correction
%
% Input:
%
% t1    time axis of x dimension (column), can be empty, if dimension does
%       not exist
% t2    time axis of y dimension (row), can be empty if dimension does not
%       exist
% data  data array, must have dimension length(t1),lenght(t2)
% phi   phase correction
%
% Output:
%
% t01   estimated time zero along t1 dimension
% t02   estimated time zero along t2 dimension
% data  phase corrected data
% phi   phase correction (rad)
% n01   data point corresponding to time zero along t1 dimension
% n02   data point corresponding to time zero along t2 dimension
%
% G. Jeschke, 25.8.2016

[m,n] = size(data);
phi=fminbnd(@rms_phi_2D,-pi/2+1e-4,pi/2,[],data);
data = data*exp(1i*phi);
data = data/max(max(real(data)));

if m > 1,
    cdata = sum(real(data),2);
    % Determine maximum
    [~,mp]=max(cdata);
    nmp=1;
    % Determine time zero by moment analysis
    if mp > 1 && mp < length(cdata),
        dmi = mp-1;
        dma = length(cdata)-mp;
        dm = dmi; if dma < dm, dm = dma; end;
        maxd = floor(dm/2);
        dev = 1e20;
        nmp = mp;
        for k = -maxd+mp:maxd+mp,
            summ = 0;
            for l = -maxd:maxd,
                summ = summ+cdata(k+l)*l;
            end;
            if abs(summ)<dev, dev = abs(summ); nmp=k; end;
        end;
    end;
    t01 = t1(nmp);
    n01 = nmp;
else
    t01 = 0;
    n01 = 1;
end;

if n > 1,
    cdata = sum(real(data),1);
    % Determine maximum
    [~,mp]=max(cdata);
    nmp=1;
    % Determine time zero by moment analysis
    if mp > 1 && mp < length(cdata),
        dmi = mp-1;
        dma = length(cdata)-mp;
        dm = dmi; if dma < dm, dm = dma; end;
        maxd = floor(dm/2);
        dev = 1e20;
        nmp = mp;
        for k = -maxd+mp:maxd+mp,
            summ = 0;
            for l = -maxd:maxd,
                summ = summ+cdata(k+l)*l;
            end;
            if abs(summ)<dev, dev = abs(summ); nmp=k; end;
        end;
    end;
    t02 = t2(nmp);
    n02 = nmp;
else
    t02 = 0;
    n02 = 1;
end;
