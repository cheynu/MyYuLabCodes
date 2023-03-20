function med_ExpCompare3FPs_Individual(btAll,expVar,varargin)
p = inputParser;
addRequired(p,'btAll',@iscell);
addRequired(p,'expVar',@isstring);
addParameter(p,'plotRange',[]);
addParameter(p,'FPs',[0.5,1,1.5]);
addParameter(p,'smoWin',8);
addParameter(p,'edges_RT',0:0.025:0.6);
addParameter(p,'edges_RelT',0:0.05:1);
addParameter(p,'edges_HT',0:0.05:2.5);
parse(p,btAll,expVar,varargin{:});

param = p.Results;
%%
if ~isempty(param.plotRange)
    btAll_raw = btAll;
    btAll = btAll(param.plotRange);
    expVar = expVar(param.plotRange);
end
[SBS,TBT] = packData(btAll,param);



end
%% Functions
function [SBS,TBT] = packData(btAll,param)
SBS = table;
TBT = table;
for i=1:length(btAll)
    T = btAll{i};
    SBS = [SBS;estSBS(T)];
    TBT = [TBT;eraseWarmup(T)];
end

function outT = eraseWarmup(T)
    outT = table;
    if size(T,1)>1
        idxWU = find(abs(T.FP-max(param.FPs)-0.1)<1e-4,'last'); % warmup end
        if ~isempty(idxWU) && size(T,1)>idxWU
            outT = T((idxWU+1):end,:);
            outT = addvars(outT,repelem(i,size(outT,1))','After','Date','NewVariableNames','Session');
        end
    end
end

function outT = estSBS(T)
    outT = table;
    if isempty(T)
        return;
    end
    t = struct;
    t.Subject = T.Subject(1);
    t.Group = T.Group(1);
    t.Date = T.Date(1);
    t.Session = i;
    t.Task = T.Task(1);

    Tc = eraseWarmup(T);
    if isempty(Tc)
        tdata = T(T.Outcome~="Dark");
        t.nTrial = NaN;
        t.Dark = NaN;
        t.Cor = NaN;
        t.Pre = NaN;
        t.Late = NaN;
        t.Cor_S = NaN; t.Cor_M = NaN; t.Cor_L = NaN;
        t.Pre_S = NaN; t.Pre_M = NaN; t.Pre_L = NaN;
        t.Late_S = NaN; t.Late_M = NaN; t.Late_L = NaN;
        t.maxFP = max(tdata.FP);
        t.t2mFP = find(tdata.FP==t.maxFP,1,'first');
        t.minRW = NaN;
        t.t2mRW = NaN;
        t.HT = NaN;
        t.RT = NaN;
        outT = [outT;struct2table(t)];
        return;
    end
    tdata = Tc(Tc.Outcome~="Dark",:);
    t.nTrial = length(tdata.iTrial);
    t.Dark = sum(Tc.Outcome=="Dark")./size(Tc,1);
    t.Cor  = sum(tdata.Outcome=="Cor")./t.nTrial;
    t.Pre  = sum(tdata.Outcome=="Pre")./t.nTrial;
    t.Late = sum(tdata.Outcome=="Late")./t.nTrial;
    
    t.Cor_S = sum(tdata.Outcome=="Cor" & abs(tdata.FP-param.FPs(1))<1e-4)./sum(abs(tdata.FP-param.FPs(1))<1e-4);
    t.Cor_M = sum(tdata.Outcome=="Cor" & abs(tdata.FP-param.FPs(2))<1e-4)./sum(abs(tdata.FP-param.FPs(2))<1e-4);
    t.Cor_L = sum(tdata.Outcome=="Cor" & abs(tdata.FP-param.FPs(3))<1e-4)./sum(abs(tdata.FP-param.FPs(3))<1e-4);
    t.Pre_S = sum(tdata.Outcome=="Pre" & abs(tdata.FP-param.FPs(1))<1e-4)./sum(abs(tdata.FP-param.FPs(1))<1e-4);
    t.Pre_M = sum(tdata.Outcome=="Pre" & abs(tdata.FP-param.FPs(2))<1e-4)./sum(abs(tdata.FP-param.FPs(2))<1e-4);
    t.Pre_L = sum(tdata.Outcome=="Pre" & abs(tdata.FP-param.FPs(3))<1e-4)./sum(abs(tdata.FP-param.FPs(3))<1e-4);
    t.Late_S = sum(tdata.Outcome=="Late" & abs(tdata.FP-param.FPs(1))<1e-4)./sum(abs(tdata.FP-param.FPs(1))<1e-4);
    t.Late_M = sum(tdata.Outcome=="Late" & abs(tdata.FP-param.FPs(2))<1e-4)./sum(abs(tdata.FP-param.FPs(2))<1e-4);
    t.Late_L = sum(tdata.Outcome=="Late" & abs(tdata.FP-param.FPs(3))<1e-4)./sum(abs(tdata.FP-param.FPs(3))<1e-4);
    
    t.maxFP = max(tdata.FP);
    t.t2mFP = find(tdata.FP==t.maxFP,1,'first');
    t.minRW = min(tdata.RW);
    t.t2mRW = find(tdata.RW==t.minRW,1,'first');
    
    t.HT = median(rmoutliers(tdata.HT,'median'),'omitnan');
    t.RT = calRT(tdata(tdata.Outcome=="Cor",:).HT,tdata(tdata.Outcome=="Cor",:).FP,...
        'Remove100ms',true,'RemoveOutliers',true,'ToPlot','false','CalSE',false);
    outT = [outT;struct2table(t)];
end
end


