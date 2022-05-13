function [Data] = integrateEcho(Data,Integration,options)
%==========================================================================
% Hyscorean Detached Signal Monitoring 
%==========================================================================
% This function is responsible for integrating the echoes obtained from 
% echo-detected experiments. The echoes can be integrated directly by boxcar
% integration or by fitting a gaussian to the echo and integrating the echo
% multiplied with the fit.
% In Hyscorean this method is used for integrating echoes detected on the
% AWG spectrometer.
% (see Hyscorean manual for further information)
%==========================================================================
%
% Copyright (C) 2019  Luis Fabregas, Hyscorean 2019
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License 3.0 as published by
% the Free Software Foundation.
%==========================================================================

if nargin<3
  options = struct();
end
if ~isfield(options,'FittingTime')
  options.FittingTime = max(Data.EchoAxis);
end
if ~isfield(options,'Boxcar')
  options.Boxcar = 0;
end

%--------------------------------------------------------------------------
% Preparations
%--------------------------------------------------------------------------

% Find where to start fitting the echo
TimeIndex = find(Data.EchoAxis > -abs(options.FittingTime),1);

% Get EchoAxis
EchoAxis = Data.EchoAxis;

% If echo data is stored in cell array (mountHYSCOREdata of JS for non-NUS data) put it into a 3D-matrix
if ~iscell(Data.AverageEcho)
    AverageEcho = Data.AverageEcho;
else
    dim1 = size(Data.AverageEcho,1);
    dim2 = Data.Dimension2;
    dim3 = size(EchoAxis,1);
    AverageEcho = zeros(dim3,dim2,dim1);
    for i = 1:dim1
        if ~isempty(Data.AverageEcho{i})
        AverageEcho(:,:,i) = Data.AverageEcho{i};
        end
    end
end


% Find the first trace with a non-zero (existing) echo to fit a gaussian

switch Integration
%--------------------------------------------------------------------------
% Gaussian-Fit Integration
%--------------------------------------------------------------------------
    case 'gaussian'
      
    % Search for the first echo in stored trace data for fitting a gaussian
    Pos = 1;
    Pos2 = 1;
    while sum(AverageEcho(:,Pos,Pos2)) == 0
      Pos = Pos+1;
      if Pos > size(AverageEcho,2)
        Pos = 1;
        Pos2 = Pos2+1;
      end
    end

    % Gaussian fit of the first echo (for better SNR)
    AverageEchoFitted = zeros(size(AverageEcho));
    FitTimeAxis = EchoAxis(TimeIndex:end - TimeIndex);
    FitData = abs(squeeze(AverageEcho(TimeIndex:end - TimeIndex,Pos,Pos2)));
    try
		GaussianFit = fit(FitTimeAxis,FitData,'gauss1');
	catch err_message
        warning('Gaussian integration failed, returning to switch to boxcar integration.');
        Data = NaN;
        return;
    end
	
    %Normalize window
	window = GaussianFit(EchoAxis); 		% for returning the window function
    GaussianWindow = GaussianFit(EchoAxis)/max(GaussianFit(EchoAxis));
    
    %Apply to first echo
    AverageEchoFitted(:,Pos,1) = GaussianWindow.*AverageEcho(:,1,1);
    
    for iDimension2 = 1 : size(AverageEcho,2)
      for iDimension1 = 1: size(AverageEcho,3)
        %Repeat for the other echos applying same window
        if (AverageEcho(1,iDimension2,iDimension1)) ~= 0
            AverageEchoFitted(:,iDimension2,iDimension1) = GaussianWindow.*AverageEcho(:,iDimension2,iDimension1);
        end
      end
      % Update on the status of integration
      if isfield(options,'status')
      set(options.status, 'String', sprintf('Status: Integr. Echoes %2.1f%%',iDimension2/size(AverageEcho,2)*100)); drawnow;
      end
    end
    % Separate real and imaginary part
    RealIntegral = real(AverageEchoFitted);
    ImagIntegral = imag(AverageEchoFitted);
    % Integration of the gaussian fits of the echos
    RealIntegral = squeeze(sum(abs(RealIntegral),1));
    ImagIntegral  = squeeze(sum(abs(ImagIntegral),1));
    Integral = RealIntegral + 1i*ImagIntegral;
%--------------------------------------------------------------------------
% Boxcar Integration
%--------------------------------------------------------------------------    
  case 'boxcar'
    % Do a boxcar-integration over the (entire) echo
    Integral = squeeze(sum(abs(AverageEcho(TimeIndex:end-TimeIndex,:,:)),1));
	window = zeros(length(EchoAxis),1);			% can be shown in a better way
end

%--------------------------------------------------------------------------
% Return
%--------------------------------------------------------------------------

% Normalize integral and mount to data-structure
Data.Integral = (Integral/max(max((Integral))));
% Return WindowFunction for mountAWGdata gui
Data.WindowFunction = window;

end


