function dlcResults = read_dlc_table(csvFilePath)
% 2025.1.12 JY
% Read the table
% Specify the path to your CSV file
% Read the file using readtable
opts = detectImportOptions(csvFilePath, 'NumHeaderLines', 3); % Skip first 3 rows of headers
dlcData = readtable(csvFilePath, opts);

% Read the headers (bodyparts and coordinates)
fid = fopen(csvFilePath, 'r');
headerLines = textscan(fid, '%s', 3, 'Delimiter', '\n'); % Read first 3 lines
fclose(fid);

% Extract scorer, bodyparts, and coords
scorerLine = split(headerLines{1}{1}, ','); % First row
bodypartsLine = split(headerLines{1}{2}, ','); % Second row
coordsLine = split(headerLines{1}{3}, ','); % Third row

% Remove the 'scorer' column for alignment
scorerLine(1) = [];
bodypartsLine(1) = [];
coordsLine(1) = [];

% Create a structured format for the results
uniqueBodyparts = unique(bodypartsLine);
dlcResults = struct();

for i = 1:length(uniqueBodyparts)
    bodypart = uniqueBodyparts{i};
    x_col = strcmp(bodypartsLine, bodypart) & strcmp(coordsLine, 'x');
    y_col = strcmp(bodypartsLine, bodypart) & strcmp(coordsLine, 'y');
    likelihood_col = strcmp(bodypartsLine, bodypart) & strcmp(coordsLine, 'likelihood');
    
    % Extract data for this bodypart
    dlcResults.(bodypart).x = dlcData{:, find(x_col)+1};
    dlcResults.(bodypart).y = dlcData{:, find(y_col)+1};
    dlcResults.(bodypart).likelihood = dlcData{:, find(likelihood_col)+1};
end