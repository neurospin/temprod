function ns_plotstat(stat,av1,av2,lat,tshw)
% function ns_plotstat(stat,av1,av2,lat,tshw)
% Plots a series of topoplots with found clusters highlighted.
%
% Input:
%
% stat is computed from FT_TIMELOCKSTATISTICS
% av1(av2) = averaged dataset for condition 1(2) containing the averages
% only
% lat = temporal latency over which statistical analysis is computed (in seconds)
% (example: lat=[0 0.4])
% 
% tshw = time-smoothing half-width, in seconds, determines the half
% temporal window over which topographies are averaged around the latencies
% determined by cfg.lat (choose 0 for no smoothing)
%
% Marco Buiatti, INSERM Cognitive Neuroimaging Unit, Neurospin (2011).

sensors={'mag','grad1','grad2'};

for s=1:length(sensors)
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
    cfg.lat         = lat;
    cfg.alpha       = 0.3; % threshold of cluster visualization
    ns_clusterplot_timesmooth(cfg,stat{s},av1,av2,sensors{s},tshw)
end;
