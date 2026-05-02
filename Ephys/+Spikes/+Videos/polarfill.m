function polarfill(bin_centers, upper, lower, color)
    % Duplicate the polar coordinates for shading
    theta = [bin_centers, fliplr(bin_centers)];
    rho = [upper, fliplr(lower)];
    
    % Convert polar to Cartesian coordinates
    [x, y] = pol2cart(theta, rho);
    
    % Plot shaded area
    fill(x, y, color, 'EdgeColor', 'none', 'FaceAlpha', 0.2); % Adjust transparency
end