function out = isi_violation_metrics(kutime, varargin)
% isi_violation_metrics
% Compute ISI violation metrics for a spike train.
%
% Default: kutime is in MILLISECONDS.
%
% out = isi_violation_metrics(kutime)
% out = isi_violation_metrics(kutime, 'TimeUnit','ms', 'Refrac',3, 'MinISI',0, 'DoPlot',true)
%
% Name-value options
%   'TimeUnit'   : 'ms' (default) | 's'
%   'Refrac'     : refractory threshold (ms if TimeUnit='ms', else s). default 3 ms
%   'MinISI'     : minimum enforced ISI (same unit as Refrac). default 0
%   'DoPlot'     : true/false (default false)
%   'Ax'         : axes handle (default [])
%   'MaxISIms'   : histogram max x in ms (default 50)
%   'BinWidthMs' : histogram bin width in ms (default 0.25)

p = inputParser;
p.addRequired('kutime', @(v) isnumeric(v) && isvector(v) && ~isempty(v));
p.addParameter('TimeUnit', 'ms', @(s) any(strcmpi(s, {'ms','s'})));
p.addParameter('Refrac', 3, @(v) isnumeric(v) && isscalar(v) && v > 0);
p.addParameter('MinISI', 0, @(v) isnumeric(v) && isscalar(v) && v >= 0);
p.addParameter('DoPlot', false, @(v) islogical(v) && isscalar(v));
p.addParameter('Ax', [], @(h) isempty(h) || isgraphics(h,'axes'));
p.addParameter('MaxISIms', 50, @(v) isnumeric(v) && isscalar(v) && v > 0);
p.addParameter('BinWidthMs', 0.25, @(v) isnumeric(v) && isscalar(v) && v > 0);
p.parse(kutime, varargin{:});

timeUnit = lower(p.Results.TimeUnit);
refrac_in = p.Results.Refrac;
minisi_in = p.Results.MinISI;

% Convert spike times to seconds internally
spk = sort(kutime(:));
switch timeUnit
    case 'ms'
        spk_s = spk / 1000;
        t_r   = refrac_in / 1000;   % 3 ms -> 0.003 s
        t_min = minisi_in / 1000;
    case 's'
        spk_s = spk;
        t_r   = refrac_in;
        t_min = minisi_in;
end

N = numel(spk_s);

% Edge case
if N < 2
    out = struct('raw_isi_violation_pct',NaN,'raw_spike_violation_pct',NaN, ...
        'n_v',0,'N',N,'T',0,'fr',NaN,'corrected_ratio',NaN,'corrected_pct',NaN,'isi',[]);
    return;
end

isi_s = diff(spk_s);
dt = t_r - t_min;
if dt <= 0
    error('Refrac must be > MinISI.');
end

n_v = sum(isi_s < dt);

raw_isi_violation_pct   = 100 * n_v / numel(isi_s); % fraction of ISIs
raw_spike_violation_pct = 100 * n_v / N;            % alternative

T  = spk_s(end) - spk_s(1);
fr = N / max(T, eps);

% Siegle/Allen(Hill-style) corrected metric
corrected_ratio = (n_v * T) / (2 * (N^2) * dt);
corrected_pct   = 100 * corrected_ratio;

out = struct();
out.raw_isi_violation_pct   = raw_isi_violation_pct;
out.raw_spike_violation_pct = raw_spike_violation_pct;
out.n_v = n_v;
out.N = N;
out.T = T;                 % seconds
out.fr = fr;               % Hz
out.corrected_ratio = corrected_ratio;
out.corrected_pct = corrected_pct;
out.isi = isi_s;           % seconds

% Optional plot (hist in ms)
if p.Results.DoPlot
    ax = p.Results.Ax;
    if isempty(ax)
        figure;
        ax = axes('NextPlot','add','Box','on');
    else
        hold(ax,'on'); box(ax,'on');
    end

    maxISI = p.Results.MaxISIms;
    bw     = p.Results.BinWidthMs;

    histogram(ax, isi_s*1000, 0:bw:maxISI);
    xlabel(ax, 'ISI (ms)');
    ylabel(ax, 'Count');

    stats_str = sprintf(['Raw ISI<%.1fms: %.4f%% (n_v=%d)\n' ...
                         'Corrected: %.4f (%.3f%%)\n' ...
                         'N=%d, T=%.1fs, FR=%.2f Hz'], ...
                         t_r*1000, raw_isi_violation_pct, n_v, ...
                         corrected_ratio, corrected_pct, ...
                         N, T, fr);

    xl = xlim(ax); yl = ylim(ax);
    text(ax, xl(1) + 0.03*range(xl), yl(2) - 0.03*range(yl), stats_str, ...
        'HorizontalAlignment','left','VerticalAlignment','top', ...
        'FontSize', 9, 'Interpreter','none');
end
end
