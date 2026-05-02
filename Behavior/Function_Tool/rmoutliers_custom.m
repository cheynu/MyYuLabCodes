function [dataout,indrmv, threshold] = rmoutliers_custom(datain, varargin);

if nargin<2
    c=5;
end

threshold = [];
[data2575] = prctile(datain, [25, 75]);
interq = data2575(2) - data2575(1);

if nargin>2
    for i=1:2:size(varargin,2)
        switch varargin{i}
            case {'c'}
                c = varargin{i+1}; %
            case {'threshold'}
                threshold = varargin{i+1}; %
            otherwise
                errordlg('unknown argument')
        end
    end
end

if isempty(threshold)
    threshold = [data2575(1)-interq*c  data2575(2)+interq*c];
end;

indrmv = find(datain>threshold(2) | datain<threshold(1));
dataout = datain;
dataout(indrmv) = [];