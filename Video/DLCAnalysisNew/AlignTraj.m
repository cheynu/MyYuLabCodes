function [tavg, trajAvgx, trajAvgy] = AlignTraj(t_traj, trajAll_x, trajAll_y, trange)
%% align data to max y

% get data surrounding peak (1000 ms + 1000 ms)
t2 = [-2000:2000];
trajAll_x2 = NaN*ones(length(t2), size(trajAll_x, 2));
trajAll_y2 = NaN*ones(length(t2), size(trajAll_x, 2));

for k = 1:size(trajAll_y, 2)
    
    % find max x (this is the
    [~, indpeak_x] = max(trajAll_x(:, k));
    
    trajAll_x(1:indpeak_x, k) = NaN;
    
        [~, indpeak] = max(-trajAll_y(:, k));
        
        tnew = t_traj - t_traj(indpeak);
        [~, indnew] = intersect(t2, tnew);

        trajAll_x2(indnew, k) = trajAll_x(:, k);
        trajAll_y2(indnew, k) = trajAll_y(:, k);
            
end;

ind_t2 = find(t2>=trange(1) & t2<trange(2));
trajAll_x2 = trajAll_x2(ind_t2, :);
trajAll_y2 = trajAll_y2(ind_t2, :);

% remove data points that contain less than 5 trials

nonnan_x = sum(~isnan(trajAll_x2), 2);
trajAll_x2( find(sum(nonnan_x, 2)<5), :) = NaN;

nonnan_y = ~isnan(trajAll_y2);
trajAll_y2( find(sum(nonnan_y, 2)<5), :) = NaN;

trajAvgx = smoothdata(nanmedian(trajAll_x2, 2), 'gaussian', 25);
trajAvgy = smoothdata(nanmedian(trajAll_y2, 2), 'gaussian', 55);

tavg       =  t2(ind_t2);