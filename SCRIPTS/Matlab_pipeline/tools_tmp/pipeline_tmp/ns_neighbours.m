function neighbours=ns_neighbours(tl)
% compute neighbours
% tl=the output of ft_timelockanalysis or ft_timelockgrandaverage from any neuromag dataset
% Mag=labels from /neurospin/meg_tmp/tools_tmp/pipeline/SensorClassification.mat
% tl1.label=Mag;
cfg = [];
cfg.layout = 'NM306mag.lay';
cfg.neighbourdist = 0.2;
cfg.feedback = 'yes'; % if you select 'yes', neighbours for each sensor will be plotted one after the other
neighbours = ft_neighbourselection(cfg, tl);
