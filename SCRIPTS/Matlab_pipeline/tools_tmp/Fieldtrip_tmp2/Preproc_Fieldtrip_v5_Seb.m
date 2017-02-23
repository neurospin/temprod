addpath '/neurospin/local/mne/matlab/toolbox'
addpath '/volatile/ProcessingScripts'

%%%%%%%%%%%%%%%%%% Recoding triggers: %%%%%%%%%%%%%%%%%%%%%
% example: 1012: 10=Lag1 correct T1; 12=correct T2
%          1113: 11=Lag1 incorrect T1; 13=incorrect T2
%          2024: 20=Lag2 correct T1; 24=Blinked T2
%          100: No T2, correct T1
%          101: No T2 incorrect T1

% note: Subject 16 responses have been badly coded and thus, it is
% processed separately because of recoding triggers.

%% Subject informations                                                                                             %% INPUT HERE
% Names 
MEGcode         = 'lc090201';                                       % Subject acquisition code
Sub_Num         = 'S25';                                            % Eprime code
RawDir          = '/media/UNTITLED/MEGdata/lc_090201/090721/';      % Raw data path
DirHead         = '/volatile/MEGdata/MATLAB_CheckHeadPosition/';    % Head position text file directory
DataDir         = '/volatile/MEGdata/';                             % SSS Data directory
run             = 1:4;                                              % Number of runs
PreStim         = 0.5;                                              % Prestimulus time window in seconds
PostStim        = 2;                                                % Poststimulus time window
EventValue      = 4044;                                             % Trigger code to be analyzed
BadChan         = '(0531 1211 0532 0533)';

%% Load the sensor classification file
load SensorClassification.mat

%% Create Processing Report file
DirReport       = '/volatile/MEGdata/ProcessingReport/';
ReportName      = 'ProcessingReport';
fd              = fopen([DirReport ReportName], 'a');
fprintf(fd, '\n');
fprintf(fd, '\n');
fprintf(fd, '\n');
fprintf(fd, ['Date:\t' date '\n']);

% Write Eprime and MEG codes in the Processing report text file
fprintf(fd, ['EPrime Code:\t' Sub_Num '\n']);
fprintf(fd, ['MEG Code:\t' MEGcode '\n']);

%% Check Head Movement between runs
% Generate an SH script which will get head position for each run and put
% it in a txt file
DirSH       = '/volatile/ProcessingScripts/scriptSH/';
SHname      = ['HeadMov' Sub_Num];
fd2              = fopen([DirSH SHname], 'w+');
fprintf(fd2, '#!/bin/tcsh\n');
fprintf(fd2, ['set raw_dir = ' RawDir '\n']);
fprintf(fd2, ['set Subject = ' Sub_Num '\n']);
fprintf(fd2, 'cd $raw_dir\n');
fprintf(fd2, 'foreach i(1 2 3 4)\n');
fprintf(fd2, 'ls *run$i"_raw.fif"\n');
fprintf(fd2, 'show_fiff -vt 222 *run$i"_raw.fif" > /volatile/MEGdata/MATLAB_CheckHeadPosition/Pos_$Subject"_run"$i.txt\n');
fprintf(fd2, 'end\n');
fprintf(fd2, 'ls *noT1_raw.fif\n');
fprintf(fd2, 'show_fiff -vt 222 *noT1_raw.fif > /volatile/MEGdata/MATLAB_CheckHeadPosition/Pos_$Subject"_noT1.txt"\n');
fclose(fd2);
cmd = ['chmod 777 ' DirSH SHname];
system(cmd);
cmd = [DirSH SHname];
[status, result] = system(cmd);

% Use the head position txt files and display rotations and translations
% across runs
cfg         = [];
cfg.Sub_Num = Sub_Num;
cfg.run     = run;
cfg.fd      = fd;
cfg.dirhead = DirHead;
data=CheckHeadMovement_seb(cfg);

% Based on the rotation and translation graph, you should choose a run used as the ref
% for head movement
RunRef = 2;                                                                                                     %% INPUT HERE
fprintf(fd, ['Run choosen as the reference for head position:\t' num2str(RunRef) '\n']);

%% Maxfilter
% Use the result of CheckHeadMovement script to determine head position for
% transformation
DirMaxFil       = '/volatile/ProcessingScripts/scriptSH/';
NameMaxFil      = ['Maxfilter' Sub_Num];
fd2              = fopen([DirMaxFil NameMaxFil], 'w+');
fprintf(fd2, '#!/bin/tcsh\n');
fprintf(fd2, ['set raw_dir = ' RawDir '\n']);
fprintf(fd2, ['set Subject = ' Sub_Num '\n']);
fprintf(fd2, ['set Bad = ' BadChan '\n']);
fprintf(fd2, 'cd $raw_dir\n');
fprintf(fd2, 'foreach i(1 2 3 4)\n');
fprintf(fd2, 'ls *run$i"_raw.fif"\n');
fprintf(fd2, ['maxfilter-2.1 -force -f *run$i"_raw.fif" -o $Subject"run"$i"_sss".fif -frame head -origin 0 0 40 -bad $Bad -autobad on -badlimit 7 -trans *run' num2str(RunRef) '_raw.fif\n']);
fprintf(fd2, 'end\n');
fprintf(fd2, 'ls *noT1_raw.fif\n');
fprintf(fd2, ['maxfilter-2.1 -force -f *noT1_raw.fif -o $Subject"noT1_sss.fif" -frame head -origin 0 0 40 -bad $Bad -autobad on -badlimit 7 -trans *run' num2str(RunRef) '_raw.fif\n']);
fclose(fd2);
cmd = ['chmod 777 ' DirMaxFil NameMaxFil];
system(cmd);
cmd = [DirMaxFil NameMaxFil];
[status, result] = system(cmd)
fclose(fd);

%% DEFINE TRIAL and automatic artifact rejection    % THE FOLLOWING PARTS
%% SHOULD BE REPEATED FOR EACH CONDITION
fd          = fopen([DirReport ReportName], 'a');
savename    = [DataDir Sub_Num '_' num2str(EventValue) '.mat']; % Filename to save
    fprintf(fd, ['Condition:\t' num2str(EventValue) '\n']);
    fprintf(fd, ['Saved file:\t' savename '\n']);
Subject         = [];
events          = [];
j=1;
for i=run
    dataset        = [DataDir Sub_Num 'run' num2str(i) '_sss.fif'];
    events{i}      = TriggerCheck_seb(dataset);        % Check the proportion of trials by condition
    events{i}      = RecodTriggers_fieldtrip(events{i});  % Recode the triggers according to performance
    TriggerChannel = events{i};  
    events{i}      = [find(events{i}>0); events{i}(events{i}>0)];
    disp('--------------------------------------------------------------');
    disp(['---------------- Processing ' dataset ' ----------------------']);
    if isempty(find(TriggerChannel==EventValue)) == 0;
        Subject.CfgTrlRun(j) = DefineTrial_Seb(dataset,TriggerChannel,EventValue,PreStim,PostStim);
%         Subject.CfgArtRun(j) = ArtifactReject_Seb(Subject.CfgTrlRun(j)); % muscle and jump artifact rejection
        Subject.Step1Run(j) = preprocessing(Subject.CfgTrlRun(i));
        j=j+1;
    else
        j=j;
    end
end
close all

%% Concatanate all runs into a single dataset
cfg = [];
if length(Subject.Step1Run) == 4
    Subject = appenddata(cfg, Subject.Step1Run(1),Subject.Step1Run(2),Subject.Step1Run(3),Subject.Step1Run(4));
elseif length(Subject.Step1Run) == 3
    Subject = appenddata(cfg, Subject.Step1Run(1),Subject.Step1Run(2),Subject.Step1Run(3));
elseif length(Subject.Step1Run) == 2
    Subject = appenddata(cfg, Subject.Step1Run(1),Subject.Step1Run(2));
elseif length(Subject.Step1Run) == 1
    Subject = appenddata(cfg, Subject.Step1Run(1));
end

Subject.events = events;
clear events
Subject.ECGEOG=Subject.trial;
for tmp=1:length(Subject.ECGEOG)
    Subject.ECGEOG{tmp}=Subject.ECGEOG{tmp}(323:326,:);
end

%% Baseline correction
j=1;
for j=1:length(Subject.trial)
    Subject.trial{j} = preproc_baselinecorrect(Subject.trial{j}, 1, 200);
end

%% Manual artifact rejection
cfg                 =[];
cfg.channel         = All2;
cfg.method          = 'summary';
cfg.megscale        = 10;
Subject             = rejectvisual_seb(cfg, Subject);

% Rejected trials:
rejected=[17,38,39];                                                                 %% INPUT HERE
rejected=sort(rejected);
for tmp=1:length(rejected)
    Subject.ECGEOG(rejected(tmp))=[];
    rejected=rejected-1;
end
fprintf(fd, ['Trials visually rejected: ' num2str(rejected) '\n']);


%% ICA decomposition
% perform the independent component analysis, i.e. decompose the downsampled original data
% this results in a mixing matrix and in the component timecourses
% Don't forget to perform ICA separately for Grad1 Grad2 and Mag
comp = [];
cfg               = [];
cfg.method        ='runica';
cfg.numcomponent  = 10;
channel           = [];
channel{1}        = Grad2_1;
channel{2}        = Grad2_2';
channel{3}        = Mag2;
tmp=1;
tmp2=1;

for j=1:length(channel)
    cfg.channel     = channel{j};
    comp{j}         = componentanalysis(cfg, Subject);
    comp{j}.typechan= channel{j};

comp{j}.meanCorr=zeros(3,10);
for tmp2=1:10
for tmp=1:length(Subject.trial) % trials        
    x=corrcoef(comp{j}.trial{tmp}(tmp2,:), Subject.ECGEOG{tmp}(1,:));
    CorrEOG1(tmp)=x(1,2);
    meanCorrEOG1_comp=mean(CorrEOG1);
        
    y=corrcoef(comp{j}.trial{tmp}(tmp2,:), Subject.ECGEOG{tmp}(2,:));
    CorrEOG2(tmp)=y(1,2);
    meanCorrEOG2_comp=mean(CorrEOG2);
    
    z=corrcoef(comp{j}.trial{tmp}(tmp2,:), Subject.ECGEOG{tmp}(3,:));
    CorrECG(tmp)=z(1,2);
    meanCorrECG_comp=mean(CorrECG);
end
comp{j}.meanCorr(1,tmp2)=meanCorrEOG1_comp;
comp{j}.meanCorr(2,tmp2)=meanCorrEOG2_comp;
comp{j}.meanCorr(3,tmp2)=meanCorrECG_comp;
end
end

% Plot the correlation between EOG1, EOG2, ECG and the components
figure
subplot(3,1,1)
bar(comp{1}.meanCorr', 'group')
title('Grad 1: Correlation between EOG1, EOG2, ECG and the components');
ylim([-1 1]);
subplot(3,1,2)
bar(comp{2}.meanCorr', 'group')
title('Grad 2: Correlation between EOG1, EOG2, ECG and the components');
ylim([-1 1]);
subplot(3,1,3)
bar(comp{3}.meanCorr', 'group')
title('Mag: Correlation between EOG1, EOG2, ECG and the components');
ylim([-1 1]);

% Browse components
cfg=[];
cfg.layout='NM306mag.lay';
comp{1}.topolabel=Mag;
Browser=componentbrowser(cfg,comp{1});
comp{1}.topolabel=Grad2_1;

cfg=[];
cfg.layout='NM306mag.lay';
comp{2}.topolabel=Mag;
Browser=componentbrowser(cfg,comp{2});
comp{2}.topolabel=Grad2_2;

cfg=[];
cfg.layout='NM306mag.lay';
comp{3}.topolabel=Mag;
Browser=componentbrowser(cfg,comp{3});
comp{3}.topolabel=Mag2;

%% the original data can be reconstructed, excluding those components
% data_beforeICA=Subject;
cfg = [];
cfg.component = [3];                                                                                % INPUT HERE
Subject_grad1 = rejectcomponent(cfg, comp{1}); % Grad1
cfg.component = [1];                                                                                 % INPUT HERE
Subject_grad2 = rejectcomponent(cfg, comp{2}); % Grad2
cfg.component = [1,5];                                                                                % INPUT HERE
Subject_mag = rejectcomponent(cfg, comp{3}); % Mag
fprintf(fd, ['Number of ICA components rejected ' num2str(length(cfg.component)) '\n']);

% Combine the structures in a single structure, respecting the order of the
% sensors prior to decomposition.
j=1;
Subject.trial=[];
Subject.label=[];
for j=1:length(Subject_grad1.trial)
    k=1;
    m=1;
    for k=1:102
        Subject.trial{j}(m,:)=Subject_grad1.trial{j}(k,:);
        m=m+1;
        Subject.trial{j}(m,:)=Subject_grad2.trial{j}(k,:);
        m=m+1;
        Subject.trial{j}(m,:)=Subject_mag.trial{j}(k,:);
        m=m+1;
    end
end

k=1;
m=1;
for k=1:102
    Subject.label{m}=Subject_grad1.label{k};
    m=m+1;
    Subject.label{m}=Subject_grad2.label{k};
    m=m+1;
    Subject.label{m}=Subject_mag.label{k};
    m=m+1;
end
Subject.label=Subject.label';

%% Average across trials for each run
cfg             = [];
Subject.Avg     = timelockanalysis(cfg, Subject);
save(savename, 'Subject')   % Save the structure in MAT file
disp(['Processing Subject ' Sub_Num ', Condition ' num2str(EventValue) ': Done.']);
fclose(fd);