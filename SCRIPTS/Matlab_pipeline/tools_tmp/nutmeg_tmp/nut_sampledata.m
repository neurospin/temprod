function data=nut_sampledata(par,trlval)
data_loc=cell(length(par.run),1);
for r=1:length(par.run)
    data_loc{r}=ns_fif2ft(par,par.run(r));
    %% select trials based on trlval
    data_loc{r}.trial=data_loc{r}.trial(find(ismember(data_loc{r}.trialinfo,trlval))');
    data_loc{r}.trialinfo=data_loc{r}.trialinfo(find(ismember(data_loc{r}.trialinfo,trlval))');
end;
%% disable warnings to avoid displaying fieldtrip complaining about the different origin of the datasets %%
% warning off;
%% concatenate data from different runs %%
data=ft_appenddata([],data_loc{:});
clear data_loc;
% %% LowPassFiltering %%
% if ~isempty(par.lpf)
%     [par,datasel]=ns_lpf(par,datasel,par.lpf); % use: [par,data]=ns_lpf(par,data,par.lpf) where par.lpf=low-pass frequency in Hz
% end
% %% Compute time-locked average either by not keeping the trials ('av', for visualization and across-subjects stats) 
% %% or keeping them ('tr', for within-subject stats) %%
% cfg = [];
% cfg.keeptrials  = 'no';
% av = ft_timelockanalysis(cfg, datasel);
% cfg = [];
% cfg.keeptrials = 'yes';
% tr = ft_timelockanalysis(cfg, datasel);
% %% save data %%
% avname=[par.avdir par.subj trllabel 'av'];
% trname=[par.avdir par.subj trllabel 'tr'];
% disp(['Saving av data in ' avname '...']);
% save(avname,'av','-v7.3');
% disp(['Saving tr data in ' trname '...']);
% save(trname,'tr','-v7.3');
% disp('Done.');
