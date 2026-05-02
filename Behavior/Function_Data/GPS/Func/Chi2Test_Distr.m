function [p_val, chi2, p_sub, n_cat] = Chi2Test_Distr(data, bin_edges)

% Zhuohao Zhang 1/29/2024
% 

% parsing input
P = inputParser;

addRequired(P, 'data', @iscell);
addRequired(P, 'bin_edges', @isvector);

parse(P, data, bin_edges);

data = P.Results.data(:);
bin_edges = P.Results.bin_edges;

%
n_group = length(data);
n_cat = length(bin_edges);

num_count = zeros(n_group, n_cat);
for g = 1:n_group
    num_count(g, 1) = sum(data{g}<bin_edges(1));
    for c = 2:n_cat
            num_count(g, c) = sum(data{g}>=bin_edges(c-1) & data{g}<bin_edges(c));
    end
end

[p_val, chi2] = Chi2Test(num_count); 

%
p_sub = zeros(1, n_cat);
for c = 1:n_cat
    c_other = setdiff(1:n_cat, c);
    num_count_sub = [num_count(:, c) sum(num_count(:, c_other), 2)];
    p_sub(c) = Chi2Test(num_count_sub); 
end

end
