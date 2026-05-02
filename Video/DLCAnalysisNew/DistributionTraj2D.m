function DistOut = DistributionTraj2D(t_traj, trajAll_x, trajAll_y)
%% Jianing Yu 4/3/2022
% plot hand trajectories

data = [trajAll_x(:) trajAll_y(:)];
ind_nonnan = find(~isnan(data(:, 1)) | ~isnan(data(:, 2))); 
data = data(ind_nonnan, :);
Xedges = [0:10:1200];
Xcenters = (Xedges(1:end-1)+Xedges(2:end))/2;
Yedges = [0:10:1200];
Ycenters = (Yedges(1:end-1)+Yedges(2:end))/2;
[N, Xcenters, Ycenters] = histcounts2(data(:,1),data(:, 2),Xedges,Yedges, 'Normalization', 'probability');
Nspatial = N;

data2 = [repmat(t_traj', size(trajAll_x, 2), 1) trajAll_x(:)];
ind_nonnan = find(~isnan(data2(:, 1)) | ~isnan(data2(:, 2))); 
data2 = data2(ind_nonnan, :);

tedges = [-1000:10:200];
tcenters = (tedges(1:end-1)+tedges(2:end))/2;

[Nx] = histcounts2(data2(:,1),data2(:, 2),tedges,Xedges, 'Normalization', 'probability');

data3= [repmat(t_traj', size(trajAll_y, 2), 1) trajAll_y(:)];
ind_nonnan = find(~isnan(data3(:, 1)) | ~isnan(data3(:, 2))); 
data3 = data3(ind_nonnan, :);
[Ny] = histcounts2(data3(:,1),data3(:, 2),tedges, Yedges, 'Normalization', 'probability');

DistOut.CenterNames = {'t', 'X', 'Y'};
DistOut.Centers = {tcenters, Xcenters, Ycenters};
DistOut.DistributionNames = {'X-Y', 't-X', 't-Y'};
DistOut.Distribution = {Nspatial, Nx, Ny};



figure; 
set(gcf, 'Visible', 'on', 'units', 'centimeters', 'position', [2 2 25 6])
subplot(1, 3, 1)
imagesc(Xcenters, Ycenters, N', [0  prctile(N(:), 99.9)]);
colorbar
set(gca, 'xlim', [100 900], 'ylim', [200 800])

subplot(1, 3, 2)
imagesc(tcenters, Xcenters, Nx', [0  prctile(Nx(:), 99.9)]);
colorbar
set(gca, 'xlim', [-1000 200], 'ylim', [200 800])

subplot(1, 3, 3)
imagesc(tcenters, Ycenters, Ny', [0  prctile(Ny(:), 99.9)]);
colorbar
set(gca, 'xlim', [-1000 200], 'ylim', [200 800])
