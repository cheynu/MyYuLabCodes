function stat = calIndivStat(data,multiSession,opts)
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
        % opts.GaussEqn = 'a1*exp(-((x-b1)/c1)^2)+a2*exp(-((x-b2)/c2)^2)';
        % opts.StartPoints = [1 1 1 2 2 1];
        % opts.LowerBound = [0 0 0 0 0 0];
        % opts.UpperBound = [10 10 10 10 10 10];
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

    typename = unique(data.TrialType);
    for j=1:length(typename)
        t = struct;
        
        t.Subject = data.Subject(1);
        t.Group = data.Group(1);
        t.Experiment = data.Experiment(1);
        t.Task = data.Task(1);
        if ~multiSession
            t.Session = data.Session(1);
            t.Date = data.Date(1);
            t.DateTime = data.DateTime(1);
        else
            t.nSession = length(unique(data.Session));
        end
        
        t.TrialType = typename(j);
        tdata = data(data.TrialType==t.TrialType,:);
        
        if ~multiSession
            t.nBlock = length(unique(tdata.BlockNum));
        else
            nBlk = 0;
            uniSession = unique(tdata.Session);
            for iBlk=1:length(uniSession)
                nBlk = nBlk + length(unique(tdata(tdata.Session==uniSession(iBlk),:).BlockNum));
            end
        end
        
        t.nTrial = length(tdata.iTrial);
        t.Dark = sum(tdata.DarkTry);
        t.rTrial = t.nTrial./(t.Dark+t.nTrial);

        idxCor = contains(tdata.Outcome,'Cor');
        idxPre = contains(tdata.Outcome,'Pre');
        idxLate = contains(tdata.Outcome,'Late');
        t.Cor  = sum(idxCor)./t.nTrial;
        t.Pre  = sum(idxPre)./t.nTrial;
        t.Late = sum(idxLate)./t.nTrial;
        t.PreTendency = (t.Pre-t.Late)./(t.Pre+t.Late);

        if ~multiSession
            t.maxFP = max(tdata.FP);
            t.t2mFP = find(tdata.FP==t.maxFP,1,'first');
            t.minRW = min(tdata.RW);
            t.t2mRW = find(tdata.RW==t.minRW,1,'first');
            switch string(t.Task)
                case "AutoShaping"
                    t2c = NaN;
                    t2cInv = NaN;
                    t.t2mRW = NaN;
                case "Wait1"
                    t2c = find(abs(data.FP-1.5)<1e-4,1,'first');
                    if ~isempty(t2c)
                        t2cInv = 1./t2c;
                    else
                        t2c = NaN;
                        t2cInv = 0;
                    end
                case "Wait2"
                    t2c = find(abs(data.FP-1.5)<1e-4 & abs(data.RW-0.6)<1e-4,1,'first');
                    if ~isempty(t2c)
                        t2cInv = 1./t2c;
                    else
                        t2c = NaN;
                        t2cInv = 0;
                    end
                case "3FPs"
                    t2c = NaN;
                    t2cInv = NaN;
            end
            t.t2c = t2c;
            t.t2cInv = t2cInv;
        end
        
        t.HT = median(rmoutliers(tdata.HT,'quartiles'),'omitnan');
        rt = calRT(tdata.HT(idxCor), tdata.FP(idxCor),...
            'Remove100ms', 1, 'RemoveOutliers', 1, 'ToPlot', 0, 'Calse', 0);
        t.RT = rt.median;
        t.RT_IQR = diff(prctile(tdata.RT(idxCor), [25 75]));
        relt = calRT(tdata.HT(idxCor|idxLate), tdata.FP(idxCor|idxLate),...
            'Remove100ms', 1, 'RemoveOutliers', 1, 'ToPlot', 0, 'Calse', 0);
        t.RelT = relt.median;
        t.RelT_IQR = diff(prctile(tdata.HT(idxCor|idxLate)-tdata.FP(idxCor|idxLate), [25 75]));
        t.MT = median(rmoutliers(tdata.MT,'quartiles'),'omitnan');

        idxPostCor = [0;idxCor(1:end-1)];
        idxPostPre = [0;idxPre(1:end-1)];
        idxPostLate = [0;idxLate(1:end-1)];
        idxPostError = idxPostPre | idxPostLate;
        rt_postcor = calRT(tdata.HT(idxCor & idxPostCor), tdata.FP(idxCor & idxPostCor),...
            'Remove100ms', 1, 'RemoveOutliers', 1, 'ToPlot', 0, 'Calse', 0);
        t.RT_postCor = rt_postcor.median;
        rt_postpre = calRT(tdata.HT(idxCor & idxPostPre), tdata.FP(idxCor & idxPostPre),...
            'Remove100ms', 1, 'RemoveOutliers', 1, 'ToPlot', 0, 'Calse', 0);
        t.RT_postPre = rt_postpre.median;
        rt_postlate = calRT(tdata.HT(idxCor & idxPostLate), tdata.FP(idxCor & idxPostLate),...
            'Remove100ms', 1, 'RemoveOutliers', 1, 'ToPlot', 0, 'Calse', 0);
        t.RT_postLate = rt_postlate.median;
        rt_posterror = calRT(tdata.HT(idxCor & idxPostError), tdata.FP(idxCor & idxPostError),...
            'Remove100ms', 1, 'RemoveOutliers', 1, 'ToPlot', 0, 'Calse', 0);
        t.RT_postError = rt_posterror.median;

        % Stat in each FP
        corFP = []; preFP = []; lateFP = []; htFP = []; htiqr_FP = [];
        rtFP = []; rt95ci_FP = []; rtiqr_FP = []; reltFP = []; relt95ci_FP = []; reltiqr_FP = []; mtFP = [];
        for iFP = 1:length(fplist)
            if iFP == 1
                idxThis = (tdata.FP>=0) & (tdata.FP<=fplist(iFP));
            else
                idxThis = (tdata.FP<=fplist(iFP)) & (tdata.FP>fplist(iFP-1));
            end
            if sum(idxThis) == 0
                corFP = [corFP, 0];
                preFP = [preFP, 0];
                lateFP = [lateFP, 0];
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
                lateFP = [lateFP, sum(idxLate & idxThis)./sum(idxThis)];
                htFP = [htFP, median(rmoutliers(tdata.HT(idxThis),'quartiles'),'omitnan')];
                htiqr_FP = [htiqr_FP, iqr(tdata.HT(idxThis))];
                mtFP = [mtFP, median(rmoutliers(tdata.MT(idxThis),'quartiles'),'omitnan')];

                if opts.calRT95CI
                    rtt = calRT_95CI(tdata.HT(idxCor & idxThis), tdata.FP(idxCor & idxThis),...
                        'Remove100ms', 1, 'RemoveOutliers', 1, 'ToPlot', 0, 'Calse', 1);
                    rtFP = [rtFP, rtt.median(1)];
                    rt95ci_FP = [rt95ci_FP, rtt.median_95CI];
                    rtiqr_FP = [rtiqr_FP, iqr(tdata.RT(idxCor & idxThis))];
                    reltt = calRT_95CI(tdata.HT((idxCor|idxLate)&idxThis), tdata.FP((idxCor|idxLate)&idxThis),...
                        'Remove100ms', 1, 'RemoveOutliers', 1, 'ToPlot', 0, 'Calse', 1);
                    reltFP = [reltFP, reltt.median(1)];
                    relt95ci_FP = [relt95ci_FP, reltt.median_95CI];
                    reltiqr_FP = [reltiqr_FP, iqr(tdata.RelT((idxCor|idxLate) & idxThis))];
                else
                    rtt = calRT(tdata.HT(idxCor & idxThis), tdata.FP(idxCor & idxThis),...
                        'Remove100ms', 1, 'RemoveOutliers', 1, 'ToPlot', 0, 'Calse', 0);
                    rtFP = [rtFP, rtt.median];
                    rt95ci_FP = [rt95ci_FP, [NaN NaN]];
                    rtiqr_FP = [rtiqr_FP, diff(prctile(tdata.RT(idxCor & idxThis),[25 75]))];
                    reltt = calRT(tdata.HT((idxCor|idxLate)&idxThis), tdata.FP((idxCor|idxLate)&idxThis),...
                        'Remove100ms', 1, 'RemoveOutliers', 1, 'ToPlot', 0, 'Calse', 0);
                    reltFP = [reltFP, reltt.median];
                    relt95ci_FP = [relt95ci_FP, [NaN NaN]];
                    reltiqr_FP = [reltiqr_FP, diff(prctile(tdata.RelT((idxCor|idxLate) & idxThis), [25 75]))];
                end
            end
        end
        t.Cor_FP = corFP;
        t.Pre_FP = preFP;
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
            t.HTpdf = smoothdata(histcounts(tdata.HT,...
                opts.edges_HT,'Normalization','pdf'),2,'gaussian',opts.smoWin);
            t.RTpdf = smoothdata(histcounts(tdata.RT(idxCor),...
                opts.edges_RT,'Normalization','pdf'),2,'gaussian',opts.smoWin);
            t.RelTpdf = smoothdata(histcounts(tdata.HT(idxCor|idxLate)-tdata.FP(idxCor|idxLate),...
                opts.edges_RelT,'Normalization','pdf'),2,'gaussian',opts.smoWin);
            t.HTcdf = smoothdata(histcounts(tdata.HT,...
                opts.edges_HT,'Normalization','cdf'),2,'gaussian',opts.smoWin);
            t.RTcdf = smoothdata(histcounts(tdata.RT(idxCor),...
                opts.edges_RT,'Normalization','cdf'),2,'gaussian',opts.smoWin);
            t.RelTcdf = smoothdata(histcounts(tdata.HT(idxCor|idxLate)-tdata.FP(idxCor|idxLate),...
                opts.edges_RelT,'Normalization','cdf'),2,'gaussian',opts.smoWin);
            
            for iFP = 1:length(fplist)
                idxThis = tdata.FP==fplist(iFP);
                
                t.(['HTpdf_FP',num2str(iFP)]) = smoothdata(histcounts(tdata.HT(idxThis),...
                    opts.edges_HT,'Normalization','pdf'),2,'gaussian',opts.smoWin);
                t.(['RTpdf_FP',num2str(iFP)]) = smoothdata(histcounts(tdata.RT(idxCor&idxThis),...
                    opts.edges_RT,'Normalization','pdf'),2,'gaussian',opts.smoWin);
                t.(['RelTpdf_FP',num2str(iFP)]) = smoothdata(histcounts(tdata.HT((idxCor|idxLate)&idxThis)-...
                    tdata.FP((idxCor|idxLate)&idxThis),...
                    opts.edges_RelT,'Normalization','pdf'),2,'gaussian',opts.smoWin);
                t.(['HTcdf_FP',num2str(iFP)]) = smoothdata(histcounts(tdata.HT(idxThis),...
                    opts.edges_HT,'Normalization','cdf'),2,'gaussian',opts.smoWin);
                t.(['RTcdf_FP',num2str(iFP)]) = smoothdata(histcounts(tdata.RT(idxCor&idxThis),...
                    opts.edges_RT,'Normalization','cdf'),2,'gaussian',opts.smoWin);
                t.(['RelTcdf_FP',num2str(iFP)]) = smoothdata(histcounts(tdata.HT((idxCor|idxLate)&idxThis)-...
                    tdata.FP((idxCor|idxLate)&idxThis),...
                    opts.edges_RelT,'Normalization','cdf'),2,'gaussian',opts.smoWin);

                % x = opts.bins_HT;
                % y = t.(['HTpdf_FP', num2str(iFP)]);
                % f = fit(x', y', opts.GaussEqn, ...
                %     'Start', opts.StartPoints, 'Lower', opts.LowerBound, 'Upper',opts.UpperBound);
                % t.(['HTpdf_FP_GaussFWHM',num2str(iFP)]) = cmptFWHM(f, opts.edges_HT);
            end

        end
        
        stat = [stat;struct2table(t)];
    end
end