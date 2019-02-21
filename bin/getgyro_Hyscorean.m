function gyromagneticRatio = getgyro_Hyscorean(NucleifromList)
%Gyromagnetic ratios in MHz/T

switch NucleifromList
  case 1
    gyromagneticRatio = 42.57747892;  %1H
  case 2
    gyromagneticRatio = 6.536; %2H
  case 3
    gyromagneticRatio = -32.434; %3He
  case 4
    gyromagneticRatio = 16.546; %7Li
  case 5
    gyromagneticRatio = 10.7084; %13C
  case 6
    gyromagneticRatio = 3.077; %14N
  case 7
    gyromagneticRatio = -4.316; %15N
  case 8
    gyromagneticRatio = -5.772; %17O
  case 9
    gyromagneticRatio = 40.052; %19F
      case 10
    gyromagneticRatio = 11.262; %23Na
      case 11
    gyromagneticRatio = 11.103; %27Al
      case 12
    gyromagneticRatio = -8.465; %29Si
      case 13
    gyromagneticRatio = 17.235; %31P
      case 14
    gyromagneticRatio = 1.382; %57Fe
      case 15
    gyromagneticRatio = 11.319; %63Cu
      case 16
    gyromagneticRatio = 2.669; %67Zn
end