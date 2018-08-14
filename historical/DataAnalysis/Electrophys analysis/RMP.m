close all;

path = fileparts(mfilename('fullpath')); %mfilename takes the whole path, fileparts splits the name (firing single or joint) from the rest of the path
delete(sprintf('%s/Output/Stimulus/*.xlsx', path));
addpath(sprintf('%s/Includes', path));

[filenames, path] = uigetfile({'*.abf'}, 'Select file(s)', 'MultiSelect', 'on'); %filenames is a list of filenames I selected in the dialog box

if ~iscell(filenames) %if filenames is not an array
    filenames = {filenames};%make it into one element array. we want it in am array because you cannot have text inthe matrix
end

number_of_files = length(filenames); %length is a function getting a number

RMP_all = zeros (1, number_of_files);

for i = 1:number_of_files
    fullname = strcat(path, filenames(i));%strcat concatinatina
    data = abfload(char(fullname));
    duration_cut=10 %in seconds
    
    
    if isempty(data)
        continue %reiskia skippinti viska after this and get to the next, if there is sth wrong with data
    end
    
    %duration = size(data, 1);
    filter = 100000;
    duration=duration_cut*filter;
    
    fullname = sprintf('%s %d:%d', filenames{1});
    [RMP]=Analysis_RMP(data, duration);
   
 RMP_all(i)=RMP;   
end
    
    [ignore primary_filename] = fileparts(char(filenames(1)));
    
    if number_of_files>1
    excel_name = sprintf('%s\\RMP_%s_and_more.xlsx', path, primary_filename) %it tells the full path of the file
else
    excel_name = sprintf('%s\\RMP_%s.xlsx', path, primary_filename) %it tells the full path of the file
    end

    warning('off', 'MATLAB:xlswrite:AddSheet');
    xlswrite(excel_name, 'RMP', 'RMP','A2');
    xlswrite(excel_name, RMP_all', 'Latency','A4');    
    