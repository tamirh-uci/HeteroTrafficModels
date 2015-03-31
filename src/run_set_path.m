function run_set_path()
%RUNSETPATH Setup subfolders to be on the current path
    addpath( fullfile(pwd,'simulation') );
    addpath( fullfile(pwd,'utility') );
    addpath( fullfile(pwd,'markov') );
end