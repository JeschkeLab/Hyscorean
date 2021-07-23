function gyromagneticRatio = getgyro_Hyscorean(NucleifromList, IsotopeTags)
%Gyromagnetic ratios in MHz/T

gyromagneticRatio = IsotopeTags(NucleifromList).gn;

gyromagneticRatio = 5.050783746100000e-27*abs(gyromagneticRatio)/planck/1e6;

end

