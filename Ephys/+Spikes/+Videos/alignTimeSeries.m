function [alignedData, validTrials] = alignTimeSeries(data, time, tEvent, tPre, tPost)
    % Inputs:
    %   data:       Matrix (time points x trials) of location data
    %   time:       Vector (time points x 1) shared across trials
    %   tEvent:     Vector (trials x 1) of event times
    %   tPre:       Time before event (scalar)
    %   tPost:      Time after event (scalar)
    %
    % Output:
    %   alignedData: 3D array (trials x segment time points x 1)
    % JY 2025 with GROK 
    % initially devloped to align paw rising data to the moment of crossing
    % a time point.  

    % Determine segment length based on tPre and tPost
    segmentTime = (tPre:1:tPost); % 1 ms segment
    nSegmentPoints = length(segmentTime);

    % Filter out trials where tEvent is NaN
    validTrials = ~isnan(tEvent);
    data = data(validTrials, :);
    tEvent = tEvent(validTrials);
    nValidTrials = sum(validTrials);

    % Preallocate output (trials x segment points x 1)
    alignedData = NaN(nValidTrials, nSegmentPoints, 1);
    % Process each trial
    for i = 1:nValidTrials
        time_ = time-tEvent(i);
        data_i = data(i, :);
        % Interpolate or match data_i onto segmentTime
        % Use interp1 to map data_i from time_ to segmentTime
        data_interp = interp1(time_, data_i, segmentTime, 'linear', NaN);
        alignedData(i, :, 1) = data_interp;
        % if data_interp(find(~isnan(data_interp), 1, 'first')) <200
        %     sprintf('Attention, trial %2.0d', i)
        % end
     end
end