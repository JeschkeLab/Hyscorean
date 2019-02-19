% camera_functional: compute the scalar sum and vector gradient
% of the hoch-hore entropy functional.
function [f, df] = camera_functional (X, d)
  % compute the scalar sum.
  abs_X = abs(X);
  sqrt_part = sqrt(1 + (abs_X./(2*d)).^2);

  f = sum(sum(abs_X .* ...
          log(abs_X./(2*d) + sqrt_part) - ...
          sqrt(4*d*d + abs_X.^2)));

  % compute the vector gradient.
  df = X .* log(abs_X./(2*d) + sqrt_part) ./ abs_X;
  return
end
