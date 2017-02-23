function ns_erf(sensors,varargin)
% function ns_erf(sensors,varargin)
% Plots ERF time courses using ft_multiplotER. See help ft_multiplotER for
% more options.
% Input:
% sensors = 'all' for all sensors, 'mag' for magnetometers, 'grad' for gradiometers.
% varargin = averaged data from ns_ave using ft_timelockanalysis. Multiple
% datasets can be plotted simultaneously.
% 1st dataset is plotted in blue, 2nd in red, 3rd in green
%
% Example: ns_erf('grad',ALVCav,ARVCav);

figure
cfg = [];
cfg.showlabels = 'yes'; 
cfg.fontsize = 8; 
cfg.interactive = 'yes';
% cfg.graphcolor = 'rygbgyr';
switch lower(sensors)
    case{'all'}
        cfg.layout = 'NM306all.lay';
    case{'mag'}
        cfg.layout = 'NM306mag.lay';
    case{'grad'}
        cfg.layout = 'NM306planar.lay';
    otherwise
        error([sensors ' is an unknown sensor type. Options are: all, mag, grad.'])
end
ft_multiplotER(cfg, varargin{:});
