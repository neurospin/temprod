function temprod_dataviewer_EEG(index,subject,freqband,K,debiasing,interpnoise,chandisplay,savetag)

DIR = ['/neurospin/meg/meg_tmp/temprod_Baptiste_2010/DATA/NEW/processed_' subject '/'];

Fullspctrm          = [];
Fullfreq            = [];
Fullspctrm_path     = [DIR 'FT_spectra/Fullspctrm_EEG_' num2str(index) '.mat'];
load(Fullspctrm_path);
tmp = unique(Fullfreq); clear Fullfreq;
Fullfreq            = tmp;

%% remove 1/f component
if debiasing == 1
    [Fullfreq,Fullspctrm] = RemoveOneOverF(Fullfreq,Fullspctrm,'mean');
end

%% noise removal and channel-by-channel linear interpolation replacemement
if interpnoise == 1
    [Fullfreq,Fullspctrm] = LineNoiseInterp(Fullfreq,Fullspctrm);
end

% select frequency band
fbegin              = find(Fullfreq >= freqband(1));
fend                = find(Fullfreq <= freqband(2));
fband               = fbegin(1):fend(end);
bandFullspctrm      = Fullspctrm(:,:,fband);
bandFullfreq        = Fullfreq(fband);
clear Fullspctrm Fullfreq
Fullspctrm          = bandFullspctrm;
Fullfreq            = bandFullfreq;

FullfreqSave        = Fullfreq;
FullspctrmSave      = Fullspctrm;


%% smooting by convolution
h =[];
for x               = 1:size(Fullspctrm,2)
    g = [];
    for y           = 1:size(Fullspctrm,3)
        v           = squeeze(Fullspctrm(:,x,y))';
        f           = conv(v,K,'same');
        g(:,y) = f;
        clear f
    end
    h = cat(3,h,g);
end
h = permute(h,[1 3 2]);
Fullspctrm = h;

if chandisplay == 1
    %% plot channel-by-channel data
    fig                 = figure('position',[1 1 1280 1024]);
    for k               = 1:60
        full            = [];
        for i           = 1:size(Fullspctrm,1)
            Pmean       = squeeze((Fullspctrm(i,k,:)));
            full        = [full Pmean];
        end
        mysubplot(6,10,k)
        imagesc((full)')
    end
    
    %% save plot
    if savetag == 1
        print('-dpng',['/neurospin/meg/meg_tmp/temprod_Baptiste_2010/DATA/NEW/Plots_' subject...
            '/Fullspctrm_EEG_' num2str(freqband(1)) '-' num2str(freqband(2)) '_' num2str(index) '.png']);
    end
    
    %% plot-channel-by-channel zscores
    fig                 = figure('position',[1 1 1280 1024]);
    for k               = 1:60
        full            = [];
        for i           = 1:size(Fullspctrm,1)
            Pmean       = squeeze((Fullspctrm(i,k,:)));
            full        = [full Pmean];
        end
        mysubplot(6,10,k)
        imagesc(zscore((full)',0,2));
    end
    %% save plot
    if savetag == 1
        print('-dpng',['/neurospin/meg/meg_tmp/temprod_Baptiste_2010/DATA/NEW/Plots_' subject...
            '/Fullspctrm_zscores_EEG_' num2str(freqband(1)) '-' num2str(freqband(2)) '_' num2str(index) '.png']);
    end
end


%% plot results, zscores, averages across channels
fig                 = figure('position',[1 1 1280*0.5 1024*0.6]);
set(fig,'PaperPosition',[1 1 1280 1024])
set(fig,'PaperPositionMode','auto')
%% psd data
zscoretag = 0;
%% EEG
sub1 = subplot(3,3,1);
if zscoretag == 1
    z = zscore((squeeze(mean(Fullspctrm,2))),0,2);
    imagesc(z);
else
    imagesc((squeeze(mean(Fullspctrm,2))));
end
xlabel('frequency');
ylabel('trials');
title('EEG PSD');
% colorbar;
set(sub1,'XTick',10:16:length(Fullfreq),'XTickLabel',round(Fullfreq(10:16:end)*10)/10);

%% Z-scores data
zscoretag = 1;
%% EEG
sub1 = subplot(3,3,2);
if zscoretag == 1
    z = zscore((squeeze(mean(Fullspctrm,2))),0,2);
    imagesc(z);
else
    imagesc((squeeze(mean(Fullspctrm,2))));
end
xlabel('frequency');
ylabel('trials');
title('EEG PSD zscore');
% colorbar;
set(sub1,'XTick',10:16:length(Fullfreq),'XTickLabel',round(Fullfreq(10:16:end)*10)/10);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for i = 1:size(FullspctrmSave,1)
    MinSide = min(mean(FullspctrmSave(i,:,:)));
    C = cumsum((squeeze(mean(FullspctrmSave(i,:,:))) - ones(size(FullspctrmSave,3),1)*MinSide));
    j = 1;
    while C(j) <= C(end)/2
        Fpeak(i) = j;
        Fpeakpow(i) = mean(FullspctrmSave(i,:,Fpeak(i)));
        j = j+1;
    end
end
MaxPSD     = Fpeakpow;
MaxPSDfreq = Fpeak;

[R,p] = corr([asc_ord(:,1) FullfreqSave(MaxPSDfreq)'],'type','Pearson');
s = subplot(3,3,4);
plot(FullfreqSave(MaxPSDfreq),(asc_ord(:,1))/0.250,'marker','*','linestyle','none')   
axis([min(FullfreqSave) max(FullfreqSave) (min(asc_ord(:,1))/0.250) (max(asc_ord(:,1))/0.250)]);
set(gca,'YDir','reverse')
title(['Corr coeff : ' round(num2str(R(2,1))*1000)/1000 ', pval = ' round(num2str(p(2,1))*1000)/1000])
ylabel('duration (ms)');
xlabel('frequency (hz)');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear Fpeak MaxPSDfreq
numpoints = round(1/((Fullfreq(end) - Fullfreq(1))/length(Fullfreq)));

for i = 1:size(FullspctrmSave,1)
    MinSide = min(mean(FullspctrmSave(i,:,:)));
    C = cumsum((squeeze(mean(FullspctrmSave(i,:,:))) - ones(size(FullspctrmSave,3),1)*MinSide));
    j = 1;
    while C(j) <= C(end)/2
        clear Fpeak
        if (j-numpoints)     <= 0
            infbound         =  1;
        elseif (j-numpoints) >  0
            infbound         =  j - numpoints;
        end
        if (j+numpoints)     >= length(Fullfreq)
            supbound         =  length(Fullfreq);
        elseif (j+numpoints) <  length(Fullfreq)
            supbound         =  j + numpoints;
        end
        Fpeak(i,:)           =  infbound:supbound;
        Fpeakpow(i)          =  mean(squeeze((mean(FullspctrmSave(i,:,Fpeak(i,:))))));
        j                    =  j+1;
    end
end
MaxPSD     = Fpeakpow;
MaxPSDfreq = Fpeak(i,:);

[R,p] = corr([asc_ord(:,1) MaxPSD'],'type','Pearson');
s = subplot(3,3,5);
plot(MaxPSD,(asc_ord(:,1))/0.250,'marker','*','linestyle','none')   
axis([min(MaxPSD) max(MaxPSD) (min(asc_ord(:,1))/0.250) (max(asc_ord(:,1))/0.250)]);
set(gca,'YDir','reverse')
title(['Corr coeff : ' round(num2str(R(2,1))*1000)/1000 ', pval = ' round(num2str(p(2,1))*1000)/1000])
ylabel('duration (ms)');
xlabel('power');



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% plot mean topographies
EEGlabel = EEG_for_layouts;

% select the corresponding power
freq.powspctrm         = FullspctrmSave;
freq.freq              = Fullfreq;
trialnumber            = size(FullspctrmSave,1);
% complete dummy fieldtrip structure
freq.dimord            = 'rpt_chan_freq';
freq.cumtapcnt         = ones(trialnumber,length(freq.freq));
freq.label             = EEGlabel;
clear cfg
cfg.channel           = 'all';
cfg.xparam            = 'freq';
cfg.zparam            = 'powspctrm';
cfg.xlim              = [Fullfreq(1) Fullfreq(end)];
%     cfg.zlim              = [m M];
cfg.baseline          = 'no';
cfg.trials            = 'all';
cfg.colormap          = jet;
cfg.marker            = 'off';
cfg.markersymbol      = 'o';
cfg.markercolor       = [0 0 0];
cfg.markersize        = 2;
cfg.markerfontsize    = 8;
cfg.colorbar          = 'no';
cfg.interplimits      = 'head';
cfg.interpolation     = 'v4';
cfg.style             = 'straight';
cfg.gridscale         = 67;
cfg.shading           = 'flat';
cfg.interactive       = 'yes';
cfg.comment           = ['average power EEG'];
cfg.layout            = '/neurospin/meg/meg_tmp/ResonanceMeg_Baptiste_2009/SCRIPTS/Layouts_fieldtrip/eeg_64_NM20884N.lay';
lay                   = ft_prepare_layout(cfg,freq);
lay.label             = freq.label;
cfg.layout            = lay;

subplot(3,3,3)
ft_topoplotER(cfg,freq)

if savetag == 1
    print('-dpng',['/neurospin/meg/meg_tmp/temprod_Baptiste_2010/DATA/NEW/Plots_' subject...
        '/FullspctrmSaveEEG_overview_' num2str(freqband(1)) '-' num2str(freqband(2)) '_' num2str(index) '.png']);
end



