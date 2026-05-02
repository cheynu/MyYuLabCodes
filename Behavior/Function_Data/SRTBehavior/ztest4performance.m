function [p, z] = ztest4performance(perf1, perf2, tar, tail)

arguments
    perf1 % performance of session1
    perf2 
    tar   % target performance, could be string("Correct") or double(1/2/3)
    tail double {mustBeMember(tail, [1 2])} = 2 % 2 for two-tailed test
end

n1 = length(perf1); x1 = sum(perf1==tar);
n2 = length(perf2); x2 = sum(perf2==tar);
p1 = x1/n1;
p2 = x2/n2;
p0 = (x1+x2)/(n1+n2);

z = (p1-p2)/sqrt(p0*(1-p0)*((1/n1)+(1/n2)));
p = tail*normcdf(-abs(z),0,1);

end