close all;

path = fileparts(mfilename('fullpath')); %mfilename takes the whole path, fileparts splits the name (firing single or joint) from the rest of the path
delete(sprintf('%s/Output/Stimulus/*.xlsx', path));
addpath(sprintf('%s/Includes', path));

[filenames, path] = uigetfile({'*.abf'}, 'Select file(s)', 'MultiSelect', 'on'); %filenames is a list of filenames I selected in the dialog box
%filenames =  '17d11005.abf';
%path = 'C:\Users\Daumante\Desktop\CV\December\';

if ~iscell(filenames) %if filenames is not an array
    filenames = {filenames};%make it into one element array. we want it in am array because you cannot have text inthe matrix
end

number_of_files = length(filenames); %length is a function getting a number
m = 1;

distance = 1451/1000;

AP_times_all = zeros(10, number_of_files);
AP_actual_sizes_all = zeros(10, number_of_files);
Latency_all = zeros(10, number_of_files);
speed_all = zeros(10, number_of_files);
hw_list_all = zeros(10, number_of_files);
max_second_derivatives_all=zeros(10, number_of_files);
CV_all = zeros (10,number_of_files);
Latency_all_means = zeros(1, number_of_files);
Latency_all_std = zeros(1, number_of_files);

filter = 20000;
stimulus_artifacts = [
    0.56905
    1.56905
    2.56905
    3.56905
    4.56905
    5.56905
    6.56905
    7.56905
    8.56905
    9.56905
];

stimulus_artifacts = round(stimulus_artifacts .* filter);

for i = 1:number_of_files
    fullname = strcat(path, filenames(i));%strcat concatinatina
    data = abfload(char(fullname));
    
    if isempty(data)
        continue %reiskia skippinti viska after this and get to the next, if there is sth wrong with data
    end
    
    % Preview file
    duration = size(data, 1);
    sweeps = size(data, 3);
    sq = ceil(sqrt(sweeps));
    
    %figure(99);
    %plot(data(1:duration*sweeps, 1));
    %title(filenames(i));
    
    total_length = floor(duration * sweeps / filter);
    
    fullname = sprintf('%s %d:%d', filenames{1});
    [AP_times, AP_actual_sizes, Latency, AP_times_number, hw_list, max_second_derivatives] = Analysis_stim_1Hz(data, m, 9, filter, filenames(i), duration, stimulus_artifacts);
    m = m + 1;
    
    AP_times_all (:,i) = AP_times;
    AP_actual_sizes_all (:,i) = AP_actual_sizes;
    Latency_all (:,i) = Latency;
    
    speed_all (:,i) = distance./Latency;
    for k = 1:length(Latency)
        if speed_all(k,i) == Inf
            speed_all(k,i) = 0;
        end
    end
    
    CV(:,i) = std(Latency_all)/mean(Latency_all);
    hw_list_all(:,i) = hw_list(1:sweeps);
    max_second_derivatives_all(:,i) = max_second_derivatives (1:sweeps)*100;
    
    Latency_all_means(1, i) = mean(Latency_all(Latency_all(:, i) ~= 0, i));
    Latency_all_std(1, i) = std(Latency_all(Latency_all(:, i) ~= 0, i));
    speed_all_means (1, i) = mean(speed_all(speed_all(:, i) ~= 0, i));
    AP_actual_sizes_all_means (1, i) = mean(AP_actual_sizes_all(AP_actual_sizes_all(:, i) ~= 0, i));
    hw_list_all_means (1, i) = mean(hw_list_all(hw_list_all(:, i) ~= 0, i));
    max_second_derivatives_all_means (1, i) = mean(max_second_derivatives_all(max_second_derivatives_all(:, i) ~= 0, i));
end



[ignore primary_filename] = fileparts(char(filenames(1)));

if number_of_files>1
    excel_name = sprintf('%s\\AP velocity_%s_and_more.xlsx', path, primary_filename) %it tells the full path of the file
else
    excel_name = sprintf('%s\\AP velocity_%s.xlsx', path, primary_filename) %it tells the full path of the file
end


warning('off', 'MATLAB:xlswrite:AddSheet');
row_header={'1', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'Mean', 'Length'};
row_header2={'1', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'Mean', 'SD'};
xlswrite(excel_name, row_header2', 'Latency','A4');
xlswrite(excel_name, [filenames], 'Latency', 'B3');
xlswrite(excel_name, Latency_all, 'Latency', 'B4');
xlswrite(excel_name, Latency_all_means, 'Latency', 'B14');
xlswrite(excel_name, Latency_all_std, 'Latency', 'B15');
xlswrite(excel_name, row_header', 'Velocity','A4');
xlswrite(excel_name, [filenames], 'Velocity', 'B3');
xlswrite(excel_name, speed_all, 'Velocity', 'B4');
xlswrite(excel_name, speed_all_means, 'Velocity', 'B14');
xlswrite(excel_name, distance, 'Velocity','B15');
xlswrite(excel_name, row_header', 'AP sizes','A4');
xlswrite(excel_name, [filenames], 'AP sizes', 'B3');
xlswrite(excel_name, AP_actual_sizes_all, 'AP sizes', 'B4');
xlswrite(excel_name, AP_actual_sizes_all_means, 'AP sizes', 'B14');
xlswrite(excel_name, row_header', 'AP HW','A4');
xlswrite(excel_name, [filenames], 'AP HW', 'B3');
xlswrite(excel_name, hw_list_all, 'AP HW', 'B4');
xlswrite(excel_name, hw_list_all_means, 'AP HW', 'B14');
% xlswrite(excel_name, row_header', 'AP threshold','A4');
% xlswrite(excel_name, {fullname}, 'AP threshold', 'B3');
% xlswrite(excel_name, ap_threshold_list, 'AP threshold', 'B4');
% xlswrite(excel_name, mean(ap_threshold_list), 'AP threshold', 'B14');
xlswrite(excel_name, row_header', 'Max dVdt','A4');
xlswrite(excel_name, [filenames], 'Max dVdt', 'B3');
xlswrite(excel_name, max_second_derivatives_all, 'Max dVdt', 'B4');
xlswrite(excel_name, max_second_derivatives_all_means, 'Max dVdt', 'B14');

%data = abfload('D:\Clouds\One Drive\Electrophysiology\2014\2014\10 2014\31 10\14o31019.abf');