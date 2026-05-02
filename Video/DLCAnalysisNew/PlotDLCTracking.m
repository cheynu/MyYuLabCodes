function PlotDLCTracking(varargin)

% 10.15.2021
% Jianing Yu
% This plots pose tracking from DLC routine
% end goal is to plot paw lifting until press time, as well as paw pos from
% trigger

% Body part names
%
if nargin>0
    for i=1:2:size(varargin,2)
        switch varargin{i}
            case 'body_parts'
                bodyParts = varargin{i+1};
            otherwise
                errordlg('unknown argument')
        end
    end
else
    bodyParts = {'L_hand', 'Nose'};
end;

% 1. see how many videl clips
vidfile = dir('*Press*.mat');
nfile = length(vidfile);

for i =1:nfile
    
    ifilename = vidfile(i).name; % this is the meta file
    ividname = [ifilename(1:end-4) '.avi']; % this is the video clip
    dlcTable = dir([ifilename(1:end-4) '*.csv']);
    [D,S] = xlsread(dlcTable.name);
  
    for k =1:length(bodyParts)
        
        ind_body = find(strcmp(S(2, :), bodyParts{k}));
        nframes   =       D(:, 1);
        x_pos       =       D(:, ind_body(1));
        y_pos       =       D(:, ind_body(2));
        lh              =       D(:, ind_body(3));
        
        figure(15); 
        clf(15)
        plot(lh>0.8, 'ko-')
        
        n_goodframes = length(find(lh>0.8));
        n_allframes = length(lh);
        
        sprintf('Percentage of good frams is %2.1f %%', 100*n_goodframes/n_allframes)
        
        for ii = 1:length(nframes)
            
            this_video = ividname;
            vidObj = VideoReader(this_video);
            this_frame = (read(vidObj, [ii ii]));
            
            hf25 = figure(25); clf
            set(hf25, 'name', 'side view', 'units', 'centimeters',...
                'position', [ 3 5 15 15*size(this_frame, 2)/size(this_frame, 1)],...
                'PaperPositionMode', 'auto', 'color', 'w')
            
            ha= axes;
            set(ha, 'units', 'centimeters', 'position', [0 0 15 15*size(this_frame, 2)/size(this_frame, 1)], 'nextplot', 'add',...
                'xlim',[0 size(this_frame, 1)], 'ylim', [0 size(this_frame, 2)], 'ydir','reverse')
            
            image(this_frame);
            
            if lh(ii) < 0.9
                plot(x_pos(ii), y_pos(ii), 'ro', 'markersize', 6, 'linewidth', 1)
            else
                plot(x_pos(ii), y_pos(ii), 'co', 'markersize', 6, 'linewidth', 1)
            end;
            
            %% plot last five tracking points
            
            text(size(this_frame, 1)-100, 50, ['Fr# ' num2str(ii)], 'fontsize', 15, 'color', 'w')
            
            pause(0.1)
            
        end;
        
      pause  
        
        
    end;
end;

