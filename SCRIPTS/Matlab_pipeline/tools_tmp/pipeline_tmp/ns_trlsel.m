function [avgsel,trialsel] = ns_trlsel(data,trlval)
% from function avgsel = ns_trlsel_avg(data,trlval)

datasel        = data;

if isfield(datasel,'avg')
    disp('Warning: a field avg already present in data: removed');
    datasel=rmfield(datasel,'avg');
end

if ~isempty(trlval)
    datasel.trial=data.trial(find(ismember(data.trialinfo,trlval))');
    datasel.trialinfo=data.trialinfo(find(ismember(data.trialinfo,trlval))');
end;

cfg             = [];
cfg.keeptrials  = 'yes';
trialsel        = ft_timelockanalysis(cfg, datasel);

cfg             = [];
cfg.keeptrials  = 'no';
avgsel          = ft_timelockanalysis(cfg, datasel);
