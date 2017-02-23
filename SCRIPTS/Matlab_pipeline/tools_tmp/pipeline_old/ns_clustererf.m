function ns_clustererf(roi,av1,av2,channel)

load('/neurospin/meg_tmp/tools_tmp/pipeline/SensorClassification.mat');
switch channel
    case 'mag'
        av1 = ft_selectdata(av1,'channel',Mag(roi));
        av2 = ft_selectdata(av2,'channel',Mag(roi));
    case 'grad1'
        av1 = ft_selectdata(av1,'channel',Grad_1(roi));
        av2 = ft_selectdata(av2,'channel',Grad_1(roi));
    case 'grad2'
        av1 = ft_selectdata(av1,'channel',Grad_2(roi));
        av2 = ft_selectdata(av2,'channel',Grad_2(roi));
    otherwise
        disp('Error: Incorrect channel selection!');
end;

figure;
plot(av1.time,mean(av1.avg,1),'b'); hold on; plot(av1.time,mean(av2.avg,1),'r'); axis tight;

