function popWarp = PopulationSDFWarped(r)
% Gather warped population SDF
%% Units information
Units = r.Units.SpikeNotes;

%% Task information
FPs    = r.BehaviorClass.TargetFP; % you have to use BuildR2023 or BuildR4Tetrodes2023 to have this included in r.
FPs    = FPs(FPs>0);
NumFPs = length(FPs);

Ports    = r.BehaviorClass.LeftRight;
NumPorts = length(Ports);

popWarp.FPs = FPs;
popWarp.Ports = Ports;

%% 
n_units = size(Units, 1);
for i = 1:n_units
    id = Units(i, [1 2]);
    i_sdf_all = SpikesGPS.SRT.ComputeSDFWarped(r, id);

    if i==1
        popWarp.Subject = i_sdf_all.meta.subject;
        popWarp.Session = i_sdf_all.meta.session;
        popWarp.Trials  = r.PopPSTH.Trials;
        popWarp.ImplantLateral = r.ImplantLateral;

        popWarp.Units = Units;
        popWarp.IndSort = r.PopPSTH.IndSort;
        popWarp.IndUnmodulated = r.PopPSTH.IndUnmodulated;

        popWarp.t_points = i_sdf_all.SDFWarp.t_points;
        popWarp.t_points_description = i_sdf_all.SDFWarp.t_points_description;

        popWarp.t_warp = i_sdf_all.SDFWarp.t_warp;

        popWarp.sdf = cell(NumFPs, NumPorts);
        popWarp.sdf_z = cell(NumFPs, NumPorts);
        popWarp.sdf_ci_l = cell(NumFPs, NumPorts);
        popWarp.sdf_ci_u = cell(NumFPs, NumPorts);
    end
    for fp = 1:NumFPs
        for p = 1:NumPorts
            popWarp.sdf{fp, p} = [popWarp.sdf{fp, p}; i_sdf_all.SDFWarp.sdf_mean{fp, p}];
            if ~isempty(i_sdf_all.SDFWarp.sdf_ci{fp, p})
                popWarp.sdf_ci_l{fp, p} = [popWarp.sdf_ci_l{fp, p}; i_sdf_all.SDFWarp.sdf_ci{fp, p}(1,:)];
                popWarp.sdf_ci_u{fp, p} = [popWarp.sdf_ci_u{fp, p}; i_sdf_all.SDFWarp.sdf_ci{fp, p}(2,:)];
            else
                popWarp.sdf_ci_l{fp, p} = [popWarp.sdf_ci_l{fp, p}; zeros(1, length(popWarp.t_warp{fp, p}))];
                popWarp.sdf_ci_u{fp, p} = [popWarp.sdf_ci_u{fp, p}; zeros(1, length(popWarp.t_warp{fp, p}))];
            end
        end
    end

    % pooled
    if i==1
        popWarpPool.t_points = i_sdf_all.SDFWarpPool.t_points;
        popWarpPool.t_points_description = i_sdf_all.SDFWarpPool.t_points_description;

        popWarpPool.t_warp = i_sdf_all.SDFWarpPool.t_warp;

        popWarpPool.sdf.centin = cell(1, NumPorts);
        popWarpPool.sdf_z.centin = cell(1, NumPorts);
        popWarpPool.sdf_ci_l.centin = cell(1, NumPorts);
        popWarpPool.sdf_ci_u.centin = cell(1, NumPorts);

        popWarpPool.sdf.trigger = cell(1, NumPorts);
        popWarpPool.sdf_z.trigger = cell(1, NumPorts);
        popWarpPool.sdf_ci_l.trigger = cell(1, NumPorts);
        popWarpPool.sdf_ci_u.trigger = cell(1, NumPorts);

        popWarpPool.stat.centin = cell(1, NumPorts);
        popWarpPool.stat.trigger = cell(1, NumPorts);
    end
    for p = 1:NumPorts
        popWarpPool.sdf.centin{p} = [popWarpPool.sdf.centin{p}; i_sdf_all.SDFWarpPool.sdf_mean.centin{p}];
        popWarpPool.sdf_ci_l.centin{p} = [popWarpPool.sdf_ci_l.centin{p}; i_sdf_all.SDFWarpPool.sdf_ci.centin{p}(1,:)];
        popWarpPool.sdf_ci_u.centin{p} = [popWarpPool.sdf_ci_u.centin{p}; i_sdf_all.SDFWarpPool.sdf_ci.centin{p}(2,:)];

        popWarpPool.sdf.trigger{p} = [popWarpPool.sdf.trigger{p}; i_sdf_all.SDFWarpPool.sdf_mean.trigger{p}];
        popWarpPool.sdf_ci_l.trigger{p} = [popWarpPool.sdf_ci_l.trigger{p}; i_sdf_all.SDFWarpPool.sdf_ci.trigger{p}(1,:)];
        popWarpPool.sdf_ci_u.trigger{p} = [popWarpPool.sdf_ci_u.trigger{p}; i_sdf_all.SDFWarpPool.sdf_ci.trigger{p}(2,:)];

        popWarpPool.stat.centin{p}(i)  = ExamineTaskResponsive(popWarpPool.t_warp.centin{p}, i_sdf_all.SDFWarpPool.sdf_warp.centin{p}');
        popWarpPool.stat.trigger{p}(i) = ExamineTaskResponsive(popWarpPool.t_warp.trigger{p}, i_sdf_all.SDFWarpPool.sdf_warp.trigger{p}');
    end
end
[IndSort, IndInsignificant] = SpikesGPS.SRT.RankSDFWarpPooled(popWarpPool, 0.75);
popWarpPool.IndSort = IndSort;
popWarpPool.IndUnmodulated = IndInsignificant;

%% get z-score of warped sdf
popWarp.sdf_z = cellfun(@(x) normalize(x, 2, 'zscore'), popWarp.sdf, 'UniformOutput', false);
for fp = 1:NumFPs
    for p = 1:NumPorts
        popWarp.sdf_z{fp, p}(isnan(popWarp.sdf_z{fp, p})) = 0;
    end
end

for p = 1:NumPorts
    pool_sdf_cat = [popWarpPool.sdf.centin{p} popWarpPool.sdf.trigger{p}];
    pool_sdf_mean = mean(pool_sdf_cat, 2);
    pool_sdf_std  = std(pool_sdf_cat, [], 2);

    if pool_sdf_std==0
        popWarpPool.sdf_z.centin{p}  = zeros(size(popWarpPool.sdf.centin{p}));
        popWarpPool.sdf_z.trigger{p} = zeros(size(popWarpPool.sdf.trigger{p}));
    else
        popWarpPool.sdf_z.centin{p}  = (popWarpPool.sdf.centin{p} - pool_sdf_mean) ./ pool_sdf_std;
        popWarpPool.sdf_z.trigger{p} = (popWarpPool.sdf.trigger{p} - pool_sdf_mean) ./ pool_sdf_std;
    end
end

popWarp.popWarpPooled = popWarpPool;

save(sprintf('PopSDFWarped_%s_%s.mat', popWarp.Subject, popWarp.Session), "popWarp");

r.popSDFWarped = popWarp;
save(sprintf('RTarray_%s_%s.mat', popWarp.Subject, popWarp.Session), "r");

%% Plot warped SDF
SpikesGPS.SRT.VisualizePopSDFWarped(popWarp, 'Each');
SpikesGPS.SRT.VisualizePopSDFWarped(popWarp, 'Ipsi');
SpikesGPS.SRT.VisualizePopSDFWarped(popWarp, 'Contra');

end
