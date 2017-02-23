function stat = ns_btcra(tl1,tl2,channel,lat)
% function stat = ns_btcra(tl1,tl2,channel,lat) 
% computes *between-trials* statistical difference between conditions 1 and 2 by cluster
% randomization analysis implemented in Fieldtrip. For extended info on the method: 
% type help ft_timelockstatistics and help statistics_montecarlo 
% or look at http://fieldtrip.fcdonders.nl/tutorial/cluster_permutation_timelock
% 
% Input: 
% tl1(tl2) = time-locked dataset relative to condition 1(2) computed with ft_timelockanalysis 
%            (all trials must be included!)
% channel =  selection of channel set. Options are 'mag' (magnetometers),
%           'grad1' (first set of gradiometers), 'grad2' (second set of gradiometers) 
% lat  =    [begin end] in seconds or 'all': temporal latency in seconds over which statistical analysis is computed 
%           ('all' includes the whole trial time window).
%
% Output:
% stat = structure containing all the information about the spatiotemporal
% clusters on which the difference between the two conditions is
% statistically significant. Look at
% http://fieldtrip.fcdonders.nl/tutorial/cluster_permutation_timelock for
% details.
%
% Marco Buiatti, Cognitive Neuroimaging Unit, France (2011)
%
% 

% load neighbour sensors configuration (independently from channel
% selection, the magnetometers layout is loaded, as channel position is the
% same for the three types of sensors).
load('/neurospin/meg/meg_tmp/tools_tmp/pipeline/neighbours.mat');

% select channels in the data
load('/neurospin/meg/meg_tmp/tools_tmp/pipeline/SensorClassification.mat');
switch channel
    case 'mag'
        tl1 = ft_selectdata(tl1,'channel',Mag);
        tl2 = ft_selectdata(tl2,'channel',Mag);
    case 'grad1'
        tl1 = ft_selectdata(tl1,'channel',Grad_1);
        tl2 = ft_selectdata(tl2,'channel',Grad_1);
    case 'grad2'
        tl1 = ft_selectdata(tl1,'channel',Grad_2);
        tl2 = ft_selectdata(tl2,'channel',Grad_2);
    otherwise
        disp('Error: Incorrect channel selection!');
end;

% re-label channels to match the neighbour sensors configuration
tl1.label=Mag;
tl2.label=Mag;

% parameters of the statistical analysis
cfg = [];
cfg.method = 'montecarlo';       % use the Monte Carlo Method to calculate the significance probability
cfg.statistic = 'indepsamplesT'; % use the independent samples T-statistic as a measure to evaluate 
                                 % the effect at the sample level
cfg.correctm = 'cluster';
cfg.clusteralpha = 0.05;         % alpha level of the sample-specific test statistic that will be used for thresholding
cfg.clusterstatistic = 'maxsum'; % test statistic that will be evaluated under the permutation distribution. 
cfg.minnbchan = 2;               % minimum number of neighborhood channels that is required for a selected 
                                 % sample to be included in the clustering algorithm (default=0).
cfg.neighbours = neighbours;
                                 
cfg.tail = 0;                    % -1, 1 or 0 (default = 0); one-sided or two-sided test
cfg.clustertail = 0;
cfg.alpha = 0.025;               % alpha level of the permutation test
cfg.numrandomization = 100;      % number of draws from the permutation distribution

design = zeros(1,size(tl1.trial,1) + size(tl2.trial,1));
design(1,1:size(tl1.trial,1)) = 1;
design(1,(size(tl1.trial,1)+1):(size(tl1.trial,1) + size(tl2.trial,1)))= 2;

cfg.design = design;             % design matrix
cfg.ivar  = 1;                   % number or list with indices, independent variable(s)

cfg.latency = lat;   % time interval over which the experimental 
                         % conditions must be compared (in seconds)

%compute the stat!
stat = ft_timelockstatistics(cfg, tl1, tl2);

%% display basic information on significant clusters %%
ns_statinfo(stat);