function sdf_mapped = mapSDF2Traj(traj, r, id)

t_traj  = traj.t_frame_e;
n_trial = length(traj.trial_id);

SDF = SpikesGPS.ComputeSDFAll(r, id);

sdf_mapped.meta = SDF.meta;
sdf_mapped.spk  = SDF.spike_waveform;
sdf_mapped.sdf  = cell(n_trial, 1);
for j = 1:n_trial
    id_j = find(SDF.trial_id==traj.trial_id(j));
    if isempty(id_j)
        continue
    end
    t_sdf = SDF.t_sdf{id_j};
    j_sdf = SDF.sdf{id_j};

    sdf_mapped.sdf{j} = interp1(t_sdf, j_sdf, t_traj{j}', 'linear');
end

sdf_cat  = cell2mat(sdf_mapped.sdf');
sdf_mean = mean(sdf_cat);
sdf_std  = std(sdf_cat);

sdf_mapped.sdf_z = cellfun(@(x) (x-sdf_mean)./sdf_std, sdf_mapped.sdf, 'UniformOutput', false);

end