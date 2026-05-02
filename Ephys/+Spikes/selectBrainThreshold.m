function [selected_ind, selected_ycoords] = selectBrainThreshold(unit_ycoords, unit_spike_width, PeaktoTroughRatio, unit_spike_height, mean_waveformAll,brain, nplot)
% SELECTBRAINTHRESHOLD Interactive selection of brain region boundary with visual feedback
%
% Inputs/Outputs: (same as before)

% Set default nplot if not provided
if nargin < 7
    nplot = 7;
end

% Create main figure with larger height to accommodate click markers
fig_ycoords = figure('Units', 'centimeters', 'Position', [1, 1, 25, 20]);

% Create three axes as specified with extra space
ax1 = axes('Parent', fig_ycoords, 'Units', 'centimeters', 'Position', [2, 14, 20, 5]);
plot(ax1, unit_ycoords, unit_spike_width, 'ko');
xlim(ax1, [min(unit_ycoords)-500, max(unit_ycoords)+500]);
ylabel('Trough-to-peak (ms)');
title(['Click twice to set threshold range of', '  --',brain,'--'],'FontSize', 15);

ax2 = axes('Parent', fig_ycoords, 'Units', 'centimeters', 'Position', [2, 9, 20, 5]);
plot(ax2, unit_ycoords, PeaktoTroughRatio, 'ko');
xlim(ax2, [min(unit_ycoords)-500, max(unit_ycoords)+500]);
ylim([0 1]);
ylabel('Peak/trough ratio');

ax3 = axes('Parent', fig_ycoords, 'Units', 'centimeters', 'Position', [2, 4, 20, 5]);
plot(ax3, unit_ycoords, unit_spike_height(2,:), 'ko');
xlim(ax3, [min(unit_ycoords)-500, max(unit_ycoords)+500]);
ylim([-1000 0]);
xlabel('Y coord (um)');
ylabel('Rrough height (uV)');

disp(['Click on any axis to set threshold point1 of', '  --',brain,'--']);
[click_x, ~] = ginput(1);
thr1 = click_x;

% Draw vertical reference line (optional)
hold on;
for ax = [ax1, ax2, ax3]
    line(ax, [thr1 thr1], ylim(ax), 'LineStyle', ':', 'LineWidth', 2, 'Color', 'r');
end


disp(['Click on any axis to set threshold point2 of', '  --',brain,'--']);
[click_x, ~] = ginput(1);
thr2 = click_x;
for ax = [ax1, ax2, ax3]
    line(ax, [thr2 thr2], ylim(ax), 'LineStyle', ':', 'LineWidth', 2, 'Color', 'r');
end
hold off;
drawnow;

thr = sort([thr1 thr2]);
final_thrY = zeros(1,2);
final_thrInd = zeros(1,2);
for i = 1 : 2
    has_left_data = any(unit_ycoords < thr(i));
    has_right_data = any(unit_ycoords > thr(i));
    if has_left_data && has_right_data
        continue_dividing = true;
        [sort_ycoords, sort_ycoords_idx] = sort(unit_ycoords);

        LeftIndex = find(unit_ycoords < thr(i)', 1, 'last' );
        LeftIndex_sort = find(sort_ycoords < thr(i)', 1, 'last' );
        % if NPtype>1
        %     LeftIndex = LeftIndex_sort;
        % end

        while continue_dividing
            LeftIndex = sort_ycoords_idx(LeftIndex_sort);
            final_thrY(i) = unit_ycoords(LeftIndex);
            final_thrInd(i) = sort_ycoords_idx(LeftIndex_sort);
            % all_indices = LeftIndex-nplot+1:LeftIndex+nplot;
            all_indices_sort = LeftIndex_sort-nplot+1:LeftIndex_sort+nplot;
            all_indices_sort = all_indices_sort(all_indices_sort>0);
            all_indices = sort_ycoords_idx(all_indices_sort);
            % used_unit_ycoords = unit_ycoords(all_indices);
            % used_mean_waveformAll = mean_waveformAll(all_indices,:);
            % all_indices = sort_ycoords_idx(all_indices_sort);
            % Create verification figure
            waveform_fig = createWaveformFigure(unit_ycoords, mean_waveformAll, all_indices, nplot, all_indices_sort, LeftIndex_sort,brain);
            disp(['Click in verification figure to confirm or re-select', '  --',brain,'--']);
            [confirm_x, ~] = ginput(1);
            if floor(confirm_x) == LeftIndex_sort
                disp('Division confirmed');
                continue_dividing = false;
                savename = ['waveform_select_' brain,'.png'];
                exportgraphics(waveform_fig, savename, ...
                    'Resolution', 300, ...
                    'ContentType', 'auto', ...
                    'BackgroundColor', 'white');
                close(waveform_fig); % Close previous waveform figure
            else
                % Update threshold and continue
                LeftIndex_sort = floor(confirm_x);
                % thr_s = click_x2;
                close(waveform_fig); % Close previous waveform figure
            end


        end

    else
        [~, final_thrInd(i)] = min(abs(unit_ycoords-thr(i)));

        final_thrY(i) = unit_ycoords(final_thrInd(i));

    end
end

final_thrY = sort(final_thrY);
if ~isequal(final_thrY(1),final_thrY(2))
    if strcmp(brain, 'Striatum')
        final_thrY = [final_thrY(1)-1 final_thrY(2)+1];
    elseif strcmp(brain, 'Cortex')
        final_thrY = [final_thrY(1)-1 final_thrY(2)+1];
    end
end

final_thrInd = sort(final_thrInd);
% Clean up and prepare outputs

saveas(fig_ycoords, ['UnitDistribution_' brain,'.png']);
close(fig_ycoords);

selected_ycoords = unit_ycoords(unit_ycoords > final_thrY(1) & unit_ycoords < final_thrY(2));
selected_ind = find(unit_ycoords > final_thrY(1) & unit_ycoords < final_thrY(2));
% disp(['Final boundary index: ', num2str(maxStritumIndex)]);
disp(['Choose','--',brain,'--',' Y coord: [', num2str(final_thrY),']']);
end

%% Helper function to create waveform figure
function fig = createWaveformFigure(unit_ycoords, mean_waveformAll, all_indices, nplot, all_indices_sort, LeftIndex_sort, brain)
% Fixed layout parameters (all units in centimeters)
fixedSubplotWidth = 3;
fixedSubplotHeight = 2.5;
horizontalGap = 0.5;
verticalGap = 1;
bottomPlotHeight = 4;

% Calculate figure size
nCols = min(2*nplot, length(all_indices));
totalPlotWidth = nCols*fixedSubplotWidth + (nCols-1)*horizontalGap;
figWidth = totalPlotWidth + 4;
figHeight = fixedSubplotHeight + bottomPlotHeight + verticalGap + 2;

% Create figure
fig = figure('Name', 'Neural Waveforms', 'Units', 'centimeters',...
    'Position', [0.5, 2, figWidth, figHeight]);

% Convert positions to normalized coordinates
leftStart = 2/figWidth;
bottomStartTop = (1 + bottomPlotHeight + verticalGap)/figHeight;

% Plot individual waveforms
y_lim = [min(min(mean_waveformAll(all_indices, :))) max(max(mean_waveformAll(all_indices, :)))];
for i = 1:nCols
    posX_cm = 2 + (i-1)*(fixedSubplotWidth + horizontalGap);
    posY_cm = 1 + bottomPlotHeight + verticalGap;

    posX = posX_cm/figWidth;
    posY = posY_cm/figHeight;
    width = fixedSubplotWidth/figWidth;
    height = fixedSubplotHeight/figHeight;

    subplot('Position', [posX, posY, width, height]);
    plot(mean_waveformAll(all_indices(i), :), 'k', 'LineWidth', 1);
    title(sprintf('Idx:%d\nY:%.1f', all_indices(i), unit_ycoords(all_indices(i))), 'FontSize', 8);
    ylim(y_lim);
    % axis tight;
    box on;
    if i==1
        set(gca, 'XTick', []);%, 'YTick', []
    else
        set(gca, 'XTick', [], 'YTick', []);%
    end
end

% Bottom overview plot
subplot('Position', [leftStart, 1/figHeight, totalPlotWidth/figWidth, bottomPlotHeight/figHeight]);
hold on;

% Plot data
scatter(all_indices_sort, unit_ycoords(all_indices), 40, 'k', 'filled');

for i = 1:length(all_indices)
    line([all_indices_sort(i), all_indices_sort(i)], [0, unit_ycoords(all_indices(i))],...
        'Color', [0.8 0.8 0.8], 'LineStyle', '--');
end

% Add threshold line

thresholdX = LeftIndex_sort + 0.5;
xline(thresholdX, '--', 'Color', 'b', 'LineWidth', 1.5);
text(thresholdX, max(ylim)*0.9, 'Threshold', ...
    'Color', 'b', 'FontSize', 9, ...
    'HorizontalAlignment', 'center', ...
    'BackgroundColor', [1 1 1 0.7]);

xlabel('Neuron Index');
ylabel('Y Coordinate (μm)');
title(['Click between lines to confirm', ' --',brain,'--'],'FontSize', 15);
grid on;
box on;

ylim([min(unit_ycoords(all_indices))-100, max(unit_ycoords(all_indices))+100]);
xlim([min(all_indices_sort)-0.5, max(all_indices_sort)+0.5]);
xticks(all_indices_sort)
xticklabels(all_indices)
end