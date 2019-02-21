function [Selections,Combinations] = getTauCombinations(TauValues)
%==========================================================================
% Tau-combinations
%==========================================================================
% This function generates all possible combination of tau-values given by
% the experimental data loaded into Hyscorean.
%==========================================================================
%
% Copyright (C) 2019  Luis Fabregas, Hyscorean 2019
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License 3.0 as published by
% the Free Software Foundation.
%==========================================================================

%Initialize cell array counter
Counter = 1;

%Take increasingly more tau values for combinations
for TauValuesTaken = 1:length(TauValues)
  %Get all possible combinations for the tau values taken
  Combinations = combnk(TauValues,TauValuesTaken);
  %Get the number of combinations found
  NCombinations = size(Combinations,1);
  %Construct formated strings with combinations 
  for j = 1:NCombinations
    if TauValuesTaken == 1
      CurrentCombination = Combinations(j,:);
      String = sprintf('Tau %i ns',CurrentCombination);
    else
      CurrentCombination = Combinations(j,:);
      String = sprintf('Tau [ %i |',CurrentCombination(1));
      if TauValuesTaken>2
        for k = 2:TauValuesTaken-1
          String = sprintf('%s %i |',String,CurrentCombination(k));
        end
      end
      String = sprintf('%s %i ] ns',String,CurrentCombination(end));
    end
    Selections{Counter} = String;
    Counter = Counter+1;
  end
end

return