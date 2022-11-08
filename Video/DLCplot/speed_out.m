function [speedout,bin] = speed_out(x,y,varargin)
p = inputParser;
addRequired(p,'x');
addRequired(p,'y');
addParameter(p,'bin',20);
parse(p,x,y,varargin{:});
bin = p.Results.bin;

x_shift = nan(size(x));
y_shift = nan(size(y));
x_shift(bin+1:end,:) = x(1:end-bin,:);
y_shift(bin+1:end,:) = y(1:end-bin,:);
x_mov = abs(x - x_shift);
y_mov = abs(y - y_shift);

speedout = sqrt(x_mov.^2+y_mov.^2);

end