function rms=rms_phi_2D(phi,data)
% r.m.s. of imaginary part after phase correction
itr=imag(data*exp(1i*phi));
rms=sqrt(sum(sum(itr.*itr)));
