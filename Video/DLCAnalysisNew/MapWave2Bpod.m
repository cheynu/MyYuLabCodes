function sout = MapWave2Bpod(sout, tTriggerBpod)

% 5/5/2022

% the point is to map the signal in sout to MED time

% sout time
t_sout = sout.Time; % in ms

% sout triggers
ind_trig = find(contains(sout.Labels, 'Trigger'));
TriggerSignal = sout.Signals(:, ind_trig);

% find out the onset
above_th = find(TriggerSignal > 1);
trigger_beg = above_th([1; find(diff(above_th)>1)+1]);
trigger_end = above_th([find(diff(above_th)>1)+1; length(above_th)]);

figure; plot(TriggerSignal);
hold on
plot(trigger_beg, 1, 'ro')

TriggerTimeWS = t_sout(trigger_beg);
TriggerTimeB = tTriggerBpod*1000;

% find match
Indout = findseqmatchrev(TriggerTimeB, TriggerTimeWS, 0, 0);  % map trigger time in WS to time in MED

TriggerTimeB2 = TriggerTimeB(Indout(~isnan(Indout)));
TriggerTimeWS2 = TriggerTimeWS(~isnan(Indout));

% map time in WS to time in MED
% tframes_in_b = MapVidFrameTime2Bpod(tLEDon,  tbeh_trigger,  tsROI);

NewSoutTime = MapVidFrameTime2Bpod(TriggerTimeWS2,  TriggerTimeB2, sout.Time);
sout.TimeInBpod = NewSoutTime;
WSOut = sout;
save('WSOut.mat', 'WSOut', '-v7.3' ) 