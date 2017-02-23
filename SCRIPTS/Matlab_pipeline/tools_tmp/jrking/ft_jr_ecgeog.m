function output = ft_jr_ecgeog(cfg)
%% data_raw = ft_jr_ecgeog(cfg)
% function that automatically removes the ECG artefact using a PCA on the
% average artefact.
% -------------------------------------------------------------------------
% inputs
%   - cfg.dataset           => path of dataset
%   - cfg.plot              => 'yes' or 'no'            (default = 'yes')
%   - cfg.chantypes         => cells of chantypes       (default => all)
%   - cfg.ecgchan           => ecg channel              (default => read from header)
%   - cfg.dataformat        =>                          (default => 'neuromag')
%   - cfg.headerformat      =>                          (default => 'neuromag')
%   - cfg.prestim           => cut before ecg           (default => .2)
%   - cfg.poststim          => cut after ecg            (default => .5)
%   - cfg.dividetrial       => divide computation       (default => by 1)
%   - cfg.corr_thresh       => corr(PC,ecg) threshold   (default => .1)
% output
%   - data                  => structure containing continuous FT data
% -------------------------------------------------------------------------
% requires
%   - fieldtrip 2011
%   - MNE toolbox
% -------------------------------------------------------------------------
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% (c) 2011 Jean-Rémi KING
% jeanremi.king+matlab@gmail.com
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~isfield(cfg,'dataset'),     error('needs cfg.dataset');                 end
if ~isfield(cfg,'plot'),        cfg.plot        = 'yes';                    end
%-- read header
hdr                             = ft_read_header(cfg.dataset);
disp(hdr);
if ~isfield(cfg,'chantypes'),   cfg.chantypes   = {1:hdr.nChans};           end % cells dividing types of sensors (gradiometers, etc)
%-- finds ecg channels
if ~isfield(cfg,'ecgchan'),     cfg.ecgchan     = find(cell2mat(cellfun(@(x) ~isempty(findstr('ECG',x)), hdr.label, 'UniformOutput', false))); end
if ~isfield(cfg,'eogchan'),     cfg.eogchan     = find(cell2mat(cellfun(@(x) ~isempty(findstr('EOG',x)), hdr.label, 'UniformOutput', false))); end
if ~isfield(cfg,'headerformat'),cfg.headerformat= 'neuromag_mne';           end
if ~isfield(cfg,'dataformat'),  cfg.dataformat  = 'neuromag_mne';           end
if ~isfield(cfg,'ecg_prestim'), cfg.ecg_prestim = .200;                     end
if ~isfield(cfg,'ecg_poststim'),cfg.ecg_poststim= .500;                     end
if ~isfield(cfg,'eog_prestim'), cfg.eog_prestim = .500;                     end
if ~isfield(cfg,'eog_poststim'),cfg.eog_poststim= 1.000;                    end
if ~isfield(cfg,'dividetrial'), cfg.dividetrial = 1;                        end % divide the computation by n trials for memory issue
if ~isfield(cfg,'corr_thresh'), cfg.corr_thresh = 3;                        end % correlation between ECG and PC, in STD
if ~isfield(cfg,'artnb'),       cfg.artnb       = 30;                       end % max number of artefacts to keep
if ~isfield(cfg,'ecg_thresh'),  cfg.ecg_thresh  = 3.5;                      end % in STD
if ~isfield(cfg,'eog_thresh'),  cfg.eog_thresh  = 3.5;                      end % in STD
if ~isfield(cfg,'max_comp'),    cfg.max_comp    = 3;                        end % maximum PC
cfg.trialfun                    = 'ft_jr_ecg_trialfun';                         % get heart beat as triggers

ecg_eog = {'ECG', 'EOG'};
for art = 1:2
    figure(art);
    cfg_ecg.trial               = 1:cfg.artnb;
    if art == 1 % ---------- ECG
        cfg_ecg                 = cfg;
        cfg_ecg.prestim         = cfg.ecg_prestim;
        cfg_ecg.poststim        = cfg.ecg_poststim;
        cfg_ecg.threshold       = cfg.ecg_thresh;
        cfg_ecg.artchan         = cfg.ecgchan;
        cfg_ecg.trial           = 1:cfg.artnb;
        cfg_art                 = ft_definetrial(cfg_ecg);
    else        % ---------- EOG
        cfg_eog                 = cfg;
        cfg_eog.prestim         = cfg.eog_prestim;
        cfg_eog.poststim        = cfg.eog_poststim;
        cfg_eog.threshold       = cfg.eog_thresh;
        cfg_eog.artchan         = cfg.eogchan(1); % 1 or 2?? for EOGV & EOGH?
        cfg_eog.trial           = 1:cfg.artnb;
        cfg_art                 = ft_definetrial(cfg_eog);
    end
    
    set(gcf,'name', ecg_eog{art});
    
    
    %-- read data using heart beats as trials
    data_art                    = ft_preprocessing(cfg_art);
    %-- average data
    cfg_artpca                  = [];
    avg_tmp                     = data_art;
    avg_tmp.time                = {};
    avg_tmp.trial               = {};
    
    %----- divide by n trials to reduce memory issue
    for trial = 1:round(length(data_art.trial)/cfg.dividetrial):length(data_art.trial)
        if (trial+round(length(data_art.trial)/cfg.dividetrial)-1) <= length(data_art.trial)
            cfg_artpca.trials   = trial:(trial+round(length(data_art.trial)/cfg.dividetrial)-1);
        else
            cfg_artpca.trials   = trial:length(data_art.trial);
        end
        data_tmp                = ft_timelockanalysis(cfg_artpca,data_art);
        avg_tmp.trial{end+1}    = data_tmp.avg;
        avg_tmp.time{end+1}     = data_tmp.time;
    end
    data_art                 = ft_timelockanalysis([],avg_tmp);
    clear avg_tmp;
    
    %-- get continuous signal
    cfg_raw                     = [];
    cfg_raw.continuous          = 'yes';
    cfg_raw.headerformat        = cfg.headerformat;
    cfg_raw.dataformat          = cfg.dataformat;
    cfg_raw.dataset             = cfg.dataset;
    data_raw                    = ft_preprocessing(cfg_raw);
    
    %-- apply pca
    data_raw.components         = data_raw.trial{1};
    data_art.pca             = {};
    
    %-- apply pca independlty for each sensor
    for chantype = 1:length(cfg.chantypes)
        disp(['channel type ' num2str(chantype)]);
        
        disp(['computes pca on ' ecg_eog{art} '...']);
        data_art.pca{chantype}           = princomp(data_art.avg(cfg.chantypes{chantype},:)');
        data_raw.components(cfg.chantypes{chantype},:) = data_art.pca{chantype}'*data_raw.trial{1}(cfg.chantypes{chantype},:);
        
        %-- check whether thec components correlate with heart beat timing
        disp(['computes correlation with ' ecg_eog{art} '...']);
        data_art.r{chantype}                = abs(corr(data_raw.components(cfg.chantypes{chantype},:)', data_raw.trial{1}(cfg_art.artchan,:)'));
        
        %-- will remove the components that correlates the most with the art
        data_art.rm_components{chantype}    = find(data_art.r{chantype}(1:cfg.max_comp) >= cfg.corr_thresh*std(data_art.r{chantype}));
        %-- and keep the other
        data_art.keep_components{chantype}  = setdiff(1:size(data_art.pca{chantype},1),data_art.rm_components{chantype});
        
        data_art.clear_comp{chantype}       = zeros(length(data_art.rm_components{chantype}),size(data_art.pca{chantype},1));
        data_art.clear_comp{chantype}       = cat(2,data_art.clear_comp{chantype}',data_art.pca{chantype}(:,data_art.keep_components{chantype}))';
        
        
        %-- watch effect on average art
        data_art.avg_comps{chantype}     = ...
            data_art.pca{chantype}*...
            data_art.clear_comp{chantype}*...
            data_art.avg(cfg.chantypes{chantype},:);
        
        %%-- transform continuous signal
        %data_raw.trial{1}(cfg.chantypes{chantype},:) = ...
        %data_art.pca{chantype}*...
        %data_art.clear_comp{chantype}*...
        %data_raw.trial{1}(cfg.chantypes{chantype},:);
        
        %-- plotting functions
        if strcmp(cfg_art.plot,'yes')
            %-- art
            subplot(6,length(cfg.chantypes),length(cfg.chantypes)+chantype);hold on;
            title('art');
            plot(data_art.time,data_art.avg(cfg_art.artchan,:));
            %-- mean artefact
            subplot(3,length(cfg.chantypes),length(cfg.chantypes)+chantype);hold on;
            title(['artifact chans ' num2str(chantype)]);
            plot(data_art.time,data_art.avg(cfg.chantypes{chantype},:)','r'); % average artifact
            plot(data_art.time,data_art.avg_comps{chantype}','g');                % corrected artefact
            legend({'avg artifact', 'corrected artefact'});
            %-- correlation in time between art and principal components
            subplot(3,length(cfg.chantypes) ,2*length(cfg.chantypes)+chantype);hold on;
            title('correlation PC & art')
            scatter(1:length(data_art.r{chantype}), data_art.r{chantype});
            plot([0 length(data_art.r{chantype})], repmat(cfg.corr_thresh*std(data_art.r{chantype}),1,2), 'g--');
            plot([cfg.max_comp cfg.max_comp], [0 1], 'g--');
        end
    end
    
    %-- save components
    output.chantypes        = cfg.chantypes;
    if art == 1 % ---------- ECG
        output.ecg.all_compts   = data_art.pca;
        output.ecg.clear_comps  = data_art.clear_comp;
        output.ecg.remove       = data_art.rm_components;
        output.ecg.trl          = cfg_art;
    else        % ---------- EOG
        output.eog.all_compts   = data_art.pca;
        output.eog.clear_comps  = data_art.clear_comp;
        output.eog.remove       = data_art.rm_components;
        output.eog.trl          = cfg_art;
    end
    clear data*
end

return