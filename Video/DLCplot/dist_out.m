function distout = dist_out(x, y, xref, yref)
% compute e-distance between vector x and y
z_x = x - xref;
z_y = y - yref;
distout = sqrt(z_x.^2+z_y.^2);
end