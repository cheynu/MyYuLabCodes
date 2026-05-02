function d_x = cal_diff(x, n)

if nargin<2
    n = 1;
end

d_x = x([2:end end]) - x([1 1:end-1]);
d_x(2:end-1) = d_x(2:end-1) ./ 2;

if n > 1
    d_x = obj.cal_diff(d_x, n-1);
end

end

