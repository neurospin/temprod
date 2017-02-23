%% ns_erfanalysis %%
% Visualization of ERFs from data preprocessed with ns_preproc.
% Between-subjects statistical analysis.
% Uses Fieldtrip. 
% Parameters 'par' are specific for each subject and experiment.
%
% Marco Buiatti, INSERM U992 Cognitive Neuroimaging Unit (France), 2011.

%% set path %%
addpath '/neurospin/local/mne/i686/share/matlab/'     % MNE (needed to read and import fif data in fieldtrip 
addpath '/neurospin/meg_tmp/tools_tmp/pipeline_tmp/'  % Neurospin pipeline scripts
addpath '/neurospin/meg_tmp/PipelineTest/scripts/'    % local processing scripts
addpath '/neurospin/local/fieldtrip/'                 % fieldtrip
ft_defaults                                           % sets fieldtrip defaults and configures the minimal required path settings 

%% subject information, trigger definition and trial function %%
% Number of subject to analyze
n   = 14; 
par = ns_par(n);

%% =========================================================================
%% ERF PLOTS
%% =========================================================================
%% Load relevant averages %%
%% Example with two conditions %%
condition={'ALVC','ARVC'};
for c=1:length(condition)
    load([par.avdir par.subj condition{c} 'av'],'av');
    eval([condition{c} 'av=av;']);
    clear av;
end;

%% Plot ERF time courses for each sensor arranged according to their location specified in the layout.%%
% 'all' for all sensors, 'mag' for magnetometers, 'grad' for gradiometers.
% 1st dataset is plotted in blue, 2nd in red, 3rd in green
ns_erf('mag',ALVCav,ARVCav);
ns_erf('grad',ALVCav,ARVCav);

%% Plot topographies for each sensor type at specified latencies
tlim=0:0.05:0.3;                       % tlim = [tmin:tstep:tmax] in seconds
zmax=3*10^(-12); 
ns_multitopoplotER(ALVCav,tlim,zmax);  % first column: grad1, second column: grad 2, third column: mag
ns_multitopoplotER(ARVCav,tlim,zmax);  % first column: grad1, second column: grad 2, third column: mag
%% each row shows topography of first dataset, second dataset and 1st minus 2nd at each time interval;
% first figure: grad1, second figure: grad 2, third figure: mag
ns_multitopoplotERdiff(ALVCav,ARVCav,tlim,zmax); 

%% =========================================================================
%% ERF STATISTICAL ANALYSIS
%% =========================================================================

%% Two conditions, between-trials analysis (see http://fieldtrip.fcdonders.nl/tutorial/cluster_permutation_timelock)
%% Example with two conditions %%
condition={'ALVC','ARVC'};

% temporal latency over which statistical analysis is computed (in seconds)
lat = [0 0.4];

% load data with and without trials for between-trials statistical analysis
for c=1:length(condition)
    load([par.avdir par.subj condition{c} 'av'],'av');
    load([par.avdir par.subj condition{c} 'tr'],'tr');
    eval([condition{c} 'av=av;']);
    eval([condition{c} 'tr=tr;']);
    clear av;
    clear tr;
end;

% compute statistical analysis separately for each type of sensor
timepoints=[0:0.5:0.3]; % time points at which topographies are plotted (NOTE: must be WITHIN lat) 
stat=ns_btstat(ALVCtr,ARVCtr,ALVCav,ARVCav,lat,timepoints);

% Plots a series of topoplots with found clusters highlighted. Topography may be time-smoothed (see help ns_plotstat). 
ns_plotstat(stat,ALVCav,ARVCav,[0.05:0.05:0.3],0.01);

% plot cluster statistics time course, topography at peak of cluster statistics and ERFs of single clusters
% computed with FT CRA. In this example: plotting magnetometers, second
% negative cluster, topography time smoothing of 0.01 s (see help ns_plotsinglecluster).  
ns_plotsinglecluster(stat,ALVCav,ARVCav,1,-2,0.01); 

%% save data %%
statlabel=[condition{1} 'vs' condition{2}];
statname=[par.avdir par.subj 'stat' statlabel];
disp(['Saving stats in ' statname ' ...']);
save(statname,'stat','-v7.3');
disp('Done.');

%% Two conditions, within-subjects analysis (see http://fieldtrip.fcdonders.nl/tutorial/cluster_permutation_timelock)
%% Example with two conditions %%
condition={'ALVC','ARVC'};

% temporal latency over which statistical analysis is computed (in seconds)
lat = [0 0.4];

% compute grand-average over subjects 1 and 14 on selected condition
[gALVCav,gALVCtr] = ns_gave(par,[1 14],'ALVC');
[gARVCav,gARVCtr] = ns_gave(par,[1 14],'ARVC');

% compute within-subjects statistical analysis separately for each type of sensor
gstat=ns_wsstat(gALVCtr,gARVCtr,gALVCav,gARVCav,[0 0.3],[0:0.05:0.3]);

% Plots a series of topoplots with found clusters highlighted. Topography may be time-smoothed (see help ns_plotstat). 
ns_plotstat(stat,gALVCav,gARVCav,[0.05:0.05:0.3],0);

% plot cluster statistics time course, topography at peak of cluster statistics and ERFs of single clusters
% computed with FT CRA. In this example: plotting magnetometers, second
% negative cluster, topography time smoothing of 0.01 s (see help ns_plotsinglecluster).  
ns_plotsinglecluster(stat,gALVCav,gARVCav,3,-1,0.01);