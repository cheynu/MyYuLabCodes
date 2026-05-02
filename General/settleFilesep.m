function output = settleFilesep(filepath)
%SETTLEFILESEP 将输入的路径中的'/'或'\'全部换成当前系统所用的filesep
%   用当前系统的filesep替换所有字符串中的'/'或'\'

pathSplit = strsplit(filepath,{'/','\'});
output = fullfile(pathSplit{:});

end

