iPosFile               =        'pineapple_position2021-06-22T16_42_47.txt';
iStimFile             =        'pineapplestilm2021-06-22T16_42_50.txt';
iVidFile               =	   'pineapple2021-06-22T16_42_47.avi';
 
PosData = ExtractPosData(iPosFile, iStimFile); % PosData includes frame index that produces stim signals.

StimFrames = ExtractStimFrames(iVidFile, PosData);
