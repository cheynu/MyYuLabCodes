function [s1_m, s2_m, idx1, idx2] = matchSeqOnsetOffset(s1, s2, max_duration)
    % s1_m: 结果等同于原始 s1 (去除了重复和乱序) (onset)
    % s2_m: 匹配到的 poke-out，找不到则为 NaN (offset)
    % idx1: 原始 s1 的索引
    % idx2: 原始 s2 的索引 (如果匹配到的话)，未匹配则为 NaN
    
    if nargin < 3, max_duration = Inf; end
    
    % 预处理：排序并记录原始索引
    [s1_sorted, sortIdx1] = sort(s1(:));
    [s2_sorted, sortIdx2] = sort(s2(:));
    
    L1 = length(s1_sorted);
    L2 = length(s2_sorted);
    
    % 初始化输出：长度与 s1 一致
    s1_m = s1_sorted;
    s2_m = nan(L1, 1);
    idx1 = sortIdx1;
    idx2 = nan(L1, 1);
    
    p2 = 1; % s2 的指针
    
    for i = 1:L1
        current_in = s1_sorted(i);
        
        % 1. 移动 p2 指针，跳过所有早于当前 in 的 out
        while p2 <= L2 && s2_sorted(p2) <= current_in
            p2 = p2 + 1;
        end
        
        % 2. 检查当前的 s2 是否属于当前的 in
        % 逻辑：s2 必须在当前 in 之后，且如果存在下一个 in，s2 必须在下一个 in 之前
        if p2 <= L2
            potential_out = s2_sorted(p2);
            duration = potential_out - current_in;
            
            % 判断该 s2 是否属于当前 in 的条件：
            % A. 时长在范围内
            % B. (重要) 如果有下一个 in，当前的 out 必须比下一个 in 更近或者在下一个 in 之前
            is_valid = (duration <= max_duration);
            
            if i < L1
                % 如果下一个 in 比当前的 out 还早，说明当前的 in 丢失了 out
                if s1_sorted(i+1) < potential_out
                    is_valid = false;
                end
            end
            
            if is_valid
                s2_m(i) = potential_out;
                idx2(i) = sortIdx2(p2);
                p2 = p2 + 1; % 匹配成功，s2 指针才后移
            end
        end
        % 如果不满足 is_valid，s2_m(i) 保持为 NaN
    end
end