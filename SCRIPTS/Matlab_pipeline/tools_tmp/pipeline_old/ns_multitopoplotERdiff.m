function ns_multitopoplotERdiff(ave1,ave2,tlim,zmax)
% function multi_topoplotER(data,tlim,zmax) plots topography of the three
% sensor types separately for a selection of time intervals 
% Input:
% davg = averaged data = data.avg if data = fieldtrip dataset, format from
% ft_timelockanalysis, = data if data = grand averaged fieldtrip dataset,
% format from ft_timelockgrandaverage
% tlim = time intervals within which ERFs are averaged. 
% Example: tlim = [0:0.1:0.3] for time intervals [0 0.1], [0.1 0.2] and [0.2 0.3] (in seconds);
% zmax = z limits (1/magfactor for Mag)
%
% Marco Buiatti, INSERM U992 Cognitive Neuroimaging Unit (France), 2010.

load SensorClassification.mat
chtype={Grad_1,Grad_2,Mag};
cfg = [];
cfg.layout = 'NM306all.lay';
cfg.comment ='xlim';
cfg.marker='off';
magfactor=10;   % amplification of mag amplitude scale compared to grad
for i=1:length(chtype)
    [sel1, sel2] = match_str(All, chtype{i});
    figure
    dloc=ave1;
    dloc.label=chtype{i};
    if i==3 cfg.zlim=[-zmax,zmax]/magfactor; else cfg.zlim=[-zmax,zmax]; end;
    for j=1:length(tlim)-1
        cfg.xlim=[tlim(j) tlim(j+1)];
        subplot(size(tlim,2),3,3*(j-1)+1)
        dloc.avg=ave1.avg(sel1,:);
        ft_topoplotER(cfg, dloc);
        subplot(size(tlim,2),3,3*(j-1)+2)
        dloc.avg=ave2.avg(sel1,:);
        ft_topoplotER(cfg, dloc);
        subplot(size(tlim,2),3,3*(j-1)+3)
        dloc.avg=ave1.avg(sel1,:)-ave2.avg(sel1,:);
        ft_topoplotER(cfg, dloc);
    end;
end;