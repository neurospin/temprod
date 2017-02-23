function stat=ns_btstat(tr1,tr2,av1,av2,lat,timepoints)
% stat=ns_stat(tr1,tr2,av1,av2,lat,timepoints)
% Computes ERF statistical analysis between two conditions, separately for
% each sensor group. Uses ns_btcra (btcra=between-trials cluster
% randomization analysis) which is based on ft_timelockstatistics.
% For extended info on the method: 
% type help ft_timelockstatistics and help statistics_montecarlo 
% or look at http://fieldtrip.fcdonders.nl/tutorial/cluster_permutation_timelock
%
% Input:
% tr1(tr2) = averaged dataset for condition 1(2) containing all the trials
% (from ft_timelockanalysis)
% av1(av2) = averaged dataset for condition 1(2) containing the averages
% only (from ft_timelockanalysis)
% lat = temporal latency over which statistical analysis is computed (in seconds)
% (example: lat=[0 0.4])
% timepoints = time points at which topographies are plotted (NOTE: must be WITHIN lat) 
% (example: timepoints=[0:0.05:0.3])
%
% Output:
% stat = cell containing statistics for each of the three groups of
% sensors.

sensors={'mag','grad1','grad2'};

% statlabel=[condition{1} 'vs' condition{2}];
for s=1:length(sensors)
    stat{s} = ns_btcra(tr1,tr2,sensors{s},lat);
    
%     % plot time course of maximum positive and negative cluster
%     [tppos,tpneg,t]=ns_stattimecourse(stat{s});
    
    % plot topography of the two conditions and of the difference with clusters
    % superposed, at times specified by cfg.lat (they must be within the time
    % interval used in the statistical analysis
    cfg             = [];
    cfg.layout      = 'NM306mag.lay';
    if s==1
        cfg.zlim        = [-3e-13 3e-13];
    else
        cfg.zlim        = [-3e-12 3e-12];
    end;
    cfg.zparam      = 'avg';
    cfg.lat         = timepoints;
    cfg.alpha       = 0.3; % threshold of cluster visualization
    ns_clusterplot(cfg,stat{s},av1,av2,sensors{s})
    
%     % plot time course of the two conditions averaged over the cluster
%     [roipos,roineg]=ns_statinfo(stat{s});       
%     ns_roierf(roipos{1},av1,av2,sensors{s}); 
%     ns_roierf(roineg{1},av1,av2,sensors{s});
end;
