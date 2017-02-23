function ns_fif2ftssp(par)
%% =========================================================================
%% STEP2 import in fieldtrip format, apply projection matrix
%% =========================================================================
%% generate epoched fieldtrip dataset %%
for r=1:length(par.run)
    data=ns_fif2ft(par,par.run(r));              % watch out, this step includes baseline correction!!
    %% applies PCA (computed with graph) to data %%
    data=ns_applyprojmat(par,data);
    %% save preprocessed data %%
    outfile=[par.ftdir par.subj 'run' num2str(par.run(r)) 'pp'];
    disp(' ');
    disp(['Saving processed data in ' outfile '...']); 
    save(outfile,'data','par','-v7.3');
    %% clear workspace %%
    clear data;
    disp('Done.');
    disp(' ');
end;


