function stat = ns_btcra_old(tl1,tl2)

load /neurospin/meg_tmp/tools_tmp/pipeline/neighbours.mat
load('/neurospin/meg_tmp/tools_tmp/pipeline/SensorClassification.mat');
tl1.label=Mag;
tl2.label=Mag;
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

% cfg.channel = {'*2'};   % cell-array with selected channel labels
cfg.latency = [0 0.4];   % time interval over which the experimental 
                         % conditions must be compared (in seconds)
                         
stat = ft_timelockstatistics(cfg, tl1, tl2);