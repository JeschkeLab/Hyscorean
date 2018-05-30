function x=posorth(x)
   % Projection into positive orthant
   pos = x<0;
   x(pos) = 0;
end