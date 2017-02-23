function [gav,gtr] = ns_gave(par,subj,trllabel)

for n=1:length(subj)
    if subj(n)<10 
        subjprefix = 's0';
    else
       subjprefix = 's';
    end;
    data{n}=getfield(load([par.avdir subjprefix num2str(subj(n)) trllabel 'av.mat']),'av');
end;

gav=ft_timelockgrandaverage([],data{:});

cfg=[];
cfg.keepindividual = 'yes';
gtr=ft_timelockgrandaverage(cfg,data{:});

%% save data %%
avname=[par.avdir trllabel 'gav'];
trname=[par.avdir trllabel 'gtr'];
disp(['Saving av data in ' avname '...']);
save(avname,'gav','-v7.3');
disp(['Saving tr data in ' trname '...']);
save(trname,'gtr','-v7.3');
disp('Done.');