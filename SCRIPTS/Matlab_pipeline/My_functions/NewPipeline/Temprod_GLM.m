function Temprod_GLM( SubjectArray, RunArray, chantype, freqband, condname, tag)

% set root path
root = SetPath(tag);

%% BUILD VARIABLES
% init loop variables
DUR         = []; % regressor of interest
ACC         = []; % regressor of interest
MED         = []; % regressor of interest
yp          = []; % power data
yf          = []; % frequency data
ys          = []; % slope data
SUBID       = []; % subject regressor
RUNID       = []; % run regressor
sumrun      = 0;  % cumulative sum of runs
OFFSETPOW   = []; % offset vector for power data
OFFSETFREQ  = []; % offset vector for frequency data
OFFSETSLOPE = []; % offset vector for slope data
lgd         = ['''duration'','];  % legend for futher plotting

% loop for all subjects
for i     = 1:length(SubjectArray) % loop for all subjects  
    
    % init loop variables
    ypoff    = [];
    yfoff    = [];
    ysoff    = [];
    lgd      = [lgd '''SUB' num2str(i) ''','];
    % loop for all runs
    for j = 1:length(RunArray{i,1})
        
        MEDIANDEVIATION = [];
        sumrun = sumrun +1;
        
        % load data
        ProcDataDir = [root '/DATA/NEW/processed_' char(SubjectArray{i,1}) '/'];
        loadpath = [ProcDataDir 'FT_spectra/POW+FREQ_' chantype '_RUN' num2str(RunArray{i,1}(j),'%02i') ...
            '_' num2str(freqband(1)) '_' num2str(freqband(2)) 'Hz.mat'];
        load(loadpath)
        
        % TEMPORARY : median deviation (todo at previous analysis level (dataviewer))
        m                         = median(DURATIONSORTED(:,1));
        for ind = 1:size(DURATIONSORTED,1)
            MEDIANDEVIATION(ind,1:2)  = DURATIONSORTED(ind,1:2) - [m 0];
        end
        MEDIANDEVIATION(:,1) = abs(MEDIANDEVIATION(:,1));
        
        % build regressor for each subject
        tmp   = zeros(size(DURATIONSORTED,1),length(SubjectArray));
        tmp(:,i) = ones(size(DURATIONSORTED,1),1);
        SUBID = [SUBID ; tmp];
        
        % build regressor for each run
        tmp2 = zeros(size(DURATIONSORTED,1),(length(SubjectArray))*(length(RunArray)));
        tmp2(:,sumrun) = ones(size(DURATIONSORTED,1),1);
        RUNID = [RUNID ; tmp2];
        
        % regressor variable: 1/duration
        DURtmp = []; DURtmp = sortrows(flipdim(DURATIONSORTED,2));
        DUR  = [DUR ; 1./DURtmp(:,2)];
        % regressor variable: accuracy
        ACCtmp = []; ACCtmp = sortrows(flipdim(ACCURACY,2));
        ACC  = [ACC ; ACCtmp(:,2)];
        % regressor variable: median deviation
        MEDtmp = []; MEDtmp = sortrows(flipdim(MEDIANDEVIATION,2));
        MED  = [MED ; MEDtmp(:,2)]; 
        
        % compute average power across channels for each trial
        pow = [];
        for k = 1:length(POWER)
            pow = [pow ; POWER{k}];
        end
        yp    = [yp (nanmean(pow))]; 
        ypoff = [ypoff (nanmean(pow))]; 
        
        % compute average frequency across channels for each trial
        freq = [];
        for k = 1:length(FREQUENCY)
            freq = [freq ; FREQUENCY{k}];
        end
        yf    = [yf (nanmean(freq))];   
        yfoff = [yfoff (nanmean(freq))];  
        
        % compute average slope across channels for each trial
        slope = [];
        for k = 1:length(SLOPE)
            slope = [slope ; SLOPE{k}];
        end
        ys    = [ys (nanmean(slope))];   
        ysoff = [ysoff (nanmean(slope))]; 
        
    end
    % compute power data offset
    OFFSETPOW   = [OFFSETPOW ; ones(size(ypoff,2),1)*nanmean(ypoff)];
    
    % compute frequency data offset
    OFFSETFREQ  = [OFFSETFREQ ; ones(size(yfoff,2),1)*nanmean(yfoff)];
    
    % compute slope data offset
    OFFSETSLOPE = [OFFSETSLOPE ; ones(size(ysoff,2),1)*nanmean(ysoff)];    
    
end
% lgd = [lgd '''location'',''SouthEastOutside'''];
lgd(end) = [];

%% COMPUTE GLMs
% on frequency data
[BfreqvsDUR,DEVfreqvsDUR,STATSfreqvsDUR] = glmfit([DUR ],yf,'normal','link','identity','offset',OFFSETFREQ,'constant','off');
YHATfreqvsDUR                            = glmval(BfreqvsDUR,[DUR ],'identity','offset',OFFSETFREQ,'constant','off');

[BfreqvsACC,DEVfreqvsACC,STATSfreqvsACC] = glmfit([ACC ],yf,'normal','link','identity','offset',OFFSETFREQ,'constant','off');
YHATfreqvsACC                            = glmval(BfreqvsACC,[ACC ],'identity','offset',OFFSETFREQ,'constant','off');

[BfreqvsMED,DEVfreqvsMED,STATSfreqvsMED] = glmfit([MED ],yf,'normal','link','identity','offset',OFFSETFREQ,'constant','off');
YHATfreqvsMED                            = glmval(BfreqvsMED,[MED ],'identity','offset',OFFSETFREQ,'constant','off');

% on power data
[BpowvsDUR,DEVpowvsDUR,STATSpowvsDUR]    = glmfit([DUR ],yp,'normal','link','identity','offset',OFFSETPOW,'constant','off');
YHATpowvsDUR                             = glmval(BpowvsDUR,[DUR],'identity','offset',OFFSETPOW,'constant','off');

[BpowvsACC,DEVpowvsACC,STATSpowvsACC]    = glmfit([ACC ],yp,'normal','link','identity','offset',OFFSETPOW,'constant','off');
YHATpowvsACC                             = glmval(BpowvsACC,[ACC ],'identity','offset',OFFSETPOW,'constant','off');

[BpowvsMED,DEVpowvsMED,STATSpowvsMED]    = glmfit([MED ],yp,'normal','link','identity','offset',OFFSETPOW,'constant','off');
YHATpowvsMED                             = glmval(BpowvsMED,[MED ],'identity','offset',OFFSETPOW,'constant','off');

% one slope data
[BslopevsDUR,DEVslopevsDUR,STATSslopevsDUR]    = glmfit([DUR ],ys,'normal','link','identity','offset',OFFSETSLOPE,'constant','off');
YHATslopevsDUR                                 = glmval(BslopevsDUR,[DUR ],'identity','offset',OFFSETSLOPE,'constant','off');

[BslopevsACC,DEVslopevsACC,STATSslopevsACC]    = glmfit([ACC ],ys,'normal','link','identity','offset',OFFSETSLOPE,'constant','off');
YHATslopevsACC                                 = glmval(BslopevsACC,[ACC ],'identity','offset',OFFSETSLOPE,'constant','off');

[BslopevsMED,DEVslopevsMED,STATSslopevsMED]    = glmfit([MED ],ys,'normal','link','identity','offset',OFFSETSLOPE,'constant','off');
YHATslopevsMED                                 = glmval(BslopevsMED,[MED ],'identity','offset',OFFSETSLOPE,'constant','off');

%% PLOT RESULTS
% set figure parameters
scrsz = get(0,'ScreenSize');
fig                 = figure('position',scrsz);
set(fig,'PaperPosition',scrsz)
set(fig,'PaperPositionMode','auto')
set(fig,'visible','on')

% plot predicted and observed data
s3 = subplot(3,9,1:6);
plot(yf,'color','b'); xlabel('trials');ylabel('frequency (Hz)')
hold on; plot(YHATfreqvsDUR ,'linewidth',2,'color','r');
hold on; plot(YHATfreqvsACC ,'linewidth',2,'color','g');
hold on; plot(YHATfreqvsMED ,'linewidth',2,'color','k');
legend('observed','predicted(1/DUR)','predicted(ACC)','predicted(MED)');
title([num2str(freqband(1)) '-' num2str(freqband(2))  'Hz :frequency peaks'])

s2 = subplot(3,9,10:15);
plot(yp,'color','b'); xlabel('trials');ylabel('power')
hold on; plot(YHATpowvsDUR ,'linewidth',2,'color','r');
hold on; plot(YHATpowvsACC ,'linewidth',2,'color','g');
hold on; plot(YHATpowvsMED ,'linewidth',2,'color','k');
legend('observed','predicted(1/DUR)','predicted(ACC)','predicted(MED)');
title([num2str(freqband(1)) '-' num2str(freqband(2))  'Hz :frequency peaks power'])

s3 = subplot(3,9,19:24);
plot(ys,'color','b'); xlabel('trials');ylabel('slope coeff')
hold on; plot(YHATslopevsDUR ,'linewidth',2,'color','r');
hold on; plot(YHATslopevsACC ,'linewidth',2,'color','g');
hold on; plot(YHATslopevsMED ,'linewidth',2,'color','k');
legend('observed','predicted(1/DUR)','predicted(ACC)','predicted(MED)');
title([num2str(freqband(1)) '-' num2str(freqband(2))  'Hz :slope values'])

% plot general fit values: freq
s4 = subplot(3,9,7);
bar([BfreqvsDUR(2) BfreqvsACC(2) BfreqvsMED(2)]); title('beta');
set(s4,'Xtick',1:3,'Xticklabel',{'1/DUR';'ACC';'MED'})

s5 = subplot(3,9,8);
bar(-log([STATSfreqvsDUR.p(2) STATSfreqvsACC.p(2) STATSfreqvsMED.p(2)]))
hold on; line([0 4],[-log(0.001) -log(0.001)]); text(4.2,-log(0.001),'0.001'); 
hold on; line([0 4],[-log(0.05) -log(0.05)]); text(4.2,-log(0.05),'0.05'); 
title('p-values');
set(s5,'Xtick',1:3,'Xticklabel',{'1/DUR';'ACC';'MED'})

s6 = subplot(3,9,9);
bar([DEVfreqvsDUR DEVfreqvsACC DEVfreqvsMED]); title('deviance score');
set(s6,'Xtick',1:3,'Xticklabel',{'1/DUR';'ACC';'MED'})

% plot general fit values: pow
s7 = subplot(3,9,16);
bar([BpowvsDUR(2) BpowvsACC(2) BpowvsMED(2)]); title('beta');
set(s7,'Xtick',1:3,'Xticklabel',{'1/DUR';'ACC';'MED'})

s8 = subplot(3,9,17);
bar(-log([STATSpowvsDUR.p(2) STATSpowvsACC.p(2) STATSpowvsMED.p(2)]))
hold on; line([0 4],[-log(0.001) -log(0.001)]); text(4.2,-log(0.001),'0.001'); 
hold on; line([0 4],[-log(0.05) -log(0.05)]); text(4.2,-log(0.05),'0.05'); 
title('p-values');
set(s8,'Xtick',1:3,'Xticklabel',{'1/DUR';'ACC';'MED'})

s9 = subplot(3,9,18);
bar([DEVpowvsDUR DEVpowvsACC DEVpowvsMED]); title('deviance score');
set(s9,'Xtick',1:3,'Xticklabel',{'1/DUR';'ACC';'MED'})

% plot general fit values: slope
s10 = subplot(3,9,25);
bar([BslopevsDUR(2) BslopevsACC(2) BslopevsMED(2)]); title('beta');
set(s10,'Xtick',1:3,'Xticklabel',{'1/DUR';'ACC';'MED'})

s11 = subplot(3,9,26);
bar(-log([STATSslopevsDUR.p(2) STATSslopevsACC.p(2) STATSslopevsMED.p(2)]))
hold on; line([0 4],[-log(0.001) -log(0.001)]); text(4.2,-log(0.001),'0.001'); 
hold on; line([0 4],[-log(0.05) -log(0.05)]); text(4.2,-log(0.05),'0.05'); 
title('p-values');
set(s11,'Xtick',1:3,'Xticklabel',{'1/DUR';'ACC';'MED'})

s12 = subplot(3,9,27);
bar([DEVslopevsDUR DEVslopevsACC DEVslopevsMED]); title('deviance score');
set(s12,'Xtick',1:3,'Xticklabel',{'1/DUR';'ACC';'MED'})

% save print
print('-dpng',[root '/DATA/NEW/across_subjects_plots/GLM_FREQ+POW+SLOPE_'...
    chantype '_' num2str(freqband(1)) '-' num2str(freqband(2)) '_' condname 'Hz.png']);

