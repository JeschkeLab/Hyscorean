function [FunctionalValue, VectorGradient] = camera_functional (Spectrum, BackgroundParameter)
%==========================================================================
% CAMERA Functional Calculator
%==========================================================================
% Compute the scalar sum and vector gradient of the Hoch-Hore entropy
% functional.
%==========================================================================
%
% Adapted from Bradley Worley under the GNU GPL 3.0. license.
% 
% Copyright (C) 2019, Luis Fabregas Ibanez, Hyscorean   
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License 3.0 as published by
% the Free Software Foundation.
%==========================================================================

%Compute the scalar sum.
absSepc = abs(Spectrum);
sqrtTerm = sqrt(1 + (absSepc./(2*BackgroundParameter)).^2);
FunctionalValue = sum(sum(absSepc .* ...
  log(absSepc./(2*BackgroundParameter) + sqrtTerm) - ...
  sqrt(4*BackgroundParameter*BackgroundParameter + absSepc.^2)));

%Compute the vector gradient.
VectorGradient = Spectrum.*log(absSepc./(2*BackgroundParameter) + sqrtTerm)./absSepc;

return

