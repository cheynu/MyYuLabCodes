function [dataout, interq, indrmv] = rmoutliers_custome(datain)

[data2575] = prctile(datain, [25, 75]);
interq = data2575(2) - data2575(1);
c = 5;
indrmv = find(datain>data2575(2)+interq*c | datain<data2575(1)-interq*c | isnan(datain));
dataout = datain;

% if ~isempty(indrmv)
%     sprintf('Remove these long reaction time (ms): %2.0f, \n', dataout(indrmv))
% end;
dataout(indrmv) = [];

end
