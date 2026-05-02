function new_cmap = resizeColormap(original_cmap, new_length)
    % 将colormap调整到指定长度
    x_original = linspace(0, 1, size(original_cmap, 1));
    x_target = linspace(0, 1, new_length);
    
    new_cmap = zeros(new_length, 3);
    for i = 1:3
        new_cmap(:, i) = interp1(x_original, original_cmap(:, i), x_target, 'linear');
    end
end