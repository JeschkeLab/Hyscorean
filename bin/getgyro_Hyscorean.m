function gyromagneticRatio = getgyro_Hyscorean(NucleifromList)
%Gyromagnetic ratios in MHz/T

load isotopesData

gyromagneticRatio = gvalues(NucleifromList); 

gyromagneticRatio = 5.050783746100000e-27*abs(gyromagneticRatio)/planck/1e6;

end

