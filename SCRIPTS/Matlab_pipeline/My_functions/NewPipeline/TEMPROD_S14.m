%% TEMPROD ANALYSIS
clear all
close all

tag = 'Laptop';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if strcmp(tag,'Laptop') == 1
    
    %% SET PATHS %%
    
    addpath(genpath('C:\FIELDTRIP\fieldtrip-20111020'));
    %     ft_defaults
    %     addpath '/neurospin/local/mne/i686/share/matlab/'
    addpath 'C:\TEMPROD\SCRIPTS/Matlab_pipeline/My_functions/Main'
    addpath 'C:\TEMPROD\SCRIPTS/Matlab_pipeline/My_functions/Behavior'
    addpath 'C:\TEMPROD\SCRIPTS/Matlab_pipeline/My_functions/Preprocessing'
    addpath 'C:\TEMPROD\SCRIPTS/Matlab_pipeline/My_functions/Frequency'
    addpath 'C:\TEMPROD\SCRIPTS/Matlab_pipeline/My_functions/Timelock'
    addpath 'C:\TEMPROD\SCRIPTS/Matlab_pipeline/My_functions/ICA'
    addpath 'C:\TEMPROD\SCRIPTS/Matlab_pipeline/My_functions/Misc'
    addpath 'C:\TEMPROD\SCRIPTS/Matlab_pipeline/My_functions/Time-Frequency'
    addpath 'C:\TEMPROD\SCRIPTS/Matlab_pipeline/My_functions/n_way_toolbox'
    addpath 'C:\TEMPROD\SCRIPTS/Matlab_pipeline/My_functions/cw_entrainfreq'
    addpath 'C:\TEMPROD\SCRIPTS/Matlab_pipeline/My_functions/NewPipeline'
    
elseif strcmp(tag,'Network') == 1
    
    %% SET PATHS %%
    % rmpath(genpath('/neurospin/local/fieldtrip'))
    % addpath(genpath('/neurospin/meg/meg_tmp/fieldtrip-20110201'));
    % addpath(genpath('/neurospin/meg/meg_tmp/fieldtrip-20110404'));
    addpath(genpath('/neurospin/local/fieldtrip'));
    %     ft_defaults
    addpath '/neurospin/local/mne/i686/share/matlab/'
    addpath '/neurospin/meg/meg_tmp/temprod_Baptiste_2010/SCRIPTS/Matlab_pipeline/My_functions/Main'
    addpath '/neurospin/meg/meg_tmp/temprod_Baptiste_2010/SCRIPTS/Matlab_pipeline/My_functions/Behavior'
    addpath '/neurospin/meg/meg_tmp/temprod_Baptiste_2010/SCRIPTS/Matlab_pipeline/My_functions/Preprocessing'
    addpath '/neurospin/meg/meg_tmp/temprod_Baptiste_2010/SCRIPTS/Matlab_pipeline/My_functions/Frequency'
    addpath '/neurospin/meg/meg_tmp/temprod_Baptiste_2010/SCRIPTS/Matlab_pipeline/My_functions/Timelock'
    addpath '/neurospin/meg/meg_tmp/temprod_Baptiste_2010/SCRIPTS/Matlab_pipeline/My_functions/ICA'
    addpath '/neurospin/meg/meg_tmp/temprod_Baptiste_2010/SCRIPTS/Matlab_pipeline/My_functions/Misc'
    addpath '/neurospin/meg/meg_tmp/temprod_Baptiste_2010/SCRIPTS/Matlab_pipeline/My_functions/Time-Frequency'
    addpath '/neurospin/meg/meg_tmp/temprod_Baptiste_2010/SCRIPTS/Matlab_pipeline/My_functions/n_way_toolbox'
    addpath 'C:\TEMPROD\SCRIPTS/Matlab_pipeline/My_functions/NewPipeline'
    
end

%% STEP1: preprocessing
% s14
for run           = [2 3 4 5 6 7]
    Temprod_Preproc('s14',run,'ecg&eog',tag)
end
% s13
for run           = [2 3 4 5 6 7]
    Temprod_Preproc('s13',run,'ecg&eog',tag)
end
% s12
for run           = [2 3]
    Temprod_Preproc('s12',run,'nocorr',tag)
end
for run           = [4 5 6 7]
    Temprod_Preproc('s12',run,'ecg&eog',tag)
end

for run           = [2 3 4 5]
    Temprod_Preproc('s11',run,'ecg&eog',tag)
end

for run           = [2 3 4 5 6]
    Temprod_Preproc('s10',run,'ecg&eog',tag)
end
for run           = [7]
    Temprod_Preproc('s10',run,'nocorr',tag)
end

for run           = [2 3 4 5 6]
    Temprod_Preproc('s08',run,'ecg&eog',tag)
end

%% STEP2: frequency analysis
% s14
chantype          = {'Mags';'Grads1';'Grads2'};
Targets           = [5.7 8.5 5.7 5.7 8.5 5.7];
run               = [2 3 4 5 6 7];
for i             = 1:length(run)
    T             = Targets(i);
    R             = run(i);
    for j         = 1:3
        Temprod_Freqanalysis('s14',R,[1 120],chantype{j},T,12600,tag)
    end
end
% s13
chantype          = {'Mags';'Grads1';'Grads2'};
Targets           = [5.7 8.5 5.7 5.7 8.5 5.7];
run               = [2 3 4 5 6 7];
for i             = 1:length(run)
    T             = Targets(i);
    R             = run(i);
    for j         = 1:3
        Temprod_Freqanalysis('s13',R,[1 120],chantype{j},T,12600,tag)
    end
end
% s12
chantype          = {'Mags';'Grads1';'Grads2'};
Targets           = [5.7 8.5 5.7 5.7 8.5 5.7];
run               = [2 3 4 5 6 7];
for i             = 1:length(run)
    T             = Targets(i);
    R             = run(i);
    for j         = 1:3
        Temprod_Freqanalysis('s12',R,[1 120],chantype{j},T,12600,tag)
    end
end
% s11
chantype          = {'Mags';'Grads1';'Grads2'};
Targets           = [5.7 8.5 5.7 5.7];
run               = [2 3 4 5];
for i             = 1:length(run)
    T             = Targets(i);
    R             = run(i);
    for j         = 1:3
        Temprod_Freqanalysis('s11',R,[1 120],chantype{j},T,12600,tag)
    end
end
% s10
chantype          = {'Mags';'Grads1';'Grads2'};
Targets           = [5.7 8.5 5.7 5.7 8.5 5.7];
run               = [2 3 4 5 6 7];
for i             = 1:length(run)
    T             = Targets(i);
    R             = run(i);
    for j         = 1:3
        Temprod_Freqanalysis('s10',R,[1 120],chantype{j},T,12600,tag)
    end
end
%s08
chantype          = {'Mags';'Grads1';'Grads2'};
Targets           = [6.5 8.5 6.5 6.5 8.5];
run               = [2 3 4 5 6];
for i             = 1:length(run)
    T             = Targets(i);
    R             = run(i);
    for j         = 1:3
        Temprod_Freqanalysis('s08',R,[1 120],chantype{j},T,12600,tag)
    end
end

%% compute, plot ans store frequency and power peaks values
chantype          = {'Mags';'Grads1';'Grads2'};
freqband          = {[2 6],[7 14],[15 30]};
run               = [2 3 4 5 6 7];
for i = 1:length(run)
    R             = run(i);
    for j         = 1:3
        F         = freqband{j};
        for k = 1:3
            Temprod_Dataviewer('s08',R,F,chantype{k},[1 2 3 2 1],'no',tag)
        end
    end
end


