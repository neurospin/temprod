function ns_multitopoplotER(davg,tlim,zmax)
% function multi_topoplotER(data,tlim,zmax) plots topography of the three
% sensor types separately for a selection of time intervals 
% Input:
% davg = averaged data from ns_ave, format from ft_timelockanalysis
% tlim = time points within which ERFs are averaged. 
% Example: tlim = [0:0.1:0.3] for time intervals [0 0.1], [0.1 0.2] and [0.2 0.3] (in seconds);
% zmax = z limits (1/magfactor for Mag)
%
% Marco Buiatti, INSERM U992 Cognitive Neuroimaging Unit (France), 2011.

load('/neurospin/meg/meg_tmp/tools_tmp/pipeline/SensorClassification.mat');
chtype={Grad_1,Grad_2,Mag};
cfg = [];
cfg.layout = 'NM306all.lay';
cfg.comment ='xlim';
cfg.marker='off';
magfactor=10;   % amplification of mag amplitude scale compared to grad
figure
dloc=davg;
for j=1:length(tlim)-1
    cfg.xlim=[tlim(j) tlim(j+1)];
    for i=1:length(chtype)
        if i==3 cfg.zlim=[-zmax,zmax]/magfactor; else cfg.zlim=[-zmax,zmax]; end; 
        subplot(length(tlim),3,i+3*(j-1))
        [sel1, sel2] = match_str(All, chtype{i});
        dloc.label=chtype{i};
        dloc.avg=davg.avg(sel1,:);
        ft_topoplotER(cfg, dloc);
    end;
end;