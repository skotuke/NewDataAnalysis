close all;

path = fileparts(mfilename('fullpath')); %mfilename takes the whole path, fileparts splits the name (firing single or joint) from the rest of the path
delete(sprintf('%s/Output/Frequency/*.xlsx', path));
addpath(sprintf('%s/Includes', path));

[filenames, path] = uigetfile({'*.abf'}, 'Select file(s)', 'MultiSelect', 'on'); %filenames is a list of filenames I selected in the dialog box


if ~iscell(filenames) %if filenames is not an array
    filenames = {filenames};%make it into one element array. we want it in am array because you cannot have text inthe matrix
end

number_of_files = length(filenames); %length is a function getting a number 
m = 1;

for i = 1:number_of_files
    fullname = strcat(path, filenames(i));%strcat concatinatina
    data = abfload(fullname{1});
    name = filenames(i);

    if isempty(data)
        continue %reiskia skippinti viska after this and get to the next, if there is sth wrong with data
    end

    % Preview file
    duration = size(data, 1);
    sweeps = size(data, 3);
    sq = ceil(sqrt(sweeps));

    data = reshape(data, duration * sweeps, 1);
    
    %figure(99);
    %plot(data(1:duration*sweeps, 1));
    %title(filenames(i));
  
    filter = 10000;
    
    
    total_length = floor(duration * sweeps / filter);

    if total_length>300
            total_length=300;
    end
    
    if total_length<200
        filter=0;
    end
        
   if filter == 0
        %close 99;
        continue;
    end
        
           startts = 0; 
           endts = 100;  
           duration=(endts-startts)*filter;
           fullname = sprintf('%s %d:%d', name{1}, startts, endts);
           [ISI_values, AP_actual_sizes, AP_times_number]=Analysis_100s(data((startts * filter + 1):(endts * filter)), 1, m, 9, filter, fullname, 'Frequency',path, filenames{1}, filenames(i), duration );
           m = m + 1;
           
            

             
    
    %close 99;
end



%data = abfload('D:\Clouds\One Drive\Electrophysiology\2014\2014\10 2014\31 10\14o31019.abf');    