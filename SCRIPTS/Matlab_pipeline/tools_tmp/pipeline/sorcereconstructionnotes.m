% 1: segmentation
mri = ft_read_mri('Subject01.mri');
cfg = [];
cfg.write      = 'no';
cfg.coordsys   = 'ctf';
[segmentedmri] = ft_volumesegment(cfg, mri);

% 2: prepare the head model
cfg = [];
vol = ft_prepare_singleshell(cfg, segmentedmri);

% 3: discretize the brain volume into a grid. For each grid point the lead field matrix is calculated.
cfg                 = [];
cfg.grad            = freqPre.grad;
cfg.vol             = vol;
cfg.reducerank      = 2;
cfg.channel         = {'MEG','-MLP31', '-MLO12'};
cfg.grid.resolution = 1;   % use a 3-D grid with a 1 cm resolution
[grid] = ft_prepare_leadfield(cfg);

% 4: source reconstruction of the sensor space data
cfg              = []; 
cfg.frequency    = 18;  
cfg.method       = 'dics';
cfg.projectnoise = 'yes';
cfg.grid         = grid; 
cfg.vol          = vol;
cfg.lambda       = 0;

sourcePre  = ft_sourceanalysis(cfg, freqPre );
sourcePost = ft_sourceanalysis(cfg, freqPost);