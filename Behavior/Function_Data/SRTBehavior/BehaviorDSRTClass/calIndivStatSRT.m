function stat = calIndivStatSRT(data,multiSession,opts)
% calculate the STATs of one subject
% STATs of 1 session or across sessions (but in the same Experiment & Task)
    arguments
        data
        multiSession = false
        opts.fplist = []
        opts.ifDistr = false
        opts.calRT95CI = false
        opts.edges_HT = 0:0.05:2.5 % Hold time (All trials)
        opts.bins_HT = 0.025:0.05:2.475
        opts.edges_RT = 0:0.025:0.6 % Reaction time (Cor)
        opts.edges_RelT = 0:0.05:1 % Release time (Cor+Late)
        opts.smoWin = 8 % smoothdata('gaussian')
        opts.ksbandwidth = 0.15
    end
    if isempty(opts.fplist)
        fplist = unique(data.FP); % sorted from small to big
        if length(fplist) > 3 || length(fplist) == 1
        % adapt for wait(more than 3) and single FP protocols
            fplist = [0.5 1.0 1.5];
        end
    else
        fplist = opts.fplist;
    end
    
    stat = table;

    t = struct;
    
    t.Subject = data.Subject(1);
    t.Group = data.Group(1);
    t.Experiment = data.Experiment(1);
    t.Task = data.Task(1);
    if ~multiSession
        t.Session = data.Session(1);
        t.Date = data.Date(1);
        % t.DateTime = data.DateTime(1);
    else
        t.nSession = length(unique(data.Session));
    end
    
    t.nTrial = length(data.iTrial);
    % t.Dark = size(data.Dark,1);
    % t.rTrial = t.nTrial./(t.Dark+t.nTrial);

    idxCor  = contains(data.Outcome,'Cor');
    idxPre  = contains(data.Outcome,'Pre');
    idxLate = contains(data.Outcome,'Late');
    idxAnti = data.RT >= 0 & data.RT < 0.1;
    t.Cor  = sum(idxCor)/t.nTrial;
    t.Pre  = sum(idxPre)/t.nTrial;
    t.Late = sum(idxLate)/t.nTrial;
    t.Cor_anti = (sum(idxCor) - sum(idxAnti))/t.nTrial;
    t.Pre_anti = (sum(idxPre) + sum(idxAnti))/t.nTrial;
    t.PreTendency = (t.Pre-t.Late)/(t.Pre+t.Late);

    idx_max = data.FP == 1.5;
    if any(idx_max)
        outcome_max = data.Outcome(idx_max);
        t.Cor_max = sum(outcome_max=="Cor")/sum(idx_max);
        t.Pre_max = sum(outcome_max=="Pre")/sum(idx_max);
        t.Late_max = sum(outcome_max=="Late")/sum(idx_max);
    else
        t.Cor_max = NaN;
        t.Pre_max = NaN;
        t.Late_max = NaN;
    end



    if ~multiSession
        t.maxFP = max(data.FP);
        t.t2mFP = find(data.FP==t.maxFP,1,'first');
        if isempty(t.t2mFP) % hbWang Jan 2024 (revised for LeverPress/Release)
            t.t2mFP = NaN;
        end
        t.minRW = min(data.RW);
        t.t2mRW = find(data.RW==t.minRW,1,'first');
        if isempty(t.t2mRW) % hbWang Jan 2024 (revised for SRTMED)
            t.t2mRW = NaN;
        end
        switch string(t.Task)
            case {"AutoShaping", "LeverPress", "LeverRelease"}
                t2c = NaN;
                t2cInv = NaN;
                t.t2mRW = NaN;
            case {"Wait1","Wait1Ephys"}
                t2c = find(abs(data.FP-1.5)<1e-4,1,'first');
                if ~isempty(t2c)
                    t2cInv = 1./t2c;
                else
                    t2c = NaN;
                    t2cInv = 0;
                end
            case {"Wait2","Wait2Ephys"}
                t2c = find(abs(data.FP-1.5)<1e-4 & abs(data.RW-0.6)<1e-4,1,'first');
                if ~isempty(t2c)
                    t2cInv = 1./t2c;
                else
                    t2c = NaN;
                    t2cInv = 0;
                end
            case {"3FPs", "2FPs"}
                t2c = NaN;
                t2cInv = NaN;

        end
        t.t2c = t2c;
        t.t2cInv = t2cInv;
    end
    
    t.HT = median(rmoutliers(data.HT,'quartiles'),'omitnan');
    rt = calRT(data.HT(idxCor), data.FP(idxCor),...
        'Remove100ms', 1, 'RemoveOutliers', 0, 'ToPlot', 0, 'Calse', 0);
    t.RT = rt.median;
    t.RT_IQR = diff(prctile(data.RT(idxCor), [25 75]));
    relt = calRT(data.HT(idxCor|idxLate), data.FP(idxCor|idxLate),...
        'Remove100ms', 1, 'RemoveOutliers', 0, 'ToPlot', 0, 'Calse', 0);
    t.RelT = relt.median;
    allRelT = data.HT(idxCor|idxLate)-data.FP(idxCor|idxLate);
    criRelT = allRelT(allRelT>0.1 & allRelT<2.0);
    t.RelT_IQR = diff(prctile(criRelT, [25 75]));
    t.MT = median(rmoutliers(data.MT,'quartiles'),'omitnan');

    % Post correct or post error rt
    idxPostCor = [0;idxCor(1:end-1)];
    idxPostPre = [0;idxPre(1:end-1)];
    idxPostLate = [0;idxLate(1:end-1)];
    idxPostError = idxPostPre | idxPostLate;
    rt_postcor = calRT(data.HT(idxCor & idxPostCor), data.FP(idxCor & idxPostCor),...
        'Remove100ms', 1, 'RemoveOutliers', 1, 'ToPlot', 0, 'Calse', 0);
    t.RT_postCor = rt_postcor.median;
    rt_postpre = calRT(data.HT(idxCor & idxPostPre), data.FP(idxCor & idxPostPre),...
        'Remove100ms', 1, 'RemoveOutliers', 1, 'ToPlot', 0, 'Calse', 0);
    t.RT_postPre = rt_postpre.median;
    rt_postlate = calRT(data.HT(idxCor & idxPostLate), data.FP(idxCor & idxPostLate),...
        'Remove100ms', 1, 'RemoveOutliers', 1, 'ToPlot', 0, 'Calse', 0);
    t.RT_postLate = rt_postlate.median;
    rt_posterror = calRT(data.HT(idxCor & idxPostError), data.FP(idxCor & idxPostError),...
        'Remove100ms', 1, 'RemoveOutliers', 1, 'ToPlot', 0, 'Calse', 0);
    t.RT_postError = rt_posterror.median;

    % Post dark rt
    temp = [1;diff(data.iPress)];
    idxPostDark = temp > 1;
    rt_postdark = calRT(data.HT(idxPostDark), data.FP(idxPostDark),...
        'Remove100ms', 1, 'RemoveOutliers', 1, 'ToPlot', 0, 'Calse', 0);
    t.RT_postDark = rt_postdark.median;

    t.dRT_postError = t.RT_postError - t.RT_postCor;
    t.dRT_postDark  = t.RT_postDark  - t.RT_postCor;

    % Stat in each FP
    corFP = []; preFP = []; corFP_anti = []; preFP_anti = []; lateFP = []; 
    htFP = []; htiqr_FP = []; rtFP = []; rt95ci_FP = []; 
    rtiqr_FP = []; reltFP = []; relt95ci_FP = []; reltiqr_FP = []; mtFP = [];
    for iFP = 1:length(fplist)
        if iFP == 1
            idxThis = (data.FP>=0) & (data.FP<=fplist(iFP));
        else
            idxThis = (data.FP<=fplist(iFP)) & (data.FP>fplist(iFP-1));
        end
        if sum(idxThis) == 0
            corFP = [corFP, 0]; %#ok<*AGROW>
            preFP = [preFP, 0];
            lateFP = [lateFP, 0];
            corFP_anti = [corFP_anti, 0];
            preFP_anti = [preFP_anti, 0];

            htFP = [htFP, 0];
            htiqr_FP = [htiqr_FP, NaN];
            rtFP = [rtFP, NaN];
            rt95ci_FP = [rt95ci_FP, [NaN NaN]];
            rtiqr_FP = [rtiqr_FP, NaN];
            reltFP = [reltFP, NaN];
            relt95ci_FP = [relt95ci_FP, [NaN NaN]];
            reltiqr_FP = [reltiqr_FP, NaN];
            mtFP = [mtFP, NaN];
        else
            corFP = [corFP, sum(idxCor & idxThis)./sum(idxThis)];
            preFP = [preFP, sum(idxPre & idxThis)./sum(idxThis)];
            corFP_anti = [corFP_anti, (sum(idxCor & idxThis)-sum(idxAnti & idxThis))./sum(idxThis)];
            preFP_anti = [preFP_anti, (sum(idxPre & idxThis)+sum(idxAnti & idxThis))./sum(idxThis)];
            lateFP = [lateFP, sum(idxLate & idxThis)./sum(idxThis)];
            htFP = [htFP, median(rmoutliers(data.HT(idxThis),'quartiles'),'omitnan')];
            htiqr_FP = [htiqr_FP, iqr(data.HT(idxThis))];
            mtFP = [mtFP, median(rmoutliers(data.MT(idxThis),'quartiles'),'omitnan')];

            if opts.calRT95CI
                rtt = calRT_95CI(data.HT(idxCor & idxThis), data.FP(idxCor & idxThis),...
                    'Remove100ms', 1, 'RemoveOutliers', 1, 'ToPlot', 0, 'Calse', 1);
                rtFP = [rtFP, rtt.median(1)];
                rt95ci_FP = [rt95ci_FP, rtt.median_95CI];
                rtiqr_FP = [rtiqr_FP, iqr(data.RT(idxCor & idxThis))];
                reltt = calRT_95CI(data.HT((idxCor|idxLate)&idxThis), data.FP((idxCor|idxLate)&idxThis),...
                    'Remove100ms', 1, 'RemoveOutliers', 1, 'ToPlot', 0, 'Calse', 1);
                reltFP = [reltFP, reltt.median(1)];
                relt95ci_FP = [relt95ci_FP, reltt.median_95CI];
                reltiqr_FP = [reltiqr_FP, iqr(data.RelT((idxCor|idxLate) & idxThis))];
            else
                rtt = calRT(data.HT(idxCor & idxThis), data.FP(idxCor & idxThis),...
                    'Remove100ms', 1, 'RemoveOutliers', 1, 'ToPlot', 0, 'Calse', 0);
                rtFP = [rtFP, rtt.median];
                rt95ci_FP = [rt95ci_FP, [NaN NaN]];
                rtiqr_FP = [rtiqr_FP, diff(prctile(data.RT(idxCor & idxThis),[25 75]))];
                reltt = calRT(data.HT((idxCor|idxLate)&idxThis), data.FP((idxCor|idxLate)&idxThis),...
                    'Remove100ms', 1, 'RemoveOutliers', 1, 'ToPlot', 0, 'Calse', 0);
                reltFP = [reltFP, reltt.median];
                relt95ci_FP = [relt95ci_FP, [NaN NaN]];
                reltiqr_FP = [reltiqr_FP, diff(prctile(data.RelT((idxCor|idxLate) & idxThis), [25 75]))];
            end
        end
    end
    t.Cor_FP = corFP;
    t.Pre_FP = preFP;
    t.Cor_anti_FP = corFP_anti;
    t.Pre_anti_FP = preFP_anti;
    t.Late_FP = lateFP;
    t.PreTendency_FP = (preFP-lateFP)./(preFP+lateFP);
    t.HT_FP = htFP;
    t.HT_IQR_FP = htiqr_FP;
    t.RT_FP = rtFP;
    t.RT_CI95_FP = rt95ci_FP;
    t.RT_IQR_FP = rtiqr_FP;
    t.RelT_FP = reltFP;
    t.RelT_CI95_FP = relt95ci_FP;
    t.RelT_IQR_FP = reltiqr_FP;
    t.MT_FP = mtFP;

    % calculate distribution
    if opts.ifDistr
        % t.HTpdf = smoothdata(histcounts(data.HT,...
        %     opts.edges_HT,'Normalization','pdf'),2,'gaussian',opts.smoWin);
        % t.RTpdf = smoothdata(histcounts(data.RT(idxCor),...
        %     opts.edges_RT,'Normalization','pdf'),2,'gaussian',opts.smoWin);
        % t.RelTpdf = smoothdata(histcounts(data.HT(idxCor|idxLate)-data.FP(idxCor|idxLate),...
        %     opts.edges_RelT,'Normalization','pdf'),2,'gaussian',opts.smoWin);
        % t.HTcdf = smoothdata(histcounts(data.HT,...
        %     opts.edges_HT,'Normalization','cdf'),2,'gaussian',opts.smoWin);
        % t.RTcdf = smoothdata(histcounts(data.RT(idxCor),...
        %     opts.edges_RT,'Normalization','cdf'),2,'gaussian',opts.smoWin);
        % t.RelTcdf = smoothdata(histcounts(data.HT(idxCor|idxLate)-data.FP(idxCor|idxLate),...
        %     opts.edges_RelT,'Normalization','cdf'),2,'gaussian',opts.smoWin);
        % 
        t.HTpdf = ksdensity(data.HT, opts.edges_HT,"Bandwidth", opts.ksbandwidth);
        t.RTpdf = ksdensity(data.RT(idxCor), opts.edges_RT,"Bandwidth", opts.ksbandwidth);
        t.RelTpdf = ksdensity(data.HT(idxCor|idxLate)-data.FP(idxCor|idxLate), ...
            opts.edges_HT,"Bandwidth", opts.ksbandwidth);
        t.HTcdf = ksdensity(data.HT, opts.edges_HT,"Bandwidth", opts.ksbandwidth, "Function", "cdf");
        t.RTcdf = ksdensity(data.RT(idxCor), opts.edges_RT,"Bandwidth", opts.ksbandwidth, "Function", "cdf");
        t.RelTcdf = ksdensity(data.HT(idxCor|idxLate)-data.FP(idxCor|idxLate), ...
            opts.edges_HT,"Bandwidth", opts.ksbandwidth, "Function", "cdf");

        for iFP = 1:length(fplist)
            idxThis = data.FP==fplist(iFP);

            if any(idxThis)
                t.(['HTpdf_FP',num2str(iFP)]) = ksdensity(data.HT(idxThis), opts.edges_HT,"Bandwidth", opts.ksbandwidth);
                t.(['HTcdf_FP',num2str(iFP)]) = ksdensity(data.HT(idxThis), opts.edges_HT,"Bandwidth", opts.ksbandwidth, "Function", "cdf");
            else
                t.(['HTpdf_FP',num2str(iFP)]) = nan(1,length(opts.edges_HT));
                t.(['HTcdf_FP',num2str(iFP)]) = nan(1,length(opts.edges_HT));
            end

            if any(idxThis&idxCor)
                t.(['RTpdf_FP',num2str(iFP)]) = ksdensity(data.RT(idxCor&idxThis), opts.edges_RT,"Bandwidth", opts.ksbandwidth);
                t.(['RelTpdf_FP',num2str(iFP)]) = ksdensity(data.RelT((idxCor|idxLate)&idxThis)-data.FP((idxCor|idxLate)&idxThis), ...
                    opts.edges_RelT,"Bandwidth", opts.ksbandwidth);
                t.(['RTcdf_FP',num2str(iFP)]) = ksdensity(data.RT(idxCor&idxThis), opts.edges_RT,"Bandwidth", opts.ksbandwidth, "Function", "cdf");
                t.(['RelTcdf_FP',num2str(iFP)]) = ksdensity(data.RelT((idxCor|idxLate)&idxThis)-data.FP((idxCor|idxLate)&idxThis), ...
                    opts.edges_RelT,"Bandwidth", opts.ksbandwidth, "Function", "cdf");
            else
                t.(['RTpdf_FP',num2str(iFP)]) = nan(1,length(opts.edges_RT));
                t.(['RelTpdf_FP',num2str(iFP)]) = nan(1,length(opts.edges_RelT));
                t.(['RTcdf_FP',num2str(iFP)]) = nan(1,length(opts.edges_RT));
                t.(['RelTcdf_FP',num2str(iFP)]) = nan(1,length(opts.edges_RelT));
            end

        end

    end
    
    stat = [stat;struct2table(t)];
end