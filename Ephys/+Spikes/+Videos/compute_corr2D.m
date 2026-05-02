function [map_out, xcenters, ycenters] = compute_corr2D(x, y, xedges, yedges, spatial_binsize)
%
% x_range = [0 800];
% pix_size = 10;
% xedges = (x_range(1):pix_size:x_range(end));
%
% y_range = [0 700];
% yedges = (y_range(1):pix_size:y_range(end));

if nargin<5
    spatial_binsize = 25;
end

xcenters =(xedges(1:end-1)+xedges(2:end))/2;
ycenters =(yedges(1:end-1)+yedges(2:end))/2;

psf = fspecial('gaussian', [spatial_binsize spatial_binsize], 1); % create a 2d gaussian kernel

ndist = histcounts2(x,y, xedges, yedges, 'Normalization', 'probability');
ndist(ndist>0) = 1;
map_out = transpose(conv2(ndist, psf, 'same'));

end