function [av,tr]=ns_ave(par,trlval,trllabel)
% function [av,tr]=ns_ave(par,trlval,trllabel)
% - loads data from each run
% - selects epochs identified by the event value trlval 
% - concatenates them into a single dataset 
% - computes time-locked averages (either by keeping or not single trials)
% by using ft_timelockanalysis
% - saves averages in par.avdir
%
% Input:
% par = subject-specific par structure from ns_par
% trlval = value associated to the event of interest (all events coded in
% data.trialinfo and ns_trig)
% trllabel = label associated to trlval (see ns_trig)
%
% Output:
% av = time-locked average dataset (no single trials), format from ft_timelockanalysis
% tr = time-locked average dataset (including single trials), format from ft_timelockanalysis
%
% Marco Buiatti, INSERM U992 Cognitive Neuroimaging Unit (France), 2011.

%% Initialize %%
data_loc=cell(length(par.run),1);

%% Load data for each run %%
for r=1:length(par.run)
    dataname=[par.ftdir par.subj 'run' num2str(par.run(r)) 'pp'];
    disp(['Loading ' dataname '...']);
    load(dataname,'data');
    %% select trials based on trlval
    data.trial=data.trial(find(ismember(data.trialinfo,trlval))');
    data.trialinfo=data.trialinfo(find(ismember(data.trialinfo,trlval))');
    data_loc{r} = data;
    clear data;
end;
%% concatenate data from different runs %%
datasel=ft_appenddata([],data_loc{:});
clear data_loc;
%% LowPassFiltering %%
if ~isempty(par.lpf)
    [par,datasel]=ns_lpf(par,datasel,par.lpf); % use: [par,data]=ns_lpf(par,data,par.lpf) where par.lpf=low-pass frequency in Hz
end
%% Compute time-locked average either by not keeping the trials ('av', for visualization and within-subjects stats) 
%% or keeping them ('tr', for between-trials stats) %%
cfg = [];
cfg.keeptrials  = 'no';
av = ft_timelockanalysis(cfg, datasel);
cfg = [];
cfg.keeptrials = 'yes';
tr = ft_timelockanalysis(cfg, datasel);
%% save data %%
avname=[par.avdir par.subj trllabel 'av'];
trname=[par.avdir par.subj trllabel 'tr'];
disp(['Saving av data in ' avname '...']);
save(avname,'av','-v7.3');
disp(['Saving tr data in ' trname '...']);
save(trname,'tr','-v7.3');
disp('Done.');
