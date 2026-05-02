function indout = findseqmatchWXN(seq_mom, seq_son, toprint, toprintname, split_flag, align_first_to)
% FINDSEQMATCHWXN Finds matching indices between two sequences with gap handling
%
% This function aligns two sequences (seq_mom and seq_son) by finding the best
% matching positions in seq_mom for each point in seq_son. It handles gaps in
% seq_mom by potentially splitting the alignment into multiple segments.
%
% Inputs:
%   seq_mom     - Master sequence (may contain gaps/interruptions)
%   seq_son     - Subsequence to be matched against seq_mom
%   toprint     - Flag to enable visualization (0/1)
%   toprintname - Filename to save visualization
%   split_flag  - Maximum number of segments allowed (default=1)
%   align_first_to - (Optional) Force seq_son(1) to align to seq_mom(k)
%
% Output:
%   indout      - Indices in seq_mom that correspond to seq_son points

%% Input Parameter Handling
if nargin < 3
    toprint = 0;        % Default: no visualization
    toprintname = [];   % Default: no save filename
end
if nargin < 5
    split_flag = 1;     % Default: single segment matching
end
if nargin < 6
    align_first_to = 0; % Default: no forced alignment
end

%% Core Matching Function
    function [indout, min_error] = original_match(seq_mom, seq_son, force_align_idx)
    % ORIGINAL_MATCH Finds best alignment between two sequences
    %
    % Inputs:
    %   seq_mom - mother sequence (reference)
    %   seq_son - son sequence (to be aligned)
    %   force_align_idx - (Optional) Force alignment to specific starting index
    %
    % Outputs:
    %   indout - best matching indices in seq_mom for seq_son
    %   min_error - minimum alignment error
    
    if nargin < 3
        force_align_idx = 0; % Default: no forced alignment
    end
    
    % Initialize outputs
    indout = zeros(1, length(seq_son));
    
    if force_align_idx > 0
        % Forced alignment mode: use specified starting index
        min_error = 0;
        min_k = force_align_idx;
        
        % Validate the forced alignment index
        if min_k > length(seq_mom) || min_k < 1
            error('Forced alignment index %d is out of range [1, %d]', min_k, length(seq_mom));
        end
    else
        % Search mode: find best starting position
        min_error = 1e8;
        min_k = 0;
        
        for k = 1:length(seq_mom)
            % Align sequences
            tmp_t1 = seq_son - seq_son(1) + seq_mom(k);
            tmp_sum = 0;
            
            % Calculate alignment error
            for i = 1:length(tmp_t1)
                [l, r] = binary_search(seq_mom, tmp_t1(i));
                tmp_sum = tmp_sum + min(abs(seq_mom(r)-tmp_t1(i)), abs(tmp_t1(i)-seq_mom(l)));
            end
            
            % Update best match
            if tmp_sum < min_error 
                min_error = tmp_sum;
                min_k = k;
            end
        end
    end
    
    % Final alignment
    tmp_t1 = seq_son - seq_son(1) + seq_mom(min_k);
    indout = find_all_matches(seq_mom, tmp_t1);
end

function [l, r] = binary_search(seq, value)
    % Binary search helper function
    l = 1;
    r = length(seq);
    
    if seq(l) >= value
        r = l;
    elseif seq(r) <= value
        l = r;
    else
        while r - l > 1
            tmp_idx = round((l + r) / 2);
            if seq(tmp_idx) - value > 0
                r = tmp_idx;
            else
                l = tmp_idx;
            end
        end
    end
end

function indices = find_all_matches(seq_mom, aligned_seq)
    % Find matches for all points
    indices = zeros(1, length(aligned_seq));
    for i = 1:length(aligned_seq)
        [l, r] = binary_search(seq_mom, aligned_seq(i));
        if abs(seq_mom(r) - aligned_seq(i)) > abs(aligned_seq(i) - seq_mom(l))
            indices(i) = l;
        else
            indices(i) = r;
        end
    end
end

function is_continuous = check_continuity(indices)
    % Check if indices are continuous and non-repeating
    if length(indices) <= 1
        is_continuous = true;
        return;
    end
    
    % Check for duplicates
    if length(unique(indices)) ~= length(indices)
        is_continuous = false;
        return;
    end
    
    % Check if indices are strictly increasing by 1
    diffs = diff(indices);
    is_continuous = all(diffs == 1);
end

function first_discontinuity = find_first_discontinuity(indices)
    % Find the first position where indices become discontinuous
    if length(indices) <= 1
        first_discontinuity = length(indices) + 1; % No discontinuity
        return;
    end
    
    for i = 2:length(indices)
        if indices(i) ~= indices(i-1) + 1
            first_discontinuity = i;
            return;
        end
    end
    
    first_discontinuity = length(indices) + 1; % All continuous
end

function forced_indout = forced_alignment(seq_mom, seq_son, align_idx)
    % Direct forced alignment by simple translation
    % seq_son(1) is forced to align with seq_mom(align_idx)
    
    % Calculate the translation vector
    translation = seq_mom(align_idx) - seq_son(1);
    
    % Translate the entire son sequence
    aligned_seq = seq_son + translation;
    
    % Find the closest matches in mother sequence
    forced_indout = find_all_matches(seq_mom, aligned_seq);
end

%% Main Matching Process with Dynamic Segmentation
% Initialize variables
indout = zeros(1, length(seq_son));     % Final output indices
remaining_mom = seq_mom;                % Remaining portion of master sequence
remaining_son = seq_son;                % Remaining portion of subsequence
son_offset = 0;                         % Offset in original seq_son
segments = {};                          % Cell array to store segments
current_segment = 1;                    % Current segment counter

% Handle gap reduction if split_flag is 2
gaps = diff(seq_mom);
[max_gap, max_gap_idx] = max(gaps);
[sorted_gaps, sorted_indices] = sort(gaps, 'descend');
if split_flag == 2    
    remaining_mom(max_gap_idx+1:end) = remaining_mom(max_gap_idx+1:end) - max_gap + 1;
end

% 如果有指定对齐位置，先进行强制对齐测试
if align_first_to > 0
    % fprintf('=== 第一步：强制对齐测试 ===\n');
    % fprintf('强制对齐: seq_son(1) -> seq_mom(%d)\n', align_first_to);
    
    % 直接进行强制对齐（简单平移）
    test_indout = forced_alignment(seq_mom, seq_son, align_first_to);
    
    % 检查连续性
    is_continuous = check_continuity(test_indout);
    first_discontinuity = find_first_discontinuity(test_indout);
    
    % fprintf('连续性检查: %s\n', string(is_continuous));
    % fprintf('第一个不连续点位置: %d\n', first_discontinuity);
    
    if is_continuous
        % 如果完全连续，直接使用这个结果
        % fprintf('✓ 强制对齐产生连续结果，直接采用\n');
        indout = test_indout;
        
        % 记录为单个段
        segments{1}.indices = test_indout;
        segments{1}.son_range = [1, length(seq_son)];
        
    else
        % 如果存在不连续，使用连续部分，从不连续点开始重新对齐
        % fprintf('→ 存在不连续，使用前%d个连续点，从第%d点开始重新对齐\n', ...
        %         first_discontinuity-1, first_discontinuity);
        
        % 第一段：连续部分
        continuous_part = 1:(first_discontinuity-1);
        if ~isempty(continuous_part)
            segments{1}.indices = test_indout(continuous_part);
            segments{1}.son_range = [1, length(continuous_part)];
            
            % 更新剩余序列
            remaining_mom = seq_mom(test_indout(first_discontinuity-1)+1:end);
            remaining_son = seq_son(first_discontinuity:end);
            son_offset = length(continuous_part);
            current_segment = 2;
            
            % fprintf('第一段: 点%d-%d -> 索引%s\n', 1, length(continuous_part), ...
            %         mat2str(segments{1}.indices));
        end
    end
end

% Continue matching until all segments processed or max segments reached
while current_segment <= split_flag && ~isempty(remaining_son) && ~(align_first_to > 0 && current_segment == 1)
    % 确定是否对此段应用强制对齐（只有第一段且没有进行过强制对齐测试）
    if current_segment == 1 && align_first_to > 0 && isempty(segments)
        segment_force_align = align_first_to;
        % fprintf('第一段强制对齐到索引 %d\n', segment_force_align);
    else
        segment_force_align = 0; % 后续段自动匹配
        % fprintf('第%d段自动匹配\n', current_segment);
    end
    
    % 对当前段进行匹配
    [current_indout, ~] = original_match(remaining_mom, remaining_son, segment_force_align);
    
    % fprintf('第%d段匹配结果: %s\n', current_segment, mat2str(current_indout));
    
    % 检测不连续性（潜在间隙）
    gap_found = false;
    split_point = length(current_indout); % 默认：使用整个段
    
    for i = 2:length(current_indout)
        % 检查索引是否不连续（允许缺失点）
        if current_indout(i) ~= current_indout(i-1)+1
            split_point = i-1;  % 不连续前的最后一个点
            gap_found = true;
            % fprintf('在第%d点发现不连续 (索引 %d -> %d)\n', i, current_indout(i-1), current_indout(i));
            break;
        end
    end
    
    % 如果发现间隙且允许更多段，则进行分段
    if gap_found && current_segment < split_flag
        % 存储当前段信息
        global_start_idx = length(seq_mom) - length(remaining_mom);
        segments{current_segment}.indices = current_indout(1:split_point) + global_start_idx;
        segments{current_segment}.son_range = [son_offset+1, son_offset+split_point];
        
        % fprintf('分段: 第%d段包含点%d-%d -> 索引%s\n', current_segment, ...
        %         son_offset+1, son_offset+split_point, mat2str(segments{current_segment}.indices));
        
        % 为下一段更新剩余序列
        if current_indout(split_point) < length(remaining_mom)
            remaining_mom = remaining_mom(current_indout(split_point)+1:end);
            remaining_son = remaining_son(split_point+1:end);
            son_offset = son_offset + split_point;
            current_segment = current_segment + 1;
        else
            % fprintf('已到达母序列末尾，停止分段\n');
            break;
        end
    else
        % 无更多间隙或达到最大段数 - 最终段
        global_start_idx = length(seq_mom) - length(remaining_mom);
        segments{current_segment}.indices = current_indout + global_start_idx;
        segments{current_segment}.son_range = [son_offset+1, son_offset+length(remaining_son)];
        
        % fprintf('最终段: 第%d段包含点%d-%d -> 索引%s\n', current_segment, ...
        %         son_offset+1, son_offset+length(remaining_son), mat2str(segments{current_segment}.indices));
        break;
    end
end

%% 合并所有段
% fprintf('=== 合并所有段 ===\n');
for seg = 1:length(segments)
    % 获取此段在seq_son中的起始和结束索引
    start_idx = segments{seg}.son_range(1);
    end_idx = segments{seg}.son_range(2);
    
    % 存储匹配的索引
    indout(start_idx:end_idx) = segments{seg}.indices;
    
    % fprintf('段%d: son点%d-%d -> mom索引%s\n', seg, start_idx, end_idx, ...
    %         mat2str(segments{seg}.indices));
end

%% 处理缺失点（填充未匹配索引）
unmatched_points = find(indout == 0);
if ~isempty(unmatched_points)
    % fprintf('发现%d个未匹配点，进行填充\n', length(unmatched_points));
    
    for i = unmatched_points
        % 找到最近的匹配点（左和右）
        left = find(indout(1:i) > 0, 1, 'last');
        right = find(indout(i:end) > 0, 1, 'first');
        if ~isempty(right)
            right = right + i - 1;
        end
        
        % 处理边界情况
        if isempty(left) && isempty(right)
            indout(i) = 1;  % 无匹配，默认为第一个点
        elseif isempty(left)
            indout(i) = indout(right);  % 仅存在右匹配
        elseif isempty(right)
            indout(i) = indout(left);   % 仅存在左匹配
        else
            % 选择最近的匹配（左或右）
            if (i - left) < (right - i)
                indout(i) = indout(left);
            else
                indout(i) = indout(right);
            end
        end
    end
end

% fprintf('最终匹配结果: %s\n', mat2str(indout));

%% Visualization

hf = figure(88); clf(hf)
set(hf, 'Position', [100, 100, 800, 900]);

% Plot 1: Original Data Points
subplot(3,1,1);
hold on;
% Master sequence (top line)
scatter(seq_mom, repmat(2,1,length(seq_mom)), 30, 'b', 'o');
% Subsequence (bottom line)
scatter(seq_son, repmat(1,1,length(seq_son)), 30, 'k', 'o');

% Mark forced alignment if specified
if align_first_to > 0
    scatter(seq_mom(align_first_to), 2, 100, 'r', 'x', 'LineWidth', 2);
    text(seq_mom(align_first_to), 2.1, 'Forced Start', 'Color', 'r', ...
         'HorizontalAlignment', 'center');
end

ylim([0 3]);
set(gca, 'YTick', [1 2], 'YTickLabel', {'seq\_son', 'seq\_mom'});
title('Original Data Points (red X = forced alignment)');
grid on;

% Plot 2: Aligned Points
subplot(3,1,2);
hold on;
% Master sequence
scatter(seq_mom, repmat(2,1,length(seq_mom)), 30, 'b', 'o');
% Aligned subsequence
scatter(seq_mom(indout), repmat(1,1,length(indout)), 30, 'k', 'o');

% Color different segments if they exist
if length(segments) > 1
    colors = lines(length(segments));
    for seg = 1:length(segments)
        idx = segments{seg}.son_range(1):segments{seg}.son_range(2);
        scatter(seq_mom(indout(idx)), repmat(1,1,length(idx)), 30, colors(seg,:), 'o');
    end
end

ylim([0 3]);
set(gca, 'YTick', [1 2], 'YTickLabel', {'aligned seq\_son', 'seq\_mom'});
title('Aligned Points (colors show different segments)');
grid on;

% Plot 3: Connection Lines
subplot(3,1,3);
hold on;
% Plot both sequences
scatter(seq_mom, repmat(2,1,length(seq_mom)), 30, 'b', 'o');
scatter(seq_son, repmat(1,1,length(seq_son)), 30, 'k', 'o');

% Draw connection lines between matched points
for i = 1:length(indout)
    % Gray lines for consecutive matches, blue for discontinuous
    if i > 1 && indout(i) == indout(i-1)+1
        line_color = [0.7 0.7 0.7]; % Gray = continuous
    else
        line_color = [0 0.5 0.8];   % Blue = discontinuous
    end
    line([seq_mom(indout(i)), seq_son(i)], [2, 1], 'Color', line_color);
end

ylim([0 3]);
set(gca, 'YTick', [1 2], 'YTickLabel', {'seq\_son', 'seq\_mom'});
title('Connection Lines (gray=continuous, blue=discontinuous)');
grid on;

if toprint
    % Save figure if filename provided
    if ~isempty(toprintname)
        print(gcf, '-dpng', toprintname);
    end
end

end