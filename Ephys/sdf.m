function [spkout, sdf_mean, sdf_ci]=sdf(tspk, spkin, kernel_width, compute_ci)
% 2019, 2021, 2025
% Jianing Yu
% tspk is time, in sec. If in ms, the program will turn it to sec
% spkin takes the form of spike 1 and no spike 0, spkin is a sparse matrix.
% spkout is the kernal product of spkin
% firing rate can be estimated by averaging spkout
% K(t)=exp(-t^2/(2*s^2))/(sqrt(2*pi)*s);
% s is the kernel width, e.g., 10 ms

if any(diff(tspk)>.5)
    tspk = tspk/1000; % turn it to seconds
end

if nargin<4
    compute_ci = 0;
    if nargin<3
        kernel_width=1;
    end
end

f=round(1/(tspk(2)-tspk(1))); % sampling rate
k=gaussian_kernel(kernel_width/1000, f); % the area under the curve is 1

if size(spkin, 1)~=length(tspk)
    spkin=spkin';  % dim1 spikes, dim2 trial nums
end

if size(k, 1)<size(k, 2)
    k=k';
end

spkin2=[];
for ni=1:size(spkin, 2)
    spktemp=full(spkin(:, ni));
    spkin2(:, ni)=conv(spktemp, k, 'same');
end

spkout=spkin2;
sdf_mean = mean(spkout, 2);
if compute_ci
    sdf_ci = transpose(bootci(1000, @mean, spkout'));
else
    sdf_ci = NaN;
end
