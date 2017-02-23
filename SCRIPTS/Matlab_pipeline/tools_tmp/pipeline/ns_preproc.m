%% ns_preproc %%
% Preprocessing pipeline of raw recordings leading to clean, averaged
% data. Uses MaxFilter, Fieldtrip. 
% Parameters 'par' are specific for each subject and experiment.
%
% Marco Buiatti, INSERM U992 Cognitive Neuroimaging Unit (France), 2011.

%% set path %%
addpath '/neurospin/local/mne/i686/share/matlab/'     % MNE (needed to read and import fif data in fieldtrip) 
addpath '/neurospin/meg/meg_tmp/tools_tmp/pipeline/'  % Neurospin pipeline scripts
addpath '/neurospin/meg/meg_tmp/PipelineTest/scripts/'    % local processing scripts
addpath '/neurospin/local/fieldtrip/'                 % fieldtrip
ft_defaults                                           % sets fieldtrip defaults and configures the minimal required path settings 

%% STEP 1: subject information, trigger definition and trial function %%
% Number of subject to analyze
n   = 14; 
par = ns_par(n);

% =========================================================================
%% STEP 2: head movement correction, maxfilter %%
% =========================================================================
% Based on the rotation/translation plot, choose a run as the ref for head position %
par=ns_neuromagpreproc(par);

%% STEP 3: now use GRAPH to proceed with ECG and EOG artefact removals using PCA %%
% www.unicog.org/pm/pmwiki.php/MEG/CheckingDataWithNeuromagTools section (3)
 
%% =========================================================================
%% STEP 4: import in fieldtrip format, apply projection matrix
%% =========================================================================
ns_fif2ftssp(par);

%% =========================================================================
%% STEP 5: visual artifact detection / verify data clean
%% =========================================================================
ns_rejectvisual(par);

%% =========================================================================
%% STEP 6: trial selection, average, filtering %%
%% =========================================================================
%% Example with two conditions:

triggervalue=[12];
triggerlabel='ALVC';
[av,tr]=ns_ave(par,triggervalue,triggerlabel);
clear av tr;

triggervalue=[32];
triggerlabel='ARVC';
[av,tr]=ns_ave(par,triggervalue,triggerlabel);
clear av tr;

