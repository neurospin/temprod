%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function temprod_NEW_freqanalysis_chunked_data(isdetrend,index,subject,part)

for a = 1:8
    eval(['datapath' num2str(a) '= [''/neurospin/meg_tmp/temprod_Baptiste_2010/DATA/NEW/processed_'...
        subject '/run' num2str(a) '_' part '.mat'']']);
end

chantypefull  = {'Mags';'Gradslong';'Gradslat'};
% par.ProcDataDir        = ['/neurospin/meg_tmp/temprod_Baptiste_2010/DATA/NEW/processed_' subject '/'];
eval(['load(datapath' num2str(index) ');']);
par.ProcDataDir        = ['/neurospin/meg_tmp/temprod_Baptiste_2010/DATA/NEW/processed_' subject '/'];

eval(['data = data_' part]);
clear data_part1 data_part2 data_part3

range = 1:0.5:46;
for a = 1:length(range)
    freqbandfull{a} = [(range(a)+3) (range(a)+3.5)];
end

for x = 1:length(freqbandfull)
    for j = 1:3
        freqband = freqbandfull{x};
        chantype = chantypefull{j};
        
        %% trial-by-trial fourier analysis %%
        [GradsLong, GradsLat]  = grads_for_layouts;
        if strcmp(chantype,'Mags')     == 1
            channeltype        =  {'MEG*1'};
        elseif strcmp(chantype,'Gradslong') == 1;
            channeltype        =  GradsLong;
        elseif strcmp(chantype,'Gradslat')
            channeltype        =  GradsLat;
        end
        clear cfg
        cfg.channel            = channeltype;
        cfg.method             = 'mtmwelch';
        cfg.output             = 'pow';
        cfg.taper              = 'hanning';
        cfg.foi                = freqband(1):0.1:freqband(2);
        cfg.t_ftimwin          = ones(1,length(cfg.foi))*1;
%         cfg.tapsmofrq          = ones(1,length(cfg.foi))*1;
        cfg.toi                = ones(1,2*length(cfg.foi))*0.5;
        cfg.trials             = 'all';
%         cfg.trials             = 1:80;
        cfg.keeptrials         = 'yes';
        cfg.keeptapers         = 'no';
        cfg.pad                = 'maxperlen';
        freq                   = ft_freqanalysis(cfg,data);
        %% linear detrending %%
        if isdetrend == 1
            for i              = 1:size(freq.powspctrm,1)
                freq.powspctrm(i,:,:) = ft_preproc_detrend(squeeze(freq.powspctrm(i,:,:)));
            end
        end
        %% plot trial by trial fourrier spectra %%
        % for i = 1:size(freq.powspctrm,1)
        %     mysubplot(8,8,i)
        %     plot(mean(squeeze(freq.powspctrm(i,1:306,:))));
        % end
        %% find peak power and corresponding frequency %%
        Sample                 = [];
        for i                  = 1:length(data.time)
            Sample             = [Sample ; length(data.time{i})];
        end
        Freq                   = freq.freq;
        Fsample                = data.fsample;
        dur                    = Sample/Fsample;
        % fig = figure('position',[1 1 1280 1024]);
        for k                  = 1:length(Sample)
            hold on
            mysubplot(10,10,k)
            pmax(k)            = max(mean(squeeze(freq.powspctrm(k,:,:))));
            pmin(k)            = min(mean(squeeze(freq.powspctrm(k,:,:))));
            Pmean              = mean(squeeze(freq.powspctrm(k,:,:)));
            plot(freq.freq,Pmean);
%             Peak(k)            = find(Pmean == pmax(k));
        end
%         FPeak                  = Freq(Peak);
        %% save data %%
        freqpath               = [par.ProcDataDir chantype 'freq_' num2str(freqband(1)) '_'...
        num2str(freqband(2)) '_' num2str(index) '_' part '.mat'];
        save(freqpath,'freq','cfg','-v7.3');
        
        clear freq
        
        % print('-dpng',['/neurospin/meg_tmp/temprod_Baptiste_2010/DATA/OLD/Plots_' subject...
        %     '/trialbytrial_spectra_' chantype '-' num2str(freqband(1)) '-' num2str(freqband(2)) '_'...
        %     num2str(index) 'hz.png']);
        
    end
end
