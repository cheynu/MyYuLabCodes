function [x_,y_, vel,t]=clean_data_lever(t, x, y, like, threshold)

    figure(15); clf(15);
    set(15, 'Visible', 'on', 'Units', 'pixels', 'Position', [250 250 800 500], 'name', 'Lift and Press')
    ha1 = subplot(3, 2, [2 4]); hold on
    set(gca, 'ydir', 'reverse')
    ha2 = subplot(3, 2, 1); hold on
    ha3 = subplot(3, 2, 3); hold on

    % Remove points with low likelihood at the beginning and end
    valid_indices = like > threshold;
    start_idx = find(valid_indices, 1, 'first'); % First valid point
    end_idx = find(valid_indices, 1, 'last');   % Last valid point

    % Truncate the data to only include valid points
    t = t(start_idx:end_idx);
    if any(size(t)-size(x)~=0)
        t=t';
    end

    x = x(start_idx:end_idx);
    y = y(start_idx:end_idx);
    like = like(start_idx:end_idx);

    % Identify high- and low-likelihood points
    highLikelihoodIdx = like >= threshold;
    lowLikelihoodIdx = like < threshold;

    % Plot original data
    axes(ha1)
    plot(ha1, x(highLikelihoodIdx), y(highLikelihoodIdx), 'color', 'k', 'marker', 'o', 'markeredgecolor', 'k', ...
        'linestyle', 'none')
    hold on
    plot(ha1, x(lowLikelihoodIdx), y(lowLikelihoodIdx), 'color', 'r', 'marker', '*')
    hold off

    axes(ha2)
    plot(ha2, t(highLikelihoodIdx), x(highLikelihoodIdx), 'color', 'k', 'marker', 'o', 'markeredgecolor', 'k', ...
        'linestyle', 'none')
    hold on
    plot(ha2, t(lowLikelihoodIdx), x(lowLikelihoodIdx), 'color', 'r', 'marker', '*')
    hold off
    ylabel('x')

    axes(ha3)
    plot(ha3, t(highLikelihoodIdx), y(highLikelihoodIdx), 'color', 'k', 'marker', 'o', 'markeredgecolor', 'k', ...
        'linestyle', 'none')
    hold on
    plot(ha3, t(lowLikelihoodIdx), y(lowLikelihoodIdx), 'color', 'r', 'marker', '*')
    hold off
    ylabel('y')

    % Interpolate the entire sequence using high-likelihood points
    x_interp = x; % Create copies to store interpolated values
    y_interp = y;

    % Perform interpolation for x and y using high-likelihood points
    if sum(highLikelihoodIdx) >= 2 % Ensure there are at least 2 valid points for interpolation
        x_interp = interp1(t(highLikelihoodIdx), x(highLikelihoodIdx), t, 'linear', 'extrap');
        y_interp = interp1(t(highLikelihoodIdx), y(highLikelihoodIdx), t, 'linear', 'extrap');
    else
        warning('Not enough high-likelihood points for interpolation.');
        x_interp(:) = NaN;
        y_interp(:) = NaN;
    end

    % Set low-likelihood points at the end of the sequence to NaN
    last_high_idx = find(highLikelihoodIdx, 1, 'last'); % Last high-likelihood point
    if last_high_idx < length(like) % If there are points after the last high-likelihood point
        end_low_idx = (last_high_idx + 1):length(like); % Indices of points at the end
        if any(lowLikelihoodIdx(end_low_idx)) % If any of these are low-likelihood
            x_interp(end_low_idx(lowLikelihoodIdx(end_low_idx))) = NaN;
            y_interp(end_low_idx(lowLikelihoodIdx(end_low_idx))) = NaN;
        end
    end

    % Plot interpolated points for verification
    axes(ha1)
    hold on
    % Plot interpolated points (excluding NaNs)
    valid_interp_idx = ~isnan(x_interp) & ~isnan(y_interp) & lowLikelihoodIdx;
    plot(ha1, x_interp(valid_interp_idx), y_interp(valid_interp_idx), 'color', 'b', 'marker', 's', 'linestyle', 'none')
    % Optionally plot the interpolated curve (excluding NaNs)
    valid_curve_idx = ~isnan(x_interp) & ~isnan(y_interp);
    plot(ha1, x_interp(valid_curve_idx), y_interp(valid_curve_idx), 'color', 'b', 'linestyle', '-', 'linewidth', 1)
 
    axes(ha2)
    hold on
    plot(ha2, t(valid_interp_idx), x_interp(valid_interp_idx), 'color', 'b', 'marker', 's', 'linestyle', 'none')
    plot(ha2, t(valid_curve_idx), x_interp(valid_curve_idx), 'color', 'b', 'linestyle', '-', 'linewidth', 1)
 
    axes(ha3)
    hold on
    plot(ha3, t(valid_interp_idx), y_interp(valid_interp_idx), 'color', 'b', 'marker', 's', 'linestyle', 'none')
    plot(ha3, t(valid_curve_idx), y_interp(valid_curve_idx), 'color', 'b', 'linestyle', '-', 'linewidth', 1)
    
    x=x_interp;
    y=y_interp;
    
    % add smoothdata
    x_=smoothdata(x, 'movmedian', 7);
    y_=smoothdata(y, 'movmedian', 7);


    plot(ha1,x_, y_, 'color', 'g','marker', '+', 'LineWidth',1, 'LineStyle','-');
    set(ha1, 'ydir', 'reverse')

    plot(ha2,t, x_, 'color', 'g','marker', '+', 'LineWidth',1, 'LineStyle','-');
    plot(ha3,t, y_, 'color', 'g','marker', '+', 'LineWidth',1, 'LineStyle','-');


    % compute movement direction and compute the difference between
    % movement direction and head direction, bang!
    dx = smoothdata(diff(x_), 'movmedian', 7);
    dy = smoothdata(-diff(y_), 'movmedian', 7); % compute difference

    % plot velocity
    subplot(3, 2, [5 6])
    vel = sqrt(diff(x_).^2+diff(y_).^2)./diff(t);
    vel = smoothdata(vel, 'gaussian', 11);
    % Create a plot with two y-axes
    plot(t(2:end), vel, 'bo-');  % Plot velocity (left y-axis)
    ylabel('Velocity (pix/ms)');  % Label for the left y-axis
      set(gca, 'xlim', [t(1) t(end)]);
 
% Check size of vel
sz = size(vel);

% If row vector (1 x N), prepend NaN horizontally
if sz(1) == 1
    vel = [NaN vel];
% If column vector (N x 1), prepend NaN vertically
elseif sz(2) == 1
    vel = [NaN; vel];
else
    error('vel must be a row or column vector');
end

end