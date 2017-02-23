function [tppos,tpneg,t]=ns_stattimecourse(stat)
tppos=mean((stat.posclusterslabelmat==1).*stat.stat,1);
tpneg=mean((stat.negclusterslabelmat==1).*stat.stat,1);
t=stat.time;

figure; 
set(gca,'Fontsize',14);
plot(t,-tpneg,'b','Linewidth',2); 
hold on; 
plot(t,tppos,'r','Linewidth',2); 
axis tight;
legend('-tpneg','tppos');
xlabel('ms');
ylabel('cluster statistics');

[peakneg,tpeakneg]=min(tpneg);
[peakpos,tpeakpos]=max(tppos);

disp(['Min negative cluster statistics: ' num2str(peakneg) ' at time point ' num2str(tpeakneg) ' (' num2str(t(tpeakneg)) ' ms)']);
disp(['Max positive cluster statistics: ' num2str(peakpos) ' at time point ' num2str(tpeakpos) ' (' num2str(t(tpeakpos)) ' ms)']);