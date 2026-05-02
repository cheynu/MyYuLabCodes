function [xo,yo] = calSlidWin(x, y, options)

% hbWang, Dec/2023, revised from @calMovAVG by Yu Chen

% This function calculate moving average within sliding windows, inputs(y)
% can be 2-dim matrix (value * subject), and the sliding direction can be
% forward or backward.
% Especially useful for @BehaviorSRT_*.Class

    arguments
        x                                = [] % index or time
        y                                = [] % var*subj
                                              % each column is a subject's beh var, e.g. reaction time
        % Direction: "Reverse" mode will calculate sliding window backward,
        %            but both mode return forward output
        options.Direction   string {mustBeMember(options.Direction, ["Norm", "Reverse"])} = "Norm"
        % Method: "Fixed" calculate within fixed window size and step size;
        %         "Ratio" modified window/step size by sample size and ratio
        options.Method      string {mustBeMember(options.Method,    ["Fixed", "Ratio"])}  = "Fixed"
        % AvgMethod: calculate yo using @mean or @median (xo ~ always @median)
        options.AvgMethod   string {mustBeMember(options.AvgMethod, ["Mean", "Median"])}  = "Mean"
        options.SmoothWin   (1,1) double = 40
        options.SmoothStep  (1,1) double = 10 % step for fixed mode
        options.SmoothRatio (1,1) double = 8
        options.SmoothStepR (1,1) double = 2 % step for ratio mode
    end

    % Determine win/step
    if options.Method == "Fixed"
        win = options.SmoothWin;
        step = options.SmoothStep;
    else
        win = round(length(x)/options.SmoothRatio);
        step = max(1,floor(win/options.SmoothStepR));
    end
    
    % Determine x
    if isempty(x)
        x = 1:length(y); xisidx = true; % x is just 1:n idx
    else
        xisidx = false; % x is meaningful
    end

    if options.Direction == "Reverse"
        x = flip(x);
        y = flipud(y);
    end

    % Calculate within sliding windows
    cnt = 1; xo = []; yo = [];
    while cnt+win-1 <= length(x)
        thisx = (cnt:cnt+win-1)';
        thisy = y(thisx,:);
        xo = [xo; median(thisx, "omitnan")]; %#ok<*AGROW>
        switch options.AvgMethod
            case "Mean"
                yo = [yo; mean(thisy, 1, "omitnan")];
            case "Median"
                yo = [yo; median(thisy, 1, "omitnan")];
        end
        cnt = cnt + step;
    end

    % Convert from index to value
    if ~xisidx
        xo = x(floor(xo));
    end

    if options.Direction == "Reverse"
        xo = flip(xo);
        yo = flipud(yo);
    end
    xo = reshape(xo, [], 1);
end