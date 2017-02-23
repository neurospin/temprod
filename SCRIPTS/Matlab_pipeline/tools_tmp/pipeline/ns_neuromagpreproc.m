function par=ns_neuromagpreproc(par)
% =========================================================================
% STEP1 head movement correction, maxfilter, pca
% =========================================================================
%% correct for Head Movement between runs %%
% Generate an SH script that computes head position for each run and saves it in a txt file
ns_getheadmv(par);
% plot head movement rotation/translation coordinates across runs
dataheadmv=ns_checkheadmv(par); % dataheadmv contains all info on head movements for each run
% Based on the rotation/translation plot, choose a run as the ref for head position %
par.hprun = input('The figure displays the head position coordinates for each run.\nChoose the run for which the head position is closest to the average position of the other runs.\nType its number and press enter:\n');
disp(['Run ' num2str(par.hprun) ' selected as head reference run.']);
%% perform MaxFilter processing %%
% data saved in a folder specified by par.
% !! insure the list of BAD sensors has been specified for each run !!!
% ref: www.unicog.org/pmwiki/pmwiki.php/Main/AnalysisWithMaxfilter
ns_maxfilter(par);
