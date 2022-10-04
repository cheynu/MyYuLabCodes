function [out,x] = genGrpDistr(edges,data,varargin)
%CALGRPDIST To compute the RT/PressDur distribution of multiple ANMs
%   edges: vector, e.g., 0:0.05:0.6
%   data: I*J*K cell, e.g., i:FP(0.5s/1.0s/1.5s), j:Experiment(Pre/Post), k:ANMs
%   out: I*J*K*L, e.g., i: bin, j: mean/lower/upper, k: FP, l: Pre/Post
%   x: the edges of output, e.g., 0.025:0.05:0.575

%   normalization: If the value of 'smooth' is 'ksdensity', 'normalization' should be
%       'pdf' or 'cdf'
%   smooth: methods used in the 'smoothdata', except 'ksdensity' that will
%       call 'ksdensity'.
%   window: for 'ksdensity' smooth, the default bandwidth(window)=sig*(4/(3*N))^(1/5), 'sig'
%       is an estimated value of sd of samples
%       for 'gaussian' smooth, window=5*sd

p = inputParser;
addRequired(p,'edges',@isvector);
addRequired(p,'data',@(x) iscell(x) && length(size(x))==3);
addParameter(p,'output','absolute',@(x)ismember(lower(x),{'absolute','relative'}));
addParameter(p,'method','GA',@(x)ismember(upper(x),{'GA','BTSP'}));
addParameter(p,'nsample',50);
addParameter(p,'nboot',500);
addParameter(p,'normalization','probability',...
    @(x)ismember(lower(x),{'count','probability','countdensity','pdf','cumcount','cdf'}));
addParameter(p,'smooth','none',...
    @(x)ismember(lower(x),{'none','movmean','movmedian','gaussian','ksdensity'}));
addParameter(p,'window',[]);

parse(p,edges,data,varargin{:});
in = p.Results;

fprintf('Calculation method is %s \n',in.method);
%%
isks = strcmpi(in.smooth,'ksdensity');
if ~isks
    out = nan(length(in.edges)-1,3,size(in.data,1),size(in.data,2));
    x = mean([in.edges(2:end);in.edges(1:end-1)]);
else
    out = nan(length(in.edges),3,size(in.data,1),size(in.data,2));
    x = in.edges;
end
switch upper(in.method)
    case 'GA'
        if ~isks
            res = nan(length(in.edges)-1,size(in.data,1),size(in.data,2),size(in.data,3)); % bin*FP*Experiment*ANMs
        else
            res = nan(length(in.edges),size(in.data,1),size(in.data,2),size(in.data,3)); % bin*FP*Experiment*ANMs
        end
        for k=1:size(in.data,3)
            for j=1:size(in.data,2)
                for i=1:size(in.data,1)
                    da = in.data{i,j,k};
                    if ~isks
                        res(:,i,j,k) = histcounts(da,in.edges,'Normalization',lower(in.normalization));
                    else
                        res(:,i,j,k) = ksdensity(da,in.edges,'Function',lower(in.normalization),'Bandwidth',in.window);
                    end
                end
            end
        end
        switch lower(in.smooth)
            case 'none'
                resmo = res;
            case 'ksdensity'
                resmo = res;
            otherwise
                resmo = smoothdata(res,1,in.smooth,in.window);
        end
        resmean = mean(resmo,4,'omitnan');
        ressem = std(resmo,0,4,'omitnan')./sqrt(size(resmo,4));
        out(:,1,:,:) = resmean;
        switch lower(in.output)
            case 'absolute'
                out(:,2,:,:) = resmean - ressem;
                out(:,3,:,:) = resmean + ressem;
            case 'relative'
                out(:,2,:,:) = ressem;
                out(:,3,:,:) = ressem;
        end
    case 'BTSP'
        if ~isks
            res = nan(length(in.edges)-1,size(in.data,1),size(in.data,2),in.nboot); % bin*FP*Experiment*nboot
        else
            res = nan(length(in.edges),size(in.data,1),size(in.data,2),in.nboot); % bin*FP*Experiment*nboot
        end
        for ib=1:in.nboot
            for i=1:size(in.data,1)
                for j=1:size(in.data,2)
                    pool = nan(in.nsample*size(in.data,3),1);
                    for k=1:size(in.data,3)
                        da = in.data{i,j,k};
                        dsa = randsample(da,in.nsample,true);
                        pool(in.nsample*(k-1)+1:in.nsample*k) = dsa;
                    end
                    if ~isks
                        res(:,i,j,ib) = histcounts(pool,in.edges,'Normalization',lower(in.normalization));
                    else
                        res(:,i,j,ib) = ksdensity(pool,in.edges,'Function',lower(in.normalization),'Bandwidth',in.window);
                    end
                end
            end
        end
        switch lower(in.smooth)
            case 'none'
                resmo = res;
            case 'ksdensity'
                resmo = res;
            otherwise
                resmo = smoothdata(res,1,in.smooth,in.window);
        end
        resmean = mean(resmo,4,'omitnan');
        reslower = quantile(resmo,0.025,4);
        resupper = quantile(resmo,0.975,4);
        out(:,1,:,:) = resmean;
        switch lower(in.output)
            case 'absolute'
                out(:,2,:,:) = reslower;
                out(:,3,:,:) = resupper;
            case 'relative'
                out(:,2,:,:) = resmean - reslower;
                out(:,3,:,:) = resupper - resmean;
        end
end