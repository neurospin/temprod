% Make a vector of all p-values associated with the clusters from ft_timelockstatistics.
pos_cluster_pvals = [stat.posclusters(:).prob];
% Then, find which clusters are significant, outputting their indices as held in stat.posclusters
pos_signif_clust = find(pos_cluster_pvals < stat.cfg.alpha);
% (stat.cfg.alpha is the alpha level we specified earlier for cluster comparisons; In this case, 0.025)
% make a boolean matrix of which (channel,time)-pairs are part of a significant cluster
pos = ismember(stat.posclusterslabelmat, pos_signif_clust);

% and now for the negative clusters...
neg_cluster_pvals = [stat.negclusters(:).prob];
neg_signif_clust = find(neg_cluster_pvals < stat.cfg.alpha);
neg = ismember(stat.negclusterslabelmat, neg_signif_clust);

t1=0.07;
t2=0.15;
t=stat.time;
timestep = 0.01;		% timestep between time windows for each subplot (in seconds)
sampling_rate = 1000;	% Data has a temporal resolution of 300 Hz
j = t1:timestep:t2;
[a,s1]=min(abs(t-t1));
[a,s2]=min(abs(t-t2));
m = s1:timestep*sampling_rate:s2;
					% number of temporal samples in the statistics object
%j = [stat.time(1):timestep:stat.time(end)];   % Temporal endpoints (in seconds) of the ERP average computed in each subplot
%m = [1:timestep*sampling_rate:sample_count];  % temporal endpoints in MEEG samples

figure;
for k = 1:length(j)-1;
     subplot(2,4,k);
     cfg = [];   
     cfg.xlim=[j(k) j(k+1)];   % time interval of the subplot
     cfg.zlim = [-2.5e-13 2.5e-13];
   % If a channel reaches this significance, then
   % the element of pos_int with an index equal to that channel
   % number will be set to 1 (otherwise 0).
   
   % Next, check which channels are significant over the
   % entire time interval of interest.
     pos_int = all(pos(:, m(k):m(k+1)), 2);
     neg_int = all(neg(:, m(k):m(k+1)), 2);
     cfg.channel = {'*1'};
     cfg.highlight = 'on';
   % Get the index of each significant channel
     cfg.highlightchannel = find(pos_int | neg_int);
     cfg.comment = 'xlim';   
     cfg.commentpos = 'title';   
     cfg.layout = 'NM306mag.lay';
     ft_topoplotER(cfg, ARVRvsARVL);   
end