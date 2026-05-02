function sdfout =sdf_spktimes(spk_times, tmax, kernel_width, bin_size)
% 2019, 2021, 2024
% Jianing Yu
% tspk is time, in msec
% spkin takes the form of spike 1 and no spike 0, spkin is a sparse matrix.
% spkout is the kernal product of spkin
% firing rate can be estimated by averaging spkout
% K(t)=exp(-t^2/(2*s^2))/(sqrt(2*pi)*s);
% s is the kernel width, e.g., 10 ms
% everything in ms
% the default bin_size is 1 ms, but you can go for 10 ms 
% sdf_spktimes only requires spike times in seconds
% adapted from function spkout=sdf_spktimes(tspk, spkin, kernel_width)

if nargin<4
    bin_size = 1;
    if nargin<3
        kernel_width=1;
    end
end
 
if length(tmax)==1
    tspk  = (0:bin_size:round(tmax)); % this is the time domain
else
    tspk  = (round(tmax(1)):bin_size:round(tmax(end))); % this is the time domain
end
% 
% function gaussFilter=gaussian_kernel(width_s, fs_s)
% if nargin==0
%     width_s=0.01; % 10 ms
%     fs_s=0.001; % also 10 ms
% end;

% construct spk matrix
spkin = 1000*histcounts(spk_times, tspk)/bin_size;
tspk = tspk(1:end-1);
sdfout = smoothdata(spkin, 'gaussian', kernel_width);
sdfout = [tspk' sdfout'];
%
% figure(10); clf(10)
% set(gcf, 'visible', 'on')
% subplot(2, 1, 1)
% line([spk_times spk_times], [0 1], 'color','k', 'linewidth', 2)
% set(gca, 'xlim', [0 tmax]*1000)
% subplot(2, 1, 2)
% plot(tspk, sdfout)
% 
% []
