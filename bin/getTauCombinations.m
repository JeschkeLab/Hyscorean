function [Selections,Combinations] = getTauCombinations(TauValues)

nn = 1;
Combinations = zeros(1,length(TauValues));

%1-tau combinations
for i=1:length(TauValues)
  Selections{nn} = sprintf('Tau %i ns',TauValues(i));
  Combinations(nn,1) = i;
  nn = nn + 1;
end

if length(TauValues)>1
%2-tau combinations
for i=1:length(TauValues)
  for j=i:length(TauValues)
    if i~=j
      Selections{nn} = sprintf('Tau [ %i | %i ] ns',TauValues(i),TauValues(j));
      Combinations(nn,1:2) = [i,j];
      nn = nn + 1;
    end
  end
end
end

if length(TauValues)>2
%3-tau combinations
for i=1:length(TauValues)
  for j=i:length(TauValues)
    for k=j:length(TauValues)
      if i~=j && i~=k && j~=k
        Selections{nn} = sprintf('Tau [ %i | %i | %i ] ns',TauValues(i),TauValues(j),TauValues(k));
        Combinations(nn,1:3) = [i,j,k];
        nn = nn + 1;
      end
    end
  end
end
end


if length(TauValues)>3
  %3-tau combinations
  for i=1:length(TauValues)
    for j=1:length(TauValues)
      for k=1:length(TauValues)
        for l=1:length(TauValues)
          if i~=j && i~=k && j~=k && i~=l && j~=l && k~=l
            Selections{nn} = sprintf('Tau [ %i | %i | %i | %i ] ns',TauValues(i),TauValues(j),TauValues(k),TauValues(l));
            Combinations(nn,1:4) = [i,j,k,l];
            nn = nn + 1;
          end
        end
      end
    end
  end
end