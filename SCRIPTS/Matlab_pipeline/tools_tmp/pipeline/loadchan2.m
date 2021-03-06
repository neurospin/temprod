function [EEG,MEGm,MEGg,MEG,ALL] = loadchan2(infodata)
% load the list of the channel to extract EEG, gradio or magneto
% specifically for topoplot for EEG by SOA
EEG = [];
MEGm = [];
MEGg = [];
MEG = [];
ALL = [];

for i=1:length(infodata(1).ch_names)
    chan = [infodata(1).ch_names{i}];
    if strncmp(chan,'EEG',3) | strncmp(chan,'MEG',3)
        ALL = [ALL i];
    end
    if strncmp(chan,'EEG',3)
        EEG = [EEG i];
    elseif strncmp(chan,'MEG',3) 
        MEG = [MEG i];
    end
    if strncmp(chan,'MEG',3) && strcmp(chan(length(chan)),'1')
        MEGm = [MEGm i];
    elseif strncmp(chan,'MEG',3) && ~strcmp(chan(length(chan)),'1')
        MEGg = [MEGg i];
    end
end