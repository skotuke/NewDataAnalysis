close all;
all_data = abfload('Z:\Molecular Devices\pCLAMP\Data\2017\08 2017\24 08\17824011.abf');

rate = 10; %adjust the rate to get graph plotted faster or slower (to get real time your filter value/60 (mine is 10,000/60=~160), increase it to make it faster, reduce it to make it slower)
from = 17769; %where to start (seconds*filter)
to = 19003; %% size(data, 1); %where to finish
sweeps = [1,4,7]; %tell which sweeps need to be plotted (if there is just one, write '1')

%% Set up the movie.
writerObj = VideoWriter('out.avi'); % Name it.
writerObj.FrameRate = 60; % How many frames per second.
open(writerObj); 

figure(1); 
hold all
set(gca,'visible','off');
%axis([from min(data) to max(data)])    

for sweep=sweeps
    data = all_data(1:size(all_data,1),1,sweep);
    for i=from:rate:to      
        plot(i:i+rate, data(i:i+rate), 'b','color', 'b', 'LineWidth',2); 
        %adjust graph options here: if want to change the color of the graph, after 'color', change into blue (b), red (r),
        %increasing the number after linewidth adjusts the line thickness
        ylim ([-70 -45])  %you can set the Y axis limit here (if no need for y axis limit add % symbol before ylim to allow automatic axis adjustment)
        xlim ([17769 19003]) %you can set the X axis limit here
        set(gcf,'color','white'); %background colour set here
        frame = getframe(gcf); % 'gcf' can handle if you zoom in to take a movie.
        writeVideo(writerObj, frame);
    end
end
hold off
close(writerObj);