function [par,data]=ns_lpf(par,data,lpf)
par.lpf = lpf;           % low-pass frequency (Hz)
for j=1:length(data.trial)
    disp(['low-pass filtering trial ' num2str(j)])
    data.trial{j} = ft_preproc_lowpassfilter(data.trial{j}, data.fsample, par.lpf);
end
