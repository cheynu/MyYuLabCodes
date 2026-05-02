function sdfT = PopulationSDFWarped(r, ifReWarp, opts)
%% Initiation
arguments
    r
    ifReWarp = true % reWarp all units in r
    opts.sdfSaveFolder = 'sdf'
    % opts.glmeTableSaveFolder = pwd
    opts.figSaveFolder = 'Figure'
    opts.chanMap = []
end
sdfSaveFolder = opts.sdfSaveFolder;
% glmSaveFolder = opts.glmeTableSaveFolder;
figSaveFolder = opts.figSaveFolder;
chanMap = opts.chanMap;

if isempty(chanMap)
    if  ~isempty(dir('chanMap.mat'))
        chanMap =load('chanMap.mat');
    elseif ~isempty(dir(fullfile('catgt_Exp_g0','chanMap.mat')))
        chanMap =load(fullfile('catgt_Exp_g0','chanMap.mat'));
    else
        warndlg('chanMap not found, sptial info will be NaN');
    end
end
if ~isempty(chanMap)
    spatial = struct;
    spatial.ch = chanMap.chanMap(chanMap.connected);
    spatial.x = chanMap.xcoords(chanMap.connected);
    spatial.y = chanMap.ycoords(chanMap.connected);
    spatial.k = chanMap.kcoords(chanMap.connected);
else
    spatial = [];
end

warpedSDF = {}; % location cell list of individual warped sdf
%% ReWarp (if needed)
if ifReWarp
    ticWarp = tic;
    
    glmeTable = table;
    sdfT = table;
    index = 1:length(r.Units.SpikeTimes);
    [event_table, ~] = Spikes.SRT.rEventTable(r);
    for i=1:length(index)
        clear s sT stat_table
        s = Spikes.SRT.rPSTHWarped(r,i,'event_table',event_table);
        [~, stat_table] = Spikes.SRT.rPSTH_glm(s);
        
        [~,~] = mkdir(sdfSaveFolder);
        savename_sdf = ['sdf_',s.unit.cell_id,'.mat'];
        savepath_sdf = fullfile(sdfSaveFolder,savename_sdf);
        save(savepath_sdf,'s');
        warpedSDF{i,1} = savepath_sdf;

        % extract unit info
        cell_id = {s.unit.cell_id};
        Name = {s.subject};
        Session = {s.session};
        Unit_Sorted = s.unit.index; % default order is 1:n_unit
        Chs = s.unit.ch(1);
        Ch_Units = s.unit.ch(2);
        Unit_Quality_Num = r.Units.SpikeNotes(i,3);
        if isempty(spatial)
            xcoords = NaN;
            ycoords = NaN;
            kcoords = NaN;
        else
            idxSpatial = find(spatial.ch==Chs,1,'first');
            xcoords = spatial.x(idxSpatial);
            ycoords = spatial.y(idxSpatial);
            kcoords = spatial.k(idxSpatial);
        end
        sT = table(cell_id,Name,Session,Unit_Sorted,Chs,Ch_Units,Unit_Quality_Num,...
            xcoords,ycoords,kcoords);

        % expand table
        sT = [sT, stat_table(:,2:end)];
        % glmeTable = [glmeTable; stat_table];
        sdfT = [sdfT; sT];

        if mod(i,10)==0
            fprintf('Warp progress: %d / %d units, %.0f seconds\n\n',i,length(index),toc(ticWarp));
        end
    end
    % [~,~] = mkdir(glmSaveFolder);
    % writetable(glmeTable,fullfile(glmSaveFolder,['glmTable_' s.subject '_' s.session  '.csv']));
    
    writetable(sdfT,fullfile(sdfSaveFolder,['sdfTable_' s.subject '_' s.session '.csv']));
    toc(ticWarp)
else
    Tdir = dir(fullfile(sdfSaveFolder,'sdfTable_*.csv'));
    sdfT = readtable(fullfile(Tdir.folder, Tdir.name));
end
%% Plot warped SDF
Spikes.SRT.VisualizePopSDFWarped(sdfSaveFolder, sdfT,'figSaveFolder',figSaveFolder);
Spikes.SRT.VisualizePopSDFWarped(sdfSaveFolder, sdfT,'figSaveFolder',figSaveFolder,'frPeakThresold',5);
end