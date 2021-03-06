function appendspectra_v2(index,subject,zscoretag)

par.ProcDataDir         = ['/neurospin/meg_tmp/temprod_Baptiste_2010/DATA/NEW/processed_' subject '/'];

load([par.ProcDataDir 'run' num2str(index) '.mat']);
for i = 1:size(data.time,2)
    trialduration(1,i) = length(data.time{i});
    trialduration(2,i) = i;
end
asc_ord = sortrows(trialduration');
chantypefull            = {'Mags';'Gradslong';'Gradslat'};

for j = 1:3
    Fullspctrm          = [];
    Fullfreq            = [];
    for x               = 1:length(freqbandfull)
        freqband        = freqbandfull{x};
        chantype        = chantypefull{j};
        freqpath        = [par.ProcDataDir chantype 'freq_' num2str(freqband(1)) '_' num2str(freqband(2)) '_' num2str(index) '.mat'];
        load(freqpath)
        Fullspctrm      = cat(3,Fullspctrm,freq.powspctrm(:,:,:));
        Fullfreq        = [Fullfreq freq.freq];
    end
    Fullspctrm      = Fullspctrm(asc_ord(:,2)',:,:);
    Fullspctrm_path     = [par.ProcDataDir 'Fullspctrm_' chantype num2str(index) '.mat'];
    save(Fullspctrm_path,'Fullspctrm','Fullfreq','-v7.3');
    
    fig                 = figure('position',[1 1 1280 1024]);
    for i = 1:size(Fullspctrm,1)
        mysubplot(10,8,i)
        Pmean           = squeeze(mean(Fullspctrm(i,:,:),2));
        plot(Fullfreq,Pmean);
    end
    
    eval(['Fullspctrm' chantype '= Fullspctrm;']);

    if zscoretag == 1
        print('-dpng',['/neurospin/meg_tmp/temprod_Baptiste_2010/DATA/NEW/Plots_' subject...
            '/Fullspctrm_zscores' chantype '_' num2str(index) '.png']);
    else
        print('-dpng',['/neurospin/meg_tmp/temprod_Baptiste_2010/DATA/NEW/Plots_' subject...
            '/Fullspctrm_' chantype '_' num2str(index) '.png']);
    end
    
    fig                 = figure('position',[1 1 1280 1024]);
    for k = 1:102
        full = [];
        for i = 1:size(Fullspctrm,1)
            Pmean           = squeeze((Fullspctrm(i,k,:)));
            full = [full Pmean];
        end
        mysubplot(11,10,k)
        if zscoretag == 1
            imagesc(zscore(log(full)',0,2));
        else
            imagesc(log(full)')
        end
    end
    clear Fullspctrm
    if zscoretag == 1
        print('-dpng',['/neurospin/meg_tmp/temprod_Baptiste_2010/DATA/NEW/Plots_' subject...
            '/Fullspctrm_zscores_chan_by_chan' chantype '_' num2str(index) '.png']);
    else
        print('-dpng',['/neurospin/meg_tmp/temprod_Baptiste_2010/DATA/NEW/Plots_' subject...
            '/Fullspctrm_chan_by_chan' chantype '_' num2str(index) '.png']);
    end
    
end

%% Get visuals for the result
fig                 = figure('position',[1 1 1280 1024]);
sub1 = subplot(1,3,1);
if zscoretag == 1
    z = zscore((squeeze(mean(FullspctrmMags,2))),0,2);
    imagesc(z,[1 2]);
else
    imagesc((squeeze(mean(FullspctrmMags,2))));
end
xlabel('frequency');
ylabel('trials');
title('log power');
colorbar;
set(sub1,'XTick',11:50:length(Fullfreq),'XTickLabel',Fullfreq(11:50:end));
sub2 = subplot(1,3,2);
if zscoretag == 1
    z = zscore((squeeze(mean(FullspctrmGradslong,2))),0,2);
    imagesc(z,[1 2]);
else
    imagesc((squeeze(mean(FullspctrmGradslong,2))));
end
xlabel('frequency');
ylabel('trials');
title('log power');
colorbar;
set(sub2,'XTick',11:50:length(Fullfreq),'XTickLabel',Fullfreq(11:50:end));
sub3 = subplot(1,3,3);
if zscoretag == 1
    z = zscore((squeeze(mean(FullspctrmGradslat,2))),0,2);
    imagesc(z,[1 2]);
else
    imagesc((squeeze(mean(FullspctrmGradslat,2))));
end
xlabel('frequency');
ylabel('trials');
title('log power');
colorbar
set(sub3,'XTick',11:50:length(Fullfreq),'XTickLabel',Fullfreq(11:50:end));

if zscoretag == 1
    print('-dpng',['/neurospin/meg_tmp/temprod_Baptiste_2010/DATA/NEW/Plots_' subject...
        '/Fullspctrm_zscores_image_' num2str(index) '.png']);
else
    print('-dpng',['/neurospin/meg_tmp/temprod_Baptiste_2010/DATA/NEW/Plots_' subject...
        '/Fullspctrm_image_' num2str(index) '.png']);
end



