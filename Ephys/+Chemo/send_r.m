function send_r()

if nargin<1
    this_folder          =      pwd;
    folder_split          =     split(this_folder, '\');    
    rat_name            =       folder_split{end-1};
    session_name    =       folder_split{end};
    r_name               =      ['RTarray_' rat_name, '_', session_name, '.mat'];
end;

% send r array to the data folder
target_folder  = fullfile(findonedrive, '00_Work', '03_Projects', '09_Chemogenetics', 'Data', 'RTarray');
copyfile(r_name, target_folder)
