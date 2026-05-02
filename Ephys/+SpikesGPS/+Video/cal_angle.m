function AngleOut = cal_angle(vec_1, vec_2)
    
    [n_1, dim_1] = size(vec_1);
    [n_2, dim_2] = size(vec_2);

    if dim_1~=2 || dim_2~=2
        error("Inputs must be [n, 2] array.");
    end

    AngleOut = zeros(n_1, n_2);

    for i = 1:n_1
        for j = 1:n_2
            AngleOut(i, j) = acos(dot(vec_1(i, :), vec_2(j, :)) / (norm(vec_1(i, :)) * norm(vec_2(j, :)))) * 180 / pi;
        end
    end

    AngleOut = real(AngleOut);

end

