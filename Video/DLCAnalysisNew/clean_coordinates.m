function [x_cleaned, y_cleaned] = clean_coordinates(x, y, likelihood);
% Extract x, y, and likelihood from dlcResults.EarLTop
% x = dlcResults.EarLTop.x;
% y = dlcResults.EarLTop.y;
% likelihood = dlcResults.EarLTop.likelihood;

% Define a likelihood threshold for "well-tracked" points
threshold = 0.9; % Adjust as needed for your data

% Identify points with high likelihood
highLikelihoodIdx = likelihood >= threshold;

% Interpolate x and y for low-likelihood points
x_cleaned = x; % Create a copy of x for modification
y_cleaned = y; % Create a copy of y for modification

% Use linear interpolation to fill in low-likelihood points
x_cleaned(~highLikelihoodIdx) = interp1(find(highLikelihoodIdx), x(highLikelihoodIdx), find(~highLikelihoodIdx), 'linear', 'extrap');
y_cleaned(~highLikelihoodIdx) = interp1(find(highLikelihoodIdx), y(highLikelihoodIdx), find(~highLikelihoodIdx), 'linear', 'extrap');