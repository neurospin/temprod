function ns_rejectvisual(par)
%% =========================================================================
%% STEP3 visual artifact detection / verify data clean
%% =========================================================================
cfg=[];
cfg.method='summary';
% cfg.method='trial';
cfg.alim     = 4e-11; 
cfg.megscale = 1;
for r=1:length(par.run)
    %% Load data for each run %%
    dataname=[par.ftdir par.subj 'run' num2str(par.run(r)) 'pp'];
    disp(['Loading ' dataname '...']);
    load([par.ftdir par.subj 'run' num2str(par.run(r)) 'pp'],'data');
    %% Visual epoch rejection %% 
    data=ft_rejectvisual(cfg,data);     % ref: help ft_rejectvisual in matlab
    %% Overwrite data to save memory %% 
    disp(' ');
    disp(['Saving clean data in ' dataname '...']);
    save(dataname,'data','-v7.3','-append');
    disp('Done.');
    disp(' ');
end;
