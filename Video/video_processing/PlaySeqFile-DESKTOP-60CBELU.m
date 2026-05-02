function PlaySeqFile(vidFile)
% play seq file PlaySeqFile(vidFile)
% you can provide only some clue for a video name, eg., '53-27'
% 5.4.2022

if nargin<1
    %% Get frame times
    seqfiles = dir('*.seq');
    if length(seqfiles)>0;
        for i=1:length(seqfiles)
            SeqVidFile{i} = seqfiles(i).name;
        end;
    end;
    vidFile = SeqVidFile{1};
end

if ~any(ismember(vidFile, '.seq'))
    file_name_real = dir(['*' vidFile '*.seq']);
    if isempty(file_name_real)
        clc
        disp('####### ########## #######')
        disp('####### No such files #######')
        disp('####### ########## #######')
        return
    elseif length(file_name_real) >1
        arrayfun(@(x)x.name, x, 'UniformOutput', false)'
        clc
        disp('Provide a better name so only one file is tracked. ')
    else
        vidFile = file_name_real.name;
    end
end

disp(vidFile)
t_min           =       5;
t_sec           =       30;
framerate       =       100;
t_max         = 20;

filename = vidFile;
tnow = t_min*60+t_sec;

hf = figure(13); clf
set(gcf, 'name', 'ROI selection', 'units', 'centimeters', 'position', [5 5 15 15]);
ha=axes('units', 'centimeters', 'Position',[2 2 12 12],'NextPlot','add', 'ydir', 'reverse');
to_continue = 1;

while tnow<t_max*60 && to_continue
    frames = [tnow*framerate:(tnow+.5)*framerate-1];
    % read one min of data
    framebeg = frames(1);
    frameend = frames(end);
    sprintf('t range is [%2.2f %2.2f] (seconds)', tnow, tnow+0.1)
    title([vidFile '|t=[' num2str(tnow) '~' num2str(tnow+0.1) ']'], 'fontsize', 15)
    % Construct a multimedia reader object associated with file
    [list_of_frames, headin_frames]         =   ReadJpegSEQ(filename, [framebeg frameend]);
    % read one min of data
    frames = [];
    for i = 1:size(list_of_frames, 1)
        frames(:, :, i) = double(list_of_frames{i, 1});
    end;
    sprintf('Size of this video %s is \n [%4.0d %4.0d]', filename, size(frames, 1), size(frames, 2))
    maxproj_frames = max(frames, [], 3);
    % plot the max projection of these frames:.
    if isempty(get(ha, 'Children'))
        himg = imagesc(ha, maxproj_frames);
        colormap('gray')
        ha.XLim = [0 size(maxproj_frames, 2)];
        ha.YLim = [0 size(maxproj_frames, 1)];
    else
        himg.CData = maxproj_frames;
    end;
    drawnow;
    tnow = tnow+1;

    answer = timed_input('Continue to next block? (y|n)', 5);
    if answer == 'y'
        disp('Proceeding to the next block...');
    else
        disp('Exiting the current block...');
    end

    if isempty(answer)
        answer = 'y';
    end;
    if strcmp(answer, 'y')
        to_continue = 1;
    else
        to_continue = 0;
    end
end

% save current frame
tosavename = extractBefore(filename, '.seq');
tosavename = ['ExampleFrames_' tosavename '.png'];
print (hf,'-dpng', tosavename)
disp('Frames saved')

end

function answer = timed_input(prompt, timeout)
    % Set up the default answer if no input is provided within the timeout
    defaultAnswer = 'n';
    fprintf('%s (default=%s, %d seconds to respond): ', prompt, defaultAnswer, timeout);
    
    % Initialize the timer
    tic;
    answer = '';
    
    % Wait for input or timeout
    while toc < timeout
        if kbhit
            answer = input('', 's'); % Capture the input
            break;
        end
        pause(0.1); % Allow MATLAB to check for input
    end
    
    % If no input was given within the timeout, use the default
    if isempty(answer)
        answer = 'n';
    end
    
    % Display the chosen answer
    fprintf('Answer: %s\n', answer);
end

function hit = kbhit()
    % Check if a key is pressed without pausing execution
    drawnow; % Process any input from the command line
    hit = ~isempty(get(gcf, 'CurrentCharacter'));
end
