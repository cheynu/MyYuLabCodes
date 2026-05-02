function pathList = getSubContents(tarPath, tarType)
% Yu Chen, 2023.4.19, use mustBeMember to provide associations in IDE
% hbWang, Jan 2023

% This mini tool gets contents of target path 
% (***** Excluding '../' & './' & '.Store' *****)
%   - tarType: get "All" contents; get "Folder"; get "File"

arguments
    tarPath = pwd
    tarType {mustBeMember(tarType,{'All','Folder','File'})} = 'All'
end

oriPath = pwd; cd(tarPath);
pathList = dir();

switch tarType
    case 'All'
        omitFlag = 0;
    case 'Folder'
        omitFlag = 1;
        isdirFlag = 0;
    case 'File'
        omitFlag = 1;
        isdirFlag = 1;
end

%% 
nanList = [];
for i = 1:height(pathList)

    % Remove '../', './' and '.Store'
    iName = pathList(i).name;
    if iName(1) == '.'
        nanList = [nanList i]; %#ok<*AGROW> 
    elseif omitFlag && pathList(i).isdir == isdirFlag
        nanList = [nanList i];
    end
    
end
pathList(nanList) = [];
cd(oriPath);

end