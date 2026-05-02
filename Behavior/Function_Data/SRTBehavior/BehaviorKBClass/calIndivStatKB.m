function stat = calIndivStatKB(data,multiSession,opts)
% calculate the STATs of one subject
% STATs of 1 session or across sessions (but in the same Experiment & Task)
    arguments
        data
        multiSession    = false
        opts.cuelist    = unique(data.Cue)
        opts.ifDistr    = false
        opts.edges_HT   = 0:0.05:3 % Hold time (All trials)
        opts.bins_HT    = 0.025:0.05:2.975
        opts.edges_RT   = 0:0.05:1 % Reaction time (Cor)
        opts.edges_RelT = 0:0.05:1 % Release time (Cor+Late)
        opts.smoWin     = 8 % smoothdata('gaussian')
    end

    cuelist = opts.cuelist;
    
    stat = table;  t = struct;

    t.Subject = data.Subject(1);
    t.Group = data.Group(1);
    t.Experiment = data.Experiment(1);
    t.Task = data.Task(1);
    if ~multiSession
        t.Session  = data.Session(1);
        t.Date     = data.Date(1);
    else
        t.nSession = length(unique(data.Session));
    end
    t.nTrial = length(data.iTrial);
    t.Dark = sum(data.DarkTry);
    t.DarkRatio = t.nTrial./(t.Dark+t.nTrial);

    idxCor  = data.Outcome == "Cor";
    idxPre  = data.Outcome == "Pre";
    idxLate = data.Outcome == "Late";
    t.Cor   = sum(idxCor)./t.nTrial;
    t.Pre   = sum(idxPre)./t.nTrial;
    t.Late  = sum(idxLate)./t.nTrial;
    
    t.HT = median(rmoutliers(data.HT,'quartiles'),'omitnan');
    t.HT_IQR = diff(prctile(data.HT, [25 75]));
    rt = calRT(data.HT(idxCor), data.FP(idxCor),...
        'Remove100ms', 0, 'RemoveOutliers', 1, 'ToPlot', 0, 'Calse', 0);
    t.RT = rt.median;
    t.RT_IQR = diff(prctile(data.RT(idxCor), [25 75]));
    relt = calRT(data.HT(idxCor|idxLate), data.FP(idxCor|idxLate),...
        'Remove100ms', 0, 'RemoveOutliers', 1, 'ToPlot', 0, 'Calse', 0);
    t.RelT = relt.median;
    t.RelT_IQR = diff(prctile(data.HT(idxCor|idxLate)-data.FP(idxCor|idxLate), [25 75]));
    t.MT = median(rmoutliers(data.MT,'quartiles'),'omitnan');

    % Stat in Cue/Uncue conditions, named var_KB rows corresponding to obj.CueOptions
    corKB = []; preKB = []; lateKB = []; htKB = []; htiqr_KB = [];
    rtKB = []; rtiqr_KB = []; reltKB = []; reltiqr_KB = []; mtKB = [];
    for i = 1:length(cuelist)
        idxThis = data.Cue == cuelist(i);
        if sum(idxThis) == 0
            corKB = [corKB, 0];
            preKB = [preKB, 0];
            lateKB = [lateKB, 0];
            htKB = [htKB, 0];
            htiqr_KB = [htiqr_KB, 0];
            rtKB = [rtKB, 0];
            rtiqr_KB = [rtiqr_KB, 0];
            reltKB = [reltKB, 0];
            reltiqr_KB = [reltiqr_KB, 0];
            mtKB = [mtKB, 0];
        else
            corKB = [corKB, sum(idxCor & idxThis)./sum(idxThis)];
            preKB = [preKB, sum(idxPre & idxThis)./sum(idxThis)];
            lateKB = [lateKB, sum(idxLate & idxThis)./sum(idxThis)];
            htKB = [htKB, median(rmoutliers(data.HT(idxThis),'quartiles'),'omitnan')];
            htiqr_KB = [htiqr_KB, iqr(data.HT(idxThis))];
            rtt = calRT(data.HT(idxCor & idxThis), data.FP(idxCor & idxThis),...
            'Remove100ms', 0, 'RemoveOutliers', 1, 'ToPlot', 0, 'Calse', 0);
            rtKB = [rtKB, rtt.median];
            rtiqr_KB = [rtiqr_KB, iqr(data.RT(idxCor & idxThis))];
            reltt = calRT(data.HT((idxCor|idxLate)&idxThis), data.FP((idxCor|idxLate)&idxThis),...
            'Remove100ms', 0, 'RemoveOutliers', 1, 'ToPlot', 0, 'Calse', 0);
            reltKB = [reltKB, reltt.median];
            reltiqr_KB = [reltiqr_KB, iqr(data.RelT((idxCor|idxLate) & idxThis))];
            mtKB = [mtKB, median(rmoutliers(data.MT(idxThis),'quartiles'),'omitnan')];
        end
    end
    t.Cor_KB = corKB;
    t.Pre_KB = preKB;
    t.Late_KB = lateKB;
    t.HT_KB = htKB;
    t.HT_IQR_KB = htiqr_KB;
    t.RT_KB = rtKB;
    t.RT_IQR_KB = rtiqr_KB;
    t.RelT_KB = reltKB;
    t.RelT_IQR_KB = reltiqr_KB;
    t.MT_KB = mtKB;

    % calculate distribution
    if opts.ifDistr
        t.HTpdf = smoothdata(histcounts(data.HT,...
            opts.edges_HT,'Normalization','pdf'),2,'gaussian',opts.smoWin);
        t.RTpdf = smoothdata(histcounts(data.RT(idxCor),...
            opts.edges_RT,'Normalization','pdf'),2,'gaussian',opts.smoWin);
        t.RelTpdf = smoothdata(histcounts(data.HT(idxCor|idxLate)-data.FP(idxCor|idxLate),...
            opts.edges_RelT,'Normalization','pdf'),2,'gaussian',opts.smoWin);
        t.HTcdf = smoothdata(histcounts(data.HT,...
            opts.edges_HT,'Normalization','cdf'),2,'gaussian',opts.smoWin);
        t.RTcdf = smoothdata(histcounts(data.RT(idxCor),...
            opts.edges_RT,'Normalization','cdf'),2,'gaussian',opts.smoWin);
        t.RelTcdf = smoothdata(histcounts(data.HT(idxCor|idxLate)-data.FP(idxCor|idxLate),...
            opts.edges_RelT,'Normalization','cdf'),2,'gaussian',opts.smoWin);
        
        for i = 1:length(cuelist)
            idxThis = data.Cue == cuelist(i);
            iCue = cuelist(i);
            
            t.("HTpdf_KB"+iCue) = smoothdata(histcounts(data.HT(idxThis),...
                opts.edges_HT,'Normalization','pdf'),2,'gaussian',opts.smoWin);
            t.("RTpdf_KB"+iCue) = smoothdata(histcounts(data.RT(idxCor&idxThis),...
                opts.edges_RT,'Normalization','pdf'),2,'gaussian',opts.smoWin);
            t.("RelTpdf_KB"+iCue) = smoothdata(histcounts(data.HT((idxCor|idxLate)&idxThis)-...
                data.FP((idxCor|idxLate)&idxThis),...
                opts.edges_RelT,'Normalization','pdf'),2,'gaussian',opts.smoWin);
            t.("HTcdf_KB"+iCue) = smoothdata(histcounts(data.HT(idxThis),...
                opts.edges_HT,'Normalization','cdf'),2,'gaussian',opts.smoWin);
            t.("RTcdf_KB"+iCue) = smoothdata(histcounts(data.RT(idxCor&idxThis),...
                opts.edges_RT,'Normalization','cdf'),2,'gaussian',opts.smoWin);
            t.("RelTcdf_KB"+iCue) = smoothdata(histcounts(data.HT((idxCor|idxLate)&idxThis)-...
                data.FP((idxCor|idxLate)&idxThis),...
                opts.edges_RelT,'Normalization','cdf'),2,'gaussian',opts.smoWin);
        end
    end
    stat = [stat;struct2table(t)];
end