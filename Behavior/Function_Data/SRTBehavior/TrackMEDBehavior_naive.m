function [bout,bc] = TrackMEDBehavior_naive(filename, SessionType)

% Hanbo Wang Oct 2022
% e.g.:  TrackMEDBehavior_naive(filename, 'LeverPress');
% Track MED behavior data for AutoShaping, LeverPress and LeverRelease

% Revised from @track_training_progress_advanced (Jianing Yu Oct 2019)

SessionName  = strrep(filename(1:end-4), '_', '-');
tEvents       = med_to_tec_new(filename, 100);
bout.Metadata = med_to_protocol(filename);

%% Time of Tone and Reward
idxReward = find(tEvents(:, 2) == 13);
if isempty(idxReward)
    idxReward = find(tEvents(:, 2) == 18);
end
tReward = tEvents(idxReward, 1);

% LeverPress & LeverRelease will give free water after the first minute
tTone = tEvents(tEvents(:, 2) == 11, 1);
if tTone(1) > 60
    tTone(1)   = [];
    tReward(1) = [];
end

switch SessionType
    case 'AutoShaping'

        bout.CorrectIdx   = idxReward';

    case {'LeverPress', 'LeverRelease'}

        %% find out press-time
        tPress   = tEvents(tEvents(:, 2) == 1, 1);
        tRelease = tEvents(tEvents(:, 2) == 4, 1);

        if length(tRelease) < length(tPress) % final release was not registered before the session ended.
            tPress = tPress(1:end-1);
        end

        % press duration for each press, in ms
        if tRelease(1) < tPress(1)
            tRelease(1) = [];
        end

        if tRelease(end) < tPress(end)
            tPress(end) = [];
        end

        if length(tRelease) > length(tPress)
            tRelease(end) = [];
        end

        durPress = (tRelease-tPress)*1000; % Press duration
        nPress   = length(tPress);

        %% find out successful presses
        idxGoodPress = nan(length(tPress), 1);

        switch SessionType
            case 'LeverPress'
                tLever = tPress;
            case 'LeverRelease'
                tLever = tRelease;
        end

        for i = 1:nPress
            % Reward signal had 0.1s latency, and sometimes they just don't match exactly
            if ~isempty(find(abs(tReward - tLever(i) - 0.1) <= 0.001, 1))
                idxGoodPress(i) = i;
            end
        end
        idxGoodPress = idxGoodPress(~isnan(idxGoodPress));

        %% plot press duration
        figure(1); clf(1);
        set(gcf, 'unit', 'centimeters', 'position',[2 2 12 9], 'paperpositionmode', 'auto' );
        set(gca, 'nextplot', 'add', 'ylim', [0 2800], 'xlim', [0 3600])
        plot(tPress(idxGoodPress), durPress(idxGoodPress), 'o', 'linewidth', 1)
        xlabel('Time (s)');
        ylabel('Press duration (ms)');

        bout.PressTime    = tPress';
        bout.ReleaseTime  = tRelease';
        bout.CorrectIdx   = idxGoodPress';

end

%% save data
bout.Metadata = med_to_protocol(filename);
bout.SessionName  = SessionName;
bout.TimeTone     = tTone';
bout.MEDTTL       = tReward';

savename = ['B_' upper(bout.Metadata.SubjectName) '_' strrep(bout.Metadata.Date, '-', '_') '_' strrep(bout.Metadata.StartTime, ':', '')];
b = bout; bc = [];
save(savename, 'b');

[~,~] = mkdir('Fig');
savename = fullfile(pwd, 'Fig', savename);
print(gcf,'-dpng', savename);