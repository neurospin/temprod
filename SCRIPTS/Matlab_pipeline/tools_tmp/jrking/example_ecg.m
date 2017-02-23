addpath '/neurospin/local/mne/i686/share/matlab/'     % MNE (needed to read and import fif data in fieldtrip) 
addpath '/neurospin/meg/meg_tmp/tools_tmp/pipeline_tmp/'  % Neurospin pipeline scripts
addpath '/neurospin/meg/meg_tmp/PipelineTest/scripts/'    % local processing scripts
addpath '/neurospin/local/fieldtrip/'                 % fieldtrip
ft_defaults 

clear
cfg             = [];
cfg.ecgchan     = 307;
cfg.dataset     = '/neurospin/meg/meg_tmp/2010_auditorygaze_Lukasz/mAgaze/sss_data/s04_r1v3_M_raw_sss.fif';
cfg.dataset     = '/neurospin/meg/meg_tmp/2011_asdur_AnnaL/sss_data/tdc_01_1_sss.fif';
cfg.chantypes   = {setdiff(1:306, 3:3:306), 3:3:306}; 
data            = ft_jr_ecgeog(cfg);

hdr = ft_read_header(cfg.dataset)