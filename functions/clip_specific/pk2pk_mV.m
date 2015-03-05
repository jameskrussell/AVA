function [ SIGpk,peak ] = pk2pk_mV( ecgSig )
%calculates a median peak to trough amplitude
%using a window of 380ms (95 points *4 mS) and advancing by  
%45 at each time point to slide over signal and then
% to take the median for the peak to peak asystole calcs
ecgSig = ecgSig * 1000; %convert from mV to uV


for k=1:20
    %endpoint=((k-1)*45)+95
    clip2=ecgSig(((k-1)*45)+1:((k-1)*45)+95);
%     gg=figure;
%     plot(clip2)
%     yLowLim = min(-2000);%ecgSig);
%     yHiLim = max(2000);%ecgSig);
%     ylim([yLowLim yHiLim]);
    peak(k)=peak2peak(clip2);
%     grid on
%     pause(.1)
%     close
end

SIGpk=median(peak);
peak=sort(peak);
%%
            if(0)
             set(0,'Units','pixels')
                                    scnsize = get(0,'ScreenSize');
                                    fig2=figure;
                                    position = get(fig2,'Position');
                                    outerpos = get(fig2,'OuterPosition');
                                    borders = outerpos - position;
                                    edge = -borders(1)/2;
                                    pos1 = [edge,...
                                    scnsize(4) * (.05),...
                                    scnsize(3)/1 - edge,...
                                    scnsize(4)/2.1];

                                    set(fig2,'OuterPosition',pos1) 

            %%

                %plot(peak,'Linewidth',3)
%                 yHiLim = max(2000);%ecgSig);
%                  ylim([0 yHiLim]);
%                  grid on
                 %%
                %pause
                %close
            end
end

