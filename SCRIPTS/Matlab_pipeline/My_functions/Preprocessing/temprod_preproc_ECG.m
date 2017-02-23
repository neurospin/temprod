function datapath = temprod_preproc_ECG(run,isdownsample,subject,runref,rejection,freqband)

% subject information, trigger definition and trial function %%
par.Sub_Num            = subject;
par.RawDir             = ['/neurospin/meg/meg_tmp/temprod_Baptiste_2010/DATA/NEW/Raw_' subject '/'];
par.DirHead            = ['/neurospin/meg/meg_tmp/temprod_Baptiste_2010/DATA/NEW/HeadMvt_' subject '/'];
par.DataDir            = ['/neurospin/meg/meg_tmp/temprod_Baptiste_2010/DATA/NEW/Trans_sss_' subject '/'];
par.ProcDataDir        = ['/neurospin/meg/meg_tmp/temprod_Baptiste_2010/DATA/NEW/processed_' subject '/'];
par.run                = run;

% MaxFilter parameters
par.DirMaxFil          = '/neurospin/meg/meg_tmp/temprod_Baptiste_2010/SCRIPTS/Maxfilter_scripts/';
par.NameMaxFil         = ['Maxfilter_temprod_OLD_' subject];
% ECG/EOG PCA projection
par.pcaproj            = ['_run' num2str(runref) '_raw_sss.fif'];
par.projfile_id        = 'compmeg';
% correct for Head Movement between runs %%
% made outside of fieldtrip
% perform MaxFilter processing %%
% made outside of fieldtrip

% generate epoched fieldtrip dataset %%

% define parameters from par %%
cfg                         = [];
cfg.continuous              = 'no';
cfg.headerformat            = 'neuromag_mne';
cfg.dataformat              = 'neuromag_mne';
cfg.trialdef.channel        = 'STI101';
cfg.trialdef.prestim        = 0;
cfg.trialdef.poststim       = 0;
cfg.photodelay              = 0.0038;
if strcmp(subject,'s10') == 1
   cfg.trialfun             =  'trialfun_temprod_OLD_cond2_s10';
else
cfg.trialfun                = 'trialfun_temprod_OLD_cond2';
end
cfg.Sub_Num                 = par.Sub_Num;
cfg.lpfreq                  = 'no';
cfg.dftfilter               = 'yes';


% trial definition and preprocessing
for i                       = par.run
    disp(['processing run ' num2str(i)]);
    cfg.dataset             = [par.DataDir par.Sub_Num '_run' num2str(i) '_raw_sss.fif'];
    cfg.DataDir             = par.DataDir;
    cfg.channel             = {'ECG*';'EEG063'};
    cfg.run                 = i;
    cfg_loc{1,i}            = ft_definetrial(cfg);
    data{1,i}               = ft_preprocessing(cfg_loc{1,i});
    MaxLength{1,i}          = (max(cfg_loc{1,i}.trl(:,2) - cfg_loc{1,i}.trl(:,1)))/data{1,i}.fsample;
    sampleinfo{1,i}         = data{1,i}.sampleinfo;
end

datatmp.trial              = {};
datatmp.time               = {};
datatmp.sampleinfo         = [];

for i = 1:length(data)
    if isempty(data{1,i}) ~= 1
        datatmp.hdr        = data{1,i}.hdr;
        %         datatmp.grad       = data{1,i}.grad;
        datatmp.fsample    = data{1,i}.fsample;
        datatmp.cfg        = data{1,i}.cfg;
        datatmp.label      = data{1,i}.label;
        datatmp.trial      = [datatmp.trial data{1,i}.trial];
        datatmp.time       = [datatmp.time  data{1,i}.time ];
        datatmp.sampleinfo = [datatmp.sampleinfo ; data{1,i}.sampleinfo];
    end
end

clear data;
data = datatmp;
sampleinfo = datatmp.sampleinfo;
MaxLength = max(max(sampleinfo));

% downsampling data
cfg                    = [];
cfg.resamplefs         = 250;
cfg.detrend            = 'no';
cfg.blc                = 'no';
cfg.feedback           = 'no';
cfg.trials             = 'all';
if isdownsample        == 1
    data               = ft_resampledata(cfg,data);
end

% rejection of outliers trials (based on trial duration)
if rejection == 1;
    for i = 1:length(data.trial)
        durations(i) = size(data.trial{1,i},2);
    end
    
    q1                  = prctile(durations,25); % first quartile
    q3                  = prctile(durations,75); % third quartile
    myiqr               = iqr(durations);        % interquartile range
    lower_inner_fence   = q1 - 2*myiqr;
    upper_inner_fence   = q3 + 2*myiqr;
    
    index = [];
    a = 0;
    for i = 1:length(durations)
        if durations(i) < lower_inner_fence || durations(i) > upper_inner_fence
            a = a + 1;
            index(a) = i;
        end
    end
    
    info = [];
    if isempty(index) == 0
        a = 1; b = 1;
        for i = 1:length(data.trial)
            if i ~= index(b)
                tmp.trial{1,a} = data.trial{1,i};
                tmp.time{1,a}  = data.time{1,i};
                info(a,:) = sampleinfo(i,:);
                a = a + 1;
            elseif i == index(b) && b ~= length(index)
                b = b + 1;
            else i == index(b) && b == length(index)
            end
        end
        data.trial = tmp.trial;
        data.time  = tmp.time;
        data.sampleinfo = info;
    end
end

if isempty(info)
    info = sampleinfo;
end

MaxLength = [];
MinLength = [];
for i = 1:size(data.time,2)
    MaxLength = max([MaxLength length(data.time{i})]);
    MinLength = min([MinLength length(data.time{i})]);
end

datatmp = data;
% save data
for i = 1:length(data.time)
    data       = [];
    data       = datatmp;
    data.trial = data.trial(i);
    data.time  = data.time(i);
    datapath               = [par.ProcDataDir 'FT_trials/ECGrun' num2str(run(1)) 'trial' num2str(i,'%03i') '.mat'];
    save(datapath,'data','par','MaxLength','MinLength');
end

clear data

%% frequency analysis

Dir = ['/neurospin/meg/meg_tmp/temprod_Baptiste_2010/DATA/NEW/processed_' subject];

load(fullfile(Dir,['/FT_trials/run' num2str(run) 'trial001.mat']))
ntrials = size(data.sampleinfo,1);

% trial-by-trial fourier analysis


for N = 1:ntrials
    
    load(fullfile(Dir,['/FT_trials/ECGrun' num2str(run) 'trial' num2str(N,'%03i') '.mat']))
    clear cfg
    
    cfg.channel            = 'all';
    cfg.method             = 'mtmfft';
    cfg.output             = 'pow';
    cfg.taper              = 'hanning';
    cfg.foi                = freqband(1):0.1:freqband(2);
    cfg.t_ftimwin          = ones(1,length(cfg.foi))*2;
    cfg.tapsmofrq          = 0.5;
    cfg.toi                = ones(1,2*length(cfg.foi))*1;
    cfg.trials             = 'all';
    cfg.keeptrials         = 'yes';
    cfg.pad                = MaxLength/data.fsample;
    freq                   = ft_freqanalysis(cfg,data);
    clear data
    
    % save data
    freqpath               = [Dir '/FT_spectra/ECGfreq_' num2str(freqband(1)) '_'...
        num2str(freqband(2)) 'run' num2str(run) 'trial' num2str(N) '.mat'];
    save(freqpath,'freq','cfg');
    
    clear freq cfg
    
end

%% sort data by ascending order of trial duration

Dir = ['/neurospin/meg/meg_tmp/temprod_Baptiste_2010/DATA/NEW/processed_' subject];

load(fullfile(Dir,['/FT_trials/run' num2str(run) 'trial001.mat']))
ntrials = size(data.sampleinfo,1);

dur(:,1) = data.sampleinfo(:,2) - data.sampleinfo(:,1);
dur(:,2) = (1:length(dur))';

asc_ord = sortrows(dur);

par.ProcDataDir         = ['/neurospin/meg/meg_tmp/temprod_Baptiste_2010/DATA/NEW/processed_' subject '/'];
% concatenate data
Fullspctrm          = [];
Fullfreq            = [];
for x               = 1:ntrials
    chantype        = 'all';
    trialdataset{x}    = ['/FT_spectra/ECGfreq_' num2str(freqband(1)) '_' num2str(freqband(2)) 'run' num2str(run) 'trial' num2str(x) '.mat'];
    freqpath        = [Dir trialdataset{x}];
    load(freqpath)
    Fullspctrm      = cat(1,Fullspctrm,freq.powspctrm(:,:,:));
    Fullfreq        = [Fullfreq freq.freq];
end
Fullspctrm      = Fullspctrm(asc_ord(:,2)',:,:);
disp(['trials concatenated in FullspctrmECG_' num2str(run)])

Fullspctrm_path     = [par.ProcDataDir 'FT_spectra/FullspctrmECG_' num2str(run) '.mat'];
save(Fullspctrm_path,'Fullspctrm','Fullfreq','asc_ord','-v7.3');

% then delete all intermediate files
for x = 1:length(dur)
    delete([Dir trialdataset{x}])
end
disp(['intermediates datasets deleted'])










