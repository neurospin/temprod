function data=ns_fif2ft(par,run)
% function data=ns_fif2ft(par,run)
% Generates fieldtrip dataset data from fif dataset with parameters
% specified in par: 
% - Defines trials by ft_definetrial
% - Removes baseline
% - Performs preprocessing by ft_preprocessing
% - Concatenates data from all runs into a single dataset by ft_appenddata
%
% Input:
% par = dataset parameters defined in ns_par and ns_preproc
% run = number of run(s) to analyse. Example: run=[1 3]: analyse runs 1 and 3; run='all': analyse all runs.
% If more than one run is chosen, data from different runs are merged together in a single dataset. 
% 
% Output:
% data = fieldtrip dataset, format from ft_preprocessing
%
% Marco Buiatti, INSERM U992 Cognitive Neuroimaging Unit (France), 2011.

%% define parameters from par %%
cfg                     = [];
cfg.continuous          = 'yes';
cfg.headerformat        = 'neuromag_mne';
cfg.dataformat          = 'neuromag_mne';

% define trial parameters
cfg.trialfun =par.trialfun;               % function par.trialfun defines the trials
cfg.trialdef.channel='STI101';
cfg.trialdef.eventvalue=par.eventvalue;   % needed by par.trialfun to identify which channel contains the trigger values
cfg.trialdef.prestim=par.prestim;
cfg.trialdef.poststim=par.poststim;
cfg.delay = par.delay; 

% preprocessing parameters
% cfg.lpfilter   = 'yes';                   % apply lowpass filter
% cfg.lpfreq = 40;
cfg.channel    = {'MEG'};                   
% baseline correction
cfg.demean='yes';
cfg.baselinewindow=[-par.begt -par.endt];

%% trial definition and preprocessing
if strcmp(run,'all')
    run=par.run;
end;

for r=1:length(run)
    cfg.dataset = [par.sssdir par.subj par.runlabel{run(r)} '_sss.fif'];
    disp('Epoch extraction and conversion to Fieldtrip format:');
    disp(['Processing dataset ' cfg.dataset]);   
    % dataset configuration cfg
    cfg_loc = ft_definetrial(cfg);      % defines beginning and end of each trial on the basis of par.trialfun
    % load data in dataset structure defined by cfg_loc
    data{r}= ft_preprocessing(cfg_loc);
end;

% concatanate all runs into a single dataset
if length(run)>1                % concatenate only if more than one run, otherwise error.
   data=ft_appenddata(cfg,data{:});
else
    data=data{1};
end;

% add correct sensor labels
data.label=par.chlabels.All';
