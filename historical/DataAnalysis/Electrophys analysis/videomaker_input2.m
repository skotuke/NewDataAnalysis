close all;

rate = 3; %adjust the rate to get graph plotted faster or slower (to get real time your filter value/60 (mine is 10,000/60=~160), increase it to make it faster, reduce it to make it slower)
from = 1; %where to start (seconds*filter)
to = 124; %% size(data, 1); %where to finish
sweeps=size(stim,2);

%% Set up the movie.
writerObj = VideoWriter('out.avi'); % Name it.
writerObj.FrameRate = 60; % How many frames per second.
open(writerObj); 

figure(1); 
hold all
set(gca,'visible','off');
%axis([from min(data) to max(data)])

for sweep= 1:sweeps
   data = stim(1:size(stim,1),sweep);
    for i = from:rate:to      
        plot(i:i+rate, data(i:i+rate), 'b', 'color', 'r', 'LineWidth',2); 
        %adjust graph options here: if want to change the color of the graph, after 'color', change into blue (b), red (r),
        %increasing the number after linewidth adjusts the line thickness
        ylim([0 350]) %you can set the Y axis limit here (if no need for y axis limit add % symbol before ylim to allow automatic axis adjustment)
        xlim([1 127]) %you can set the X axis limit here
        set(gcf,'color','white'); %background colour set here
        frame = getframe(gcf); % 'gcf' can handle if you zoom in to take a movie.
        writeVideo(writerObj, frame);
   end
end
hold off
close(writerObj);