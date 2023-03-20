function EventOut = UpdateDIO_MedLick(EventOut, BpodEvents)
% Yu Chen, 2023.2.23
% Revised from @UpdataDIO_MedLick by Hanbo Wang
% Adapted to Bio-signal Apollo II in mouse ephys

% Hanbo Wang, Oct 2022
% Revised from @UpdateDIOMedOpto by Jianing Yu (Mar 2021)
%   using information from Bpod to update event stamping 

N_events = length(EventOut.EventsLabels);

tPokeIn  = BpodEvents.PokeIn*1000;
tPokeOut = BpodEvents.PokeOut*1000;
% good poke in bpod
tGoodPokeIn  = BpodEvents.GoodPokeIn*1000;
tGoodPokeOut = BpodEvents.GoodPokeOut*1000;

% "Tone" in this script means "MEDTTL"
tTone_Ephys = EventOut.Onset{strcmp(EventOut.EventsLabels, 'GoodRelease')}';
tTone_Bpod  = BpodEvents.GoodRelease*1000;
% nbpod must be larger than nblackrock


%% Align Ephys & Bpod at each tTone

% nDiff = length(tTone_Bpod) - length(tTone_Ephys);
% dt = zeros(nDiff, 1);
% 
% tTone_Ephys_rltv = tTone_Ephys - tTone_Ephys(1);
% for i = 1:1:nDiff
%     iTone_Bpod_rltv = tTone_Bpod - tTone_Bpod(i);
%     iTone_Bpod_rltv = iTone_Bpod_rltv(iTone_Bpod_rltv>=0);
%     dt(i) = toaligh(tTone_Ephys_rltv, iTone_Bpod_rltv);
% end

dt = zeros(length(tTone_Bpod), 1);

tTone_Ephys_rltv = tTone_Ephys - tTone_Ephys(1);
for i = 1:length(tTone_Bpod)
    iTone_Bpod_rltv = tTone_Bpod - tTone_Bpod(i);
    iTone_Bpod_rltv = iTone_Bpod_rltv(iTone_Bpod_rltv>=0);
    dt(i) = toalign(tTone_Ephys_rltv, iTone_Bpod_rltv);
end

h = figure(18); clf(h); 
subplot(3, 1, 1);
plot(dt, 'ko'); hold on;
[dtMax, dtMaxIdx] = max(dt);
plot(dtMaxIdx, dtMax, 'ro', 'markerfacecolor', 'r', 'markersize', 6)
xlabel('diffTrials');
ylabel('seqCorr');
title('GoodRelease Alignment');

% Align tBpod
tDiff = tTone_Bpod(dtMaxIdx) - tTone_Ephys(1);  % Difference between Bpod & Ephys tTone
tTone_Bpod_Diff = tTone_Bpod - tDiff;

% time range:
idxTone_Bpod_new = find(tTone_Bpod_Diff >= tTone_Ephys(1) - 100 & tTone_Bpod_Diff <= tTone_Ephys(end) + 200);
trangeTone_Bpod = [tTone_Bpod(idxTone_Bpod_new(1)) tTone_Bpod(idxTone_Bpod_new(end))];
tTone_Bpod_new = tTone_Bpod_Diff(idxTone_Bpod_new);

ha3 = subplot(3, 1, 2);
plot(tTone_Ephys, 0.5, 'ko');
text(tTone_Ephys(end), 0.7, 'Ephys', 'color', 'k');
hold on;
plot(tTone_Bpod_Diff, 1.2, 'co' );
set(gca, 'ylim', [0.5 2]);
plot(tTone_Bpod_new, 1.4, 'r*');
text(tTone_Bpod_new(end), 1.7, 'bpod matched', 'color', 'r');

tTone_Bpod_aligned  = zeros(length(tTone_Bpod_new), 1);
tTone_Ephys_aligned = zeros(length(tTone_Bpod_new), 1);

for i =1:length(tTone_Bpod_new)
    [dtMin, dtMinIdx] = min(abs(tTone_Ephys - tTone_Bpod_new(i)));
    if dtMin < 500
        tTone_Bpod_aligned(i)  = [tTone_Bpod_new(i)];
        tTone_Ephys_aligned(i) = [tTone_Ephys(dtMinIdx)];
        line([tTone_Bpod_new(i); tTone_Ephys(dtMinIdx)], [1.4; 0.5], 'color', 'k', 'linewidth', 1.5)      
    end
end
xlabel('Time in Ephys');

subplot(3, 1, 3)
plot(tTone_Bpod_aligned - tTone_Ephys_aligned, 'ko-');
xlabel('Good Release #');
ylabel('tBpod - tEphys');

tPokeIn_new  = tPokeIn(tPokeIn >= trangeTone_Bpod(1) - 100 & tPokeIn <= trangeTone_Bpod(2) + 200);
tPokeOut_new = tPokeOut(tPokeOut >= trangeTone_Bpod(1) - 100 & tPokeOut <= trangeTone_Bpod(2) + 200);
tPokeIn_aligned  = nan(length(tPokeIn_new), 1);
tPokeOut_aligned = nan(length(tPokeOut_new), 1);

tGoodPokeIn_new  = tGoodPokeIn(tGoodPokeIn >= trangeTone_Bpod(1) - 100 & tGoodPokeIn <= trangeTone_Bpod(2) + 200);
tGoodPokeOut_new = tGoodPokeOut(tGoodPokeIn >= trangeTone_Bpod(1) - 100  & tGoodPokeIn <= trangeTone_Bpod(2) + 200);
tGoodPokeIn_aligned  = nan(length(tGoodPokeIn_new), 1);
tGoodPokeOut_aligned = nan(length(tGoodPokeIn_new), 1);

% Align PokeIn/Out time
for i = 1:length(tPokeIn_new)
    itPokeIn  = tPokeIn_new(i);
    itPokeOut = tPokeOut_new(i);
    
    idxtTone_Bpod = find(tTone_Bpod < itPokeIn, 1, 'last');
    itTone_Bpod   = tTone_Bpod(idxtTone_Bpod);
    itTone_Bpod_Diff = itTone_Bpod - tDiff;
    [~, matchIdx] = intersect(tTone_Bpod_aligned, itTone_Bpod_Diff);
    
    if ~isempty(matchIdx)
        itTone_Ephys = tTone_Ephys_aligned(matchIdx);
        tPokeIn_aligned(i)  = itPokeIn - itTone_Bpod + itTone_Ephys;
        tPokeOut_aligned(i) = itPokeOut - itTone_Bpod + itTone_Ephys;
    end
end
tPokeIn_aligned = tPokeIn_aligned(~isnan(tPokeIn_aligned));
tPokeOut_aligned = tPokeOut_aligned(~isnan(tPokeOut_aligned));

% Align GoodPokeIn/Out time
for i = 1:length(tGoodPokeIn_new)
    itGoodPokeIn  = tGoodPokeIn_new(i);
    itGoodPokeOut = tGoodPokeOut_new(i);
    
    idxtTone_Bpod = find(tTone_Bpod < itGoodPokeIn, 1, 'last');
    itTone_Bpod = tTone_Bpod(idxtTone_Bpod);
    
    itTone_Bpod_Diff = itTone_Bpod - tDiff;
    [~, matchIdx] = intersect(tTone_Bpod_aligned, itTone_Bpod_Diff);
    
    if ~isempty(matchIdx)
        itTone_Ephys = tTone_Ephys_aligned(matchIdx);
        tGoodPokeIn_aligned(i)  = itGoodPokeIn - itTone_Bpod + itTone_Ephys;
        tGoodPokeOut_aligned(i) = itGoodPokeOut - itTone_Bpod + itTone_Ephys;
    end
end
tGoodPokeIn_aligned = tGoodPokeIn_aligned(~isnan(tGoodPokeIn_aligned));
tGoodPokeOut_aligned = tGoodPokeOut_aligned(~isnan(tGoodPokeOut_aligned));

axes(ha3);
if ~isempty(tPokeIn_aligned)
    plot(tPokeIn_aligned, 2.3, 'b^');
end
if ~isempty(tGoodPokeIn_aligned)
    plot(tGoodPokeIn_aligned, 1.3, 'r^');
end

% update EventOut
idxPoke = find(ismember(EventOut.EventsLabels,'Poke'));
if ~isempty(idxPoke)
    EventOut.Onset{idxPoke}  = tPokeIn_aligned;
    EventOut.Offset{idxPoke} = tPokeOut_aligned;
else
    EventOut.EventsLabels{end+1} = 'Poke';
    EventOut.Onset{end+1} = tPokeIn_aligned;
    EventOut.Offset{end+1} = tPokeOut_aligned;
end
idxGoodPoke = find(ismember(EventOut.EventsLabels,'GoodPoke'));
if ~isempty(idxGoodPoke)
    EventOut.Onset{idxGoodPoke}  = tGoodPokeIn_aligned;
    EventOut.Offset{idxGoodPoke} = tGoodPokeOut_aligned;
else
    EventOut.EventsLabels{end+1} = 'GoodPoke';
    EventOut.Onset{end+1} = tGoodPokeIn_aligned;
    EventOut.Offset{end+1} = tGoodPokeOut_aligned;
end



function seqcorr = toalign(seq1, seq2)
% seq 1 is a subset of seq2
% based on correlation analysis
tmax = max([seq1, seq2]);
edges =0:100:tmax;
% won't assume 
nseq1 = histcounts(seq1, edges);
nseq2 = histcounts(seq2, edges); 
seqcorr = sum(nseq1.*nseq2);
