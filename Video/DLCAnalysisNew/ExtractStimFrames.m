function vidout = ExtractStimFrames(vidfile, PosData, vid_name)

if nargin<3
    vid_name = [];
end;

ind = [1:size(PosData.StimTime, 1)];

StimClus =zeros(length(PosData.StimClus{1}));

if length(PosData.StimClus) >1
    for k =1:length(PosData.StimClus)
        StimClus = StimClus+PosData.StimClus{k}*k;
    end;
else
    StimClus = PosData.StimClus{1}*1;
end;
% object

vidObj=VideoReader(vidfile);
StimPosSelected = PosData.PosTime(PosData.StimTime(ind, 2),[1 2]);

figure(42); clf
set(gcf, 'unit', 'centimeters', 'position',[2 2 10 10], 'paperpositionmode', 'auto', 'Visible', 'on')
F= struct('cdata', [], 'colormap', []);

icount = 0; 

for i=1:length(ind)
    
    this_index = PosData.StimTime(ind(i), 2);  % this is the frame index
    this_cluster = StimClus(i);
    
    if this_cluster~=0        
        thisframe = rgb2gray(read(vidObj, [this_index this_index]));        
        [height, width] = size(thisframe);

        clf(42);
        ha=axes('unit', 'centimeters', 'position', [0 0 10 10],'xlim', [0 width], 'ylim', [0 height+100],  'ydir','reverse',  'nextplot', 'add');
        imagesc(thisframe, [0 160]);
        colormap('gray')
        hold on
        plot(StimPosSelected(i, 1), StimPosSelected(i, 2), 'co', 'markersize', 6, 'linewidth', 1);

        text(20, height+20, ['Cluster: ' num2str(this_cluster)], 'fontsize', 12, 'color', [100 180 100]/255);
        text(20, height+40, ['StimIndex#: ' num2str(i)], 'fontsize', 12, 'color', [100 180 100]/255);
        
        xpos = PosData.StimPos(i, 1);
        ypos = PosData.StimPos(i, 2);
        text(20, height+60, ['x: ' num2str(round(xpos))], 'fontsize', 12, 'color', [100 180 100]/255);
        text(20, height+80, ['y: ' num2str(round(ypos))], 'fontsize', 12, 'color', [100 180 100]/255);
        
        switch this_cluster
            case 1
                icount = icount+1;
                F(icount) =  getframe(42) ;
            case 2
                icount = icount+1;
                F(icount) =  getframe(42) ;
        end;
    end;
end;

xx=strsplit(vidfile, '\');
video_name1 = ['DLCTriggerFrames_' xx{end}(1:end-4)];

if ~isempty(vid_name)
    video_name1 = ['DLCTriggerFrames_' xx{end}(1:end-4) vid_name];
end;

vsaved = fullfile(pwd, video_name1);

sprintf('Triggered frames are stored in %s.avi', vsaved)
% make a video clip and save it to the correct location

writerObj = VideoWriter([video_name1 '.avi']);
vidout = [video_name1 '.avi'];
writerObj.FrameRate = 10; % this is 10 x slower
% set the seconds per image
% open the video writer
open(writerObj);
% write the frames to the video
for ifrm=1:length(F)
    % convert the image to a frame
    frame = F(ifrm) ;
    writeVideo(writerObj, frame);
end
% close the writer object
close(writerObj);