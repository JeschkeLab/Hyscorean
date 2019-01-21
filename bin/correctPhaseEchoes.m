function data = correctPhaseEchoes(data)
phi=fminbnd(@rms_phi_2D,-pi+1e-4,pi,[],data);
data = data*exp(1i*phi);
data = data/max(max(real(data)));
end

function rms=rms_phi_2D(phi,data)
% r.m.s. of imaginary part after phase correction
itr=imag(data*exp(1i*phi));
rms=sqrt(sum(sum(itr.*itr)));
end


