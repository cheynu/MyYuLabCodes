function value = cmptFWHM(f, binEdge)
    % compute FWHM based on the model
     xnew = binEdge(1):0.001:binEdge(end);
     ynew = f(xnew);
     x_above = xnew(ynew>0.5*max(ynew));
     value = x_above(end) - x_above(1);
end