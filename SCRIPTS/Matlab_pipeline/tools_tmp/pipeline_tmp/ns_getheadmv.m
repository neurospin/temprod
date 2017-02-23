function ns_getheadmv(par)

%% Check Head Movement between runs
% Generate a shell script that extracts the head position for each run and
% saves it in a txt file
script_name=[par.hpdir 'script_hp_' par.subj];  % define the shell script name (with complete path)
fd2         = fopen(script_name, 'w+');         % open the shell script
fprintf(fd2, '#!/bin/tcsh\n');
for r=par.run
    fiffile=[par.rawdir par.subj par.runlabel{r}];                          % name of fif file from which head position should be extracted
    disp(['Retrieving head position from dataset ' fiffile]);
    outfile=[par.hpdir 'hp_' par.subj par.runlabel{r}];                     % name of txt file where to save the result
    fprintf(fd2, ['show_fiff -vt 222 ' fiffile '.fif > ' outfile '.txt\n']);    % print the command for extracting the head position in the shell script
end;
fclose(fd2);
cmd = ['chmod 777 ' script_name];       % remove all protections from the shell script (to execute it!)
system(cmd);
cmd = [script_name];                    % run the shell script
[status, result] = system(cmd)
% if status==0
%     error('Error while retrieving one or more head positions. Please check file names and head position data within .fif files.');
% else
%     disp(['status = ' num2str(status)]);
%     disp(['result = ' result]);
% end;
