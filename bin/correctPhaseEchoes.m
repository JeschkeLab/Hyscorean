function Signal = correctPhaseEchoes(Signal)
%==========================================================================
% Phase corrector
%==========================================================================
% Correct the phase of a time-domain signal by optimizing the phase such 
% that the real component of the signal is mazimal with respect to the
% imaginary component.
%==========================================================================
%
% Copyright (C) 2019  Luis Fabregas, Hyscorean 2019
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License 3.0 as published by
% the Free Software Foundation.
%==========================================================================

Phase = fminbnd(@RMS_Phase_2D,-pi + 1e-4,pi,[],Signal);
Signal = Signal*exp(1i*Phase);
Signal = Signal/max(max(real(Signal)));
end

function RMS = RMS_Phase_2D(phi,data)
% r.m.s. of imaginary part after phase correction
ImaginaryComponent = imag(data*exp(1i*phi));
RMS = sqrt(sum(sum(ImaginaryComponent.*ImaginaryComponent)));
end


