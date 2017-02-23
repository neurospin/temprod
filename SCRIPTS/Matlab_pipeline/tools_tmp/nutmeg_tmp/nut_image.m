function nut_image(op,varargin)
% analagous to spm's spm_image -- used to update coords when clicking
% around MRI viewer

global st nuts beam rivets
if(~isempty(beam))
    coreg = beam.coreg;
else
    coreg = nuts.coreg;
end

if(~exist('op','var') || ~ischar(op))
    % ugly hack for compatibility with SPM8 ButtonDownFcn
    % call SPM refresh function
    if(~strcmp(spm('ver'),'SPM2'))
        feval(rivets.spm_refresh_handle);
    end
    op = 'shopos';
end

switch(op)
    case 'shopos'
        if isfield(st,'mp'),
            fg  = spm_figure('Findwin','Graphics');
            posmrimm = spm_orthviews('pos')';
            set(st.megp,'String',sprintf('%.1f %.1f %.1f',nut_mri2meg(posmrimm)));
            
            [crap,mriname,crap2]=fileparts(coreg.mripath);
            if isfield(coreg,'norm_mripath')
                posmni = nut_mri2mni(posmrimm);
                set(st.mnip,'String',sprintf('%.1f %.1f %.1f',posmni));
%            elseif strcmp(mriname(1),'w')
            elseif(isfield(rivets,'MNIdb'))
                posmni = posmrimm;
                set(st.mnip,'String',sprintf('%.1f %.1f %.1f',posmni));
            end
                
%             if (isfield(beam,'coreg') && (isfield(coreg,'norm_mripath'))) || strcmp(mriname(1),'w')
            if(isfield(rivets,'MNIdb') && all(isfinite(posmni)))
                ind = rivets.MNIdb.data(dsearchn(rivets.MNIdb.coords,posmni),:);
 
                for ii=1:5
                    labels(ii) = rivets.MNIdb.cNames{ii}(ind(ii));
                end

                % remove "Unidentified" tags
                labels(strmatch('Unidentified',labels))=[];
                
                set(st.mnilabel,'String',labels);
            else
                set(st.mnip,'String','');
            end
            
            % set sliders
            posmrivx = nut_mm2voxels(posmrimm);
            
            mat = st.vols{1}.premul*st.vols{1}.mat;
            R=spm_imatrix(st.vols{1}.mat);
            R = spm_matrix([0 0 0 R(4:6)]);
            R = R(1:3,1:3);
            dim = (st.vols{1}.dim*R)';
            
            for i=1:3
                set(st.slider{i},'Value',posmrivx(i)/dim(i));
            end

            if(~isempty(beam))
                feval(rivets.ts_refresh_handle);
            end
            
            if isfield(beam,'imagingdata')      % Adrian added this for personal use on 18Jan2010
                fcm_showcorr;
            end
            
        else
            st.Callback = ';';
        end
        return
    case 'setposmeg'
        if isfield(st,'megp'),
            fg = spm_figure('Findwin','Graphics');
            if(any(findobj(fg) == st.megp))
                pos = sscanf(get(st.megp,'String'), '%g %g %g',[1 3]);
                if(length(pos)==3)
                    pos = nut_meg2mri(pos);
                else
                    pos = spm_orthviews('pos');
                end
                nut_reposition(pos);
            end
        end
        return
    case 'setposmni'
        if isfield(st,'mnip'),
            fg = spm_figure('Findwin','Graphics');
            if(any(findobj(fg) == st.mnip))
                pos = sscanf(get(st.mnip,'String'), '%g %g %g',[1 3]);
                if(length(pos)==3)
                    pos = nut_mni2mri(pos);
                else
                    pos = spm_orthviews('pos');
                end
                nut_reposition(pos);
            end
        end
        return
    otherwise
        error('you''re doing something wrong.');
end
