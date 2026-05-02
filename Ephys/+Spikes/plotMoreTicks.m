function h_morePokeLines = plotMoreTicks(ax, k0, event_time, col)

if ~isempty(cell2mat(event_time'))
    nTrial = numel(event_time);

    kVec = k0 + (0:nTrial-1);
    yTop    = -kVec;
    yBottom = 1 - kVec;

    % count pokes per trial
    nP = cellfun(@numel, event_time);

    % concatenate all poke times into one vector
    x_all = [event_time{:}];
    x_all = x_all(:).';  % row

    % build matching y vectors by repeating each trial's yTop/yBottom
    y1_all = repelem(yTop,    nP);
    y2_all = repelem(yBottom, nP);

    X = [x_all; x_all; nan(1, numel(x_all))];
    Y = [y1_all; y2_all; nan(1, numel(x_all))];

    h_morePokeLines = line(ax, X(:), Y(:), ...
        'Color', col, 'LineWidth', 2);
end
