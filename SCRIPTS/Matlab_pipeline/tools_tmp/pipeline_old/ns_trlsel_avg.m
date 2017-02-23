function avgsel = ns_trlsel_avg(data,trlval)
% function avgsel = ns_trlsel_avg(data,trlval)
% Selects trials in data specified in vector trlval and time-lock averages
% with ft_timelockanalysis.
% Input: 
% data = ft dataset, format: output of ft_preprocessing
% trlval = vector of values indicating trial selection. Set trlval=[] if
% you want to average across all trials.
% Example for selecting all trials coded by numbers 1,3,5: trlval=[1 3 5];
% Remember: Trial values are coded in data.trialinfo.
%
% Output:
% datasel = ft dataset, format: output of ft_timelockanalysis
% contains the average across trials in the field 'avg'.
% By default, it DOES NOT contain the single trials.
% NOTE: if data.avg already exists, it will be removed, otherwise
% ft_timelockanalysis will not work.
%
% Marco Buiatti, INSERM U992 Cognitive Neuroimaging Unit (France), 2011.

cfg             = [];
datasel=data;

if isfield(datasel,'avg')
    disp('Warning: a field avg already present in data: removed');
    datasel=rmfield(datasel,'avg');
end

if ~isempty(trlval)
    % datasel.trial=data.trial(find(ismember(data.cfg.trl(:,4),trlval))');
    datasel.trial=data.trial(find(ismember(data.trialinfo,trlval))');
end;
avgsel     = ft_timelockanalysis(cfg, datasel);
