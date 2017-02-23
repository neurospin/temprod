function [gtr1,gtr2,gav1,gav2] = ns_gave_old(subj,condition1,condition2)


% par.avdir
avdir='/neurospin/meg/meg_tmp/2010_auditorygaze_Lukasz/mAgaze/ft_data/av_data/';

for n=1:length(subj)
    if subj(n)<10 
        subjprefix = 's0';
    else
       subjprefix = 's';
    end;
    c1{n}=getfield(load([avdir subjprefix num2str(subj(n)) '_av.mat'], condition1),condition1);
    c1{n}.avg=ft_preproc_baselinecorrect(c1{n}.avg, 1, 161);
    c2{n}=getfield(load([avdir subjprefix num2str(subj(n)) '_av.mat'], condition2),condition2);
    c2{n}.avg=ft_preproc_baselinecorrect(c2{n}.avg, 1, 161);
end;

cfg=[];
cfg.keepindividual = 'yes';
gtr1=ft_timelockgrandaverage(cfg,c1{:});
gtr2=ft_timelockgrandaverage(cfg,c2{:});
gav1=ft_timelockgrandaverage([],c1{:});
gav2=ft_timelockgrandaverage([],c2{:});