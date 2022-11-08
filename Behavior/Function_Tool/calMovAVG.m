function [xo,yo] = calMovAVG(time,outcome,varargin)
pp = inputParser;
addRequired(pp,'time');
addRequired(pp,'outcome'); % logical vector / string array
addParameter(pp,'tarStr','Cor');
addParameter(pp,'winRatio',6);
addParameter(pp,'stepRatio',3);
addParameter(pp,'winSize',[]);
addParameter(pp,'stepSize',[]);
addParameter(pp,'avgMethod','mean',@(x)ismember(x,{'mean','median'}));
parse(pp,time,outcome,varargin{:});

tarStr = pp.Results.tarStr;
winRatio = pp.Results.winRatio;
stepRatio = pp.Results.stepRatio;
winSize = pp.Results.winSize;
stepSize = pp.Results.stepSize;
avgMethod = pp.Results.avgMethod;
%%
if ~isempty(winSize)
    win = winSize;
else
    win = floor(length(time)/winRatio);
end
if ~isempty(stepSize)
    step = stepSize;
else
    step = max(1,floor(win/stepRatio));
end

countStart = 1;
xo = [];
yo = [];
while countStart+win-1 <= length(time)
    thisWin = (countStart:countStart+win-1)';
    thisOutcome = outcome(thisWin);
    switch class(thisOutcome)
        case 'logical'
            yo = [yo; 100.*sum(thisOutcome)./length(thisOutcome)]; % 'Valid'
        case 'string'
            yo = [yo; 100.*sum(strcmp(thisOutcome,tarStr))./length(thisOutcome)]; % 'Valid'
        otherwise
            if isnumeric(thisOutcome)
                switch avgMethod
                    case 'mean'
                        yo = [yo; mean(thisOutcome,'omitnan')];
                    case 'median'
                        yo = [yo; median(thisOutcome,'omitnan')];
                end
            end
    end
    xo = [xo; time(round(median(thisWin)))];
    countStart = countStart + step;
end

end