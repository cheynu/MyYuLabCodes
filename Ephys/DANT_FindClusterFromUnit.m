function [ClusterID, ClusterT] = DANT_FindClusterFromUnit(DANT_output,Session,Ch,NumInCh)
%DANT_FINDCLUSTERID 此处显示有关此函数的摘要
%   此处显示详细说明

arguments
    DANT_output
    Session string % '20251119'
    Ch string % 18: Channel 18
    NumInCh string % 2: Ch18_Unit2
end
Session = char(Session);
Ch = char(Ch);
NumInCh = char(NumInCh);

if istable(DANT_output)
    T = DANT_output;
elseif isfile(DANT_output)
    T = readtable(DANT_output);
else
    try
        T = readtable('DANT_Output.csv');
    catch
        error('DANT_output not found!');
    end
end

namesT = T.Properties.VariableNames;
for i=1:length(namesT)
    var = namesT{i};
    if ~isnumeric(T.(var))
        T.(var) = cellfun(@(x) strtrim(split(x, ',')), T.(var), 'UniformOutput', false);
    end
end

tarSession = Session;
tarCh = Ch;
tarUnit = NumInCh;

ClusterID = NaN;
ClusterT = table;

idxInRow = cellfun(@(x)find(contains(x,tarSession)),T.Sessions,'UniformOutput',false);
idxRow = find(cellfun(@(x)~isempty(x),idxInRow,'UniformOutput',true));

for i=1:length(idxRow) % all cluster containing the target session
    iRow = idxRow(i);

    t = T(iRow,:);
    id = t.ClusterID;
    ch = t.Channels{1}{idxInRow{iRow}};
    unit = t.NumInChannels{1}{idxInRow{iRow}};
    
    if strcmp(ch,tarCh) && strcmp(unit,tarUnit)
        ClusterID = id;
        ClusterT = t;
    end
end

end