function send_SRTGroupClass(type)

if nargin<1
    clc
    type = input('What is the lesion type? (M1|bM1|DLS|bDLS|M1DLS)', 's')
end;

if nargin<1
    this_folder          =      pwd;
    folder_split          =     split(this_folder, '\');
    rat_name = [];
    k=0;
    while isempty(rat_name)
        if ~contains(folder_split{end-k}, 'ThreeFP')
            rat_name            =       folder_split{end-k};
        else
            k=k+1;
        end;
    end;

    group_class_name               =     ['SRTGroupClass_' rat_name '.mat'];
end;

% send r array to the data folder
switch type
    case 'M1'
        M1_data_folder = fullfile(findonedrive, '00_Work', '03_Projects','03_LesionData',...
            'Results', '01_Contralateral_M1', 'Code', 'Data');
        target_folder  = M1_data_folder;
    case 'bM1'
        biM1_data_folder = fullfile(findonedrive, '00_Work', '03_Projects','03_LesionData',...
            'Results', '03_Bilateral_M1', 'Code', 'Data');
        target_folder  = biM1_data_folder;
    case 'DLS'
        DLS_data_folder = fullfile(findonedrive, '00_Work', '03_Projects','03_LesionData',...
            'Results', '02_Contralateral_DLS', 'Code', 'Data');
        target_folder  = DLS_data_folder;
    case 'bDLS'
        DLS_data_folder = fullfile(findonedrive, '00_Work', '03_Projects','03_LesionData',...
            'Results', '04_Bilateral_DLS', 'Code', 'Data');
        target_folder  = DLS_data_folder;

end;

if ~exist(target_folder, 'dir')
    mkdir(target_folder)
end
copyfile(group_class_name, target_folder)
disp('Done!')

if ispc
    winopen(target_folder);
end