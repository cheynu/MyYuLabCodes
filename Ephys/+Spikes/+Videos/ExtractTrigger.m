function TriggerTime = ExtractTrigger(r)
TriggerTime = 0.001*r.Behavior.EventTimings(r.Behavior.EventMarkers==find(strcmp(r.Behavior.Labels, 'Trigger')));
