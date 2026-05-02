clear;clc;
%% Parameters
dose = 0.25; % 1x DCZ
drugSegment = 2; % the segment after dcz injection
halfrecoverySegment = 3; % [] or the segment during recovery (e.g., 3 hours)
recoverySegment = 4; % [] or the segment after (e.g., 6 hours) recovery

t_pre_press = -2500;
t_pre_release = -1500;
t_pre_reward = -2000;
t_post_press = 2500;
t_post_release = 1000;
t_post_reward = 4000;
%% Extract
Rfilename = dir('RTarray*.mat').name;
load(Rfilename,'r');

unit_num_len = length(r.Units.SpikeTimes);
%% Plot
for i=1:unit_num_len
    plotSpikesDCZ4Blocks(r,i,dose,...
        'drugSegment',drugSegment,'recoverySegment',recoverySegment,'halfrecoverySegment', halfrecoverySegment,...
        't_pre_press',t_pre_press,'t_post_press',t_post_press,...
        't_pre_release',t_pre_release,'t_post_release',t_post_release,...
        't_pre_reward',t_pre_reward,'t_post_reward',t_post_reward);
end