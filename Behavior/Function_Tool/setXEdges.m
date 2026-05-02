function xedges = setXEdges()

% parameters used in this figs
edges_RT = 0:0.025:0.6; % Reaction Time (only correct)
edges_RelT = 0:0.05:1; % Realease Time (correct + late trials)
edges_HT = 0:0.05:2.5; % Hold Time (all trials)

xedges = struct;
xedges.edges_RT = edges_RT;
xedges.edges_RelT = edges_RelT;
xedges.edges_HT = edges_HT;
xedges.RT = movmean(edges_RT,2,'Endpoints','discard');
xedges.RelT = movmean(edges_RelT,2,'Endpoints','discard');
xedges.HT = movmean(edges_HT,2,'Endpoints','discard');

end