function meta = write_meta(outputFile, varargin)

% How to use:
% After saving a .mat
% outputFile = 'sdf_press_Juno_20250827.mat';
% save(outputFile, 'sdf', 'cfg');
% metaDir = data_folder;
% write_meta( ...
%     outputFile, ...
%     'MetaFolder', metaDir,...
%     'Description', 'Press-aligned SDFs pooled across FPs', ...
%     'Purpose', 'Figure 4 population dynamics', ...
%     'GeneratorFunction', 'Spikes.NP.build_sdfs_if_needed', ...
%     'GeneratorScript', 'Step2_Pipeline.m', ...
%     'Inputs', {'spike_table_Juno_20250827.mat'}, ...
% );

% After saving a .csv
% outputFile = 'unit_table_Juno_20250214.csv';
% writetable(spike_table, outputFile);
% metaDir = data_folder;
% write_meta( ...
%     outputFile, ...
%     'MetaFolder', metaDir,...
%     'Description', 'Unit table exported for R statistics', ...
%     'Purpose', 'Mixed-effects modeling and plotting', ...
%     'GeneratorScript', 'Step1_ExploreR.mlx', ...
%     'Inputs', {'unit_table_Juno_20250214.mat'}, ...
%     'Notes', 'Depth corrected relative to pia' ...
% );


%WRITE_META_JSON  Write human-readable metadata sidecar (.meta.json)

p = inputParser;
p.addRequired('outputFile', @ischar);
p.addParameter('Description', '', @ischar);
p.addParameter('Purpose', '', @ischar);
p.addParameter('GeneratorFunction', '', @ischar);
p.addParameter('GeneratorScript', '', @ischar);
p.addParameter('Inputs', {}, @iscell);
p.addParameter('Params', struct(), @isstruct);
p.addParameter('Notes', '', @ischar);
p.addParameter('MetaFolder', '', @ischar);   % <-- NEW


p.parse(outputFile, varargin{:});

meta = struct();

% ---------- Identity ----------
meta.file_name = outputFile;
[~,~,ext] = fileparts(outputFile);
meta.file_type = ext;

% ---------- Semantics ----------
meta.description = p.Results.Description;
meta.purpose     = p.Results.Purpose;

% ---------- Provenance ----------
meta.generated_on   = datestr(datetime('now'),'yyyy-mm-ddTHH:MM:SS');
meta.generated_by   = getenv('USERNAME');
meta.host           = getenv('COMPUTERNAME');
meta.matlab_version = version;
meta.os             = system_dependent('getos');

% ---------- Code traceability ----------
meta.generator = struct( ...
    'function', p.Results.GeneratorFunction, ...
    'script',   p.Results.GeneratorScript ...
);

% ---------- Dependencies ----------
meta.inputs     = p.Results.Inputs;
meta.parameters = p.Results.Params;

% ---------- Notes ----------
meta.notes = p.Results.Notes;

% ---------- Determine save location ----------
metaFolder = p.Results.MetaFolder;

if isempty(metaFolder)
    % Default: same folder as outputFile (or pwd if relative)
    [outDir, baseName, ext] = fileparts(outputFile);
    if isempty(outDir)
        outDir = pwd;
    end
    metaPath = fullfile(outDir, [baseName ext '.meta.json']);
else
    if ~isfolder(metaFolder)
        mkdir(metaFolder);
    end
    [~, baseName, ext] = fileparts(outputFile);
    metaPath = fullfile(metaFolder, [baseName ext '.meta.json']);
end

% ---------- Write JSON ----------
jsonText = jsonencode(meta, 'PrettyPrint', true);

fid = fopen(metaPath, 'w');
fwrite(fid, jsonText, 'char');
fclose(fid);

fprintf('[meta] Saved JSON metadata: %s\n', metaPath);
end