clear;clc;

funcPath = 'C:\Users\CY\OneDrive\lab\Codes\CY\Video\DLCplot'; addpath(funcPath);

rpath = pwd; % root path
sbjPath = 'D:\VideoProcessing\1_Data\Matias';
tarDate = {'20220323','20220324','20220404','20220405','20220406','20220408'};
%%

for i=1:length(tarDate)
    vidaPath = fullfile(sbjPath,tarDate{i},'VideoData','Clips','VideoData'); % VIdeo DAta PATH
    savePath = fullfile(rpath,tarDate{i});
    [~,~] = mkdir(rpath,tarDate{i}); % mkdir if ~isexist

    mergeDLC(vidaPath,savePath);
    anno2Excel(vidaPath,savePath);
end