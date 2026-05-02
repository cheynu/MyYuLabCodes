function [cdf,tEdges,auc,ddlEsti] = AnticipationFunction(HT,FPs,probe,options)
% ANTICIPATIONFUNCTION: based on (Ollman & Billington, 1972)
% Yu Chen, debug about probe, 2025.3.24
% Yu Chen, 2024.11.24
% revised from gout = Gfunction(datain, FPs, options) by Jianing Yu 7/14/2024

arguments
    HT % nx1, seconds, HoldTime of all trials excluding probe trials
    FPs % nx1, seconds, the FP value corresponding to HT
    probe = [] % nx1, HoldTime of probe trials, seconds
    options.ifPlot = false
    options.BinWidth = 0.1 % seconds
    options.minResponseTime = 0 % seconds, anything before FP+minResponseTime is considered an anticipatory response
    options.ifExcludeProbe = false
end
ifPlot = options.ifPlot;
tBin = options.BinWidth;
tMin = options.minResponseTime;
ifExcludeProbe = options.ifExcludeProbe;

HT = HT(:);
FPs = FPs(:);
probe = probe(:);

if ifExcludeProbe
    probe = [];
end
%% Calculation
FPuni = unique(FPs);
nFP = zeros(size(FPuni));
for i=1:length(FPuni)
    fp = FPuni(i);
    nFP(i) = sum(FPs==fp);
end
nProbe = length(probe);

maxT = max([FPuni(:)+tMin;probe(:)],[],'all');
maxT = ceil(maxT/tBin)*tBin;
tEdges = 0:tBin:maxT;

cdf = zeros(size(tEdges));
for i=2:length(tEdges)
    iEdge = tEdges(i);
    idx_counts = find(FPuni+tMin>=iEdge); % all FP

    n_total = 0;
    n_less = 0;

    if any(idx_counts) % current bin <= max FP + tMin
        for j=1:length(idx_counts)
            idx = idx_counts(j);
            jFP = FPuni(idx);
            jHT = HT(FPs==jFP);
            jdata = jHT;
            jAnticipation = jHT(jHT<=iEdge);
    
            n_total = n_total + length(jdata);
            n_less = n_less + length(jAnticipation);
        end
        jdata = probe;
        jAnticipation = probe(probe<=iEdge);

        n_total = n_total + length(jdata);
        n_less = n_less + length(jAnticipation);
    else % only probe trials
        jdata = probe;
        jAnticipation = probe(probe<=iEdge);
        n_total = length(jdata);
        n_less = length(jAnticipation);
    end
    cdf(i) = n_less/n_total;
end

% auc = sum(repmat(tBin,size(tEdges)).*cdf);
auc = trapz(tEdges, cdf);

ddlEsti = struct; % estimate of deadline delays
if ~isempty(probe)
    ddlEsti.Usable = true;
    
    ddlEsti.Mean = findXfromCDFvalue(tEdges,cdf,0.5);
    ddlEsti.SD = (findXfromCDFvalue(tEdges,cdf,0.84) - findXfromCDFvalue(tEdges,cdf,0.16))/2;
    ddlEsti.CV = ddlEsti.SD/ddlEsti.Mean;
else
    ddlEsti.Usable = false;
    ddlEsti.Mean = NaN;
    ddlEsti.SD = NaN;
    ddlEsti.CV = NaN;
end

if ifPlot
    plot(tEdges,cdf);
    xlabel('Time (s)');
    ylabel('Cumulative Probability');
    title(sprintf('μ=%.3f, σ=%.3f, σ/μ=%.3f',ddlEsti.Mean,ddlEsti.SD,ddlEsti.CV));
end

end

function t = findXfromCDFvalue(tEdges,cdf,tar_cdf)
idxHigh = find(cdf-tar_cdf>=0,1,'first');
if isempty(idxHigh)
    t = NaN;
    return;
elseif idxHigh == 1
    idxLow = idxHigh;
elseif cdf(idxHigh)~=0
    idxLow = idxHigh - 1;
else
    idxLow = idxHigh;
end

cdfRange = [cdf(idxLow), cdf(idxHigh)];
tEdgesRange = [tEdges(idxLow), tEdges(idxHigh)];
if isempty(idxLow) || isempty(idxHigh)
    t = NaN;
elseif cdf(idxLow)==cdf(idxHigh)
    t = tEdges(round((idxLow+idxHigh)/2));
else
    t = interp1(cdfRange, tEdgesRange, tar_cdf, 'linear');
end

end
