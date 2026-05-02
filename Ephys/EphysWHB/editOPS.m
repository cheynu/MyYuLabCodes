function editOPS(version)
arguments
    version double {mustBeMember(version, [2.5, 3])} = 2.5
end

if version == 2.5
    ksdir = 'kilosort2_5_output';
elseif version == 3
    ksdir = 'kilosort3_output';
end

oriPath = pwd;
% check path
if ~exist(fullfile(oriPath, ksdir), 'dir')
    if ~exist(fullfile(oriPath, 'sorter_output'), 'dir')
        error('Check current path');
    else
        cd(fullfile(oriPath, 'sorter_output'));
    end
else
    cd(fullfile(oriPath, ksdir, 'sorter_output'));
end
curPath = pwd;
o = load('ops.mat');
ops = o.ops;
save ops_ori.mat ops -mat;

ops.fbinary = [curPath '/recording.dat'];
ops.fproc = [curPath '/temp_wh.dat'];
ops.chanMap = [curPath '/chanMap.mat'];
ops.root = curPath;
save ops.mat ops -mat;

phyPath = fullfile(oriPath, ksdir, 'sorter_output');
phyCmd = "cd "+ string(phyPath)+"; phy template-gui params.py";
clipboard("copy", phyCmd);
end