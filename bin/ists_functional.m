function [FunctionalValue, VectorGradient] = ists_functional(ReconstructedSpectrum,Threshold)
%==========================================================================
% IST-S Functional Calculator
%==========================================================================
% compute the scalar sum and vector gradient of the Stern IST functional
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
  AbsSpec = abs(ReconstructedSpectrum);
  FunctionalValue = sum(sum(AbsSpec));

  %Compute the vector gradient.
  VectorGradient = ReconstructedSpectrum.*(AbsSpec > Threshold);
  VectorGradient = VectorGradient.*(1 - Threshold./AbsSpec);

  return
