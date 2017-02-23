function trl = trialfun_temprod_OLD_uniquetrial(cfg)

% cfg.dataset = '/neurospin/meg_tmp/temprod_Baptiste_2010/DATA/NEW/Trans_sss_s04/s04_run6_raw_sss.fif';

events = ft_read_header(cfg.dataset);

trl(1,1) = 1 ;
trl(1,2) = events.orig.raw.last_samp - events.orig.raw.first_samp -10;
trl(1,3) = 0;
