function par = ns_par(n)
% function par = ns_par(n) where n is the subject number
% Specifies subject information, trigger definition and trial function. 
% 
% Parameters here refer to the experiment 'PipelineTest' as an example. 

%% EXPERIMENT-SPECIFIC INFORMATION %%   
%% path to relevant directories (to be generated in advance) %%
par.rawdir      = '/neurospin/meg/meg_tmp/PipelineTest/data/raw/';   % Raw data
par.hpdir       = '/neurospin/meg/meg_tmp/PipelineTest/data/hp/';    % Head position text file
par.sssdir      = '/neurospin/meg/meg_tmp/PipelineTest/data/sss/';   % SSS data
par.mfdir       = '/neurospin/meg/meg_tmp/PipelineTest/data/sss/mf_scripts/'; % Maxfilter scripts
par.ftdir       = '/neurospin/meg/meg_tmp/PipelineTest/data/ft/';    % fieldtrip data
par.avdir       = '/neurospin/meg/meg_tmp/PipelineTest/data/ft/ave/'; % fieldtrip average data
par.statdir     = '/neurospin/meg/meg_tmp/PipelineTest/data/ft/stats/'; % fieldtrip cluster stats

%% General parameters %%
% load sensor labels
par.chlabels=load('/neurospin/meg/meg_tmp/tools_tmp/pipeline/SensorClassification.mat'); 

% Epoch definition: Prestimulus and poststimulus time extremes in seconds
par.prestim         = 0.4;             
par.poststim        = 0.4;

% Baseline definition: time extremes from 0 in seconds (don't put minus)
par.begt            = 0.4;             
par.endt            = 0.24;            

% low-pass frequency (set to [] to skip filtering)
par.lpf             = 40;              

% stimulus delay in seconds.
% (to compute it, see http://www.unicog.org/pm/pmwiki.php/MEG/Stimulus-triggerDelay)
% will be used in ns_trialfun, called by ft_definetrial.
par.delay           = 0.34;            

%% Trigger definition %%
% Define the triggers (value and label) that identify your epochs of interest by writing your own ns_trig function.
par.eventvalue      = ns_trig;
% Indicate the function that identifies the triggers in your data.
% In ns_trialfun, trigger times and values are computed from the difference between
% consecutive stimulus channel values 
% You can write your own trial definition function if you want.
par.trialfun        = 'ns_trialfun';        

%% SUBJECT-SPECIFIC INFORMATION %%
switch n
    case 1
        par.subj        = 's01';                                % Subject name
        par.runlabel    = {'run1_raw','run2_raw','run3_raw'};   % label of each run
        par.badch{1}    = '0543';                               % bad channels for each run
        par.badch{2}    = '0543';
        par.badch{3}    = '0543';
    % ...here you can add as many subjects as you want %  
    case 14
        par.subj        = 's14';                                % Subject name
        par.runlabel    = {'run1_raw','run2_raw','run3_raw'};   % label of each run
        par.badch{1}    = '0543 2313';                          % bad channels for each run
        par.badch{2}    = '0543 0422';
        par.badch{3}    = '0543';        
    otherwise
        disp('Error: Incorrect subject number');
end

par.run         = 1:length(par.runlabel);                                  % Number of runs

%% ECG/EOG PCA projection (to be computed after maxfilter)
par.pcapath     = [par.sssdir par.subj 'pca/'];
par.samplefile  = [par.sssdir par.subj par.runlabel{1} '_sss.fif'];
par.chansel     = 'MEG'; %MEG,eeg,mag,grad or allchan
