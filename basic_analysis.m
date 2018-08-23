close all;

% mfilename takes the whole path, fileparts splits the name (firing single or joint) from the rest of the path
path = fileparts(mfilename('fullpath'));
addpath(sprintf('%s/common', path));

% filenames is a list of filenames I selected in the dialog box
[filenames, path] = uigetfile({'*.abf'}, 'Select file(s)', 'MultiSelect', 'on');
if ~iscell(filenames) % if filenames is not an array
    filenames = {filenames};%make it into one element array. we want it in am array because you cannot have text inthe matrix
end

number_of_files = length(filenames); %length is a function getting a number
m = 1;

% This is used for calculating velocity from latency.
distance = 1556.596/1000000;

% For how many sweeps do you want to preprovision arrays (use number from the 
% file with most sweeps in it)
sweeps = 10;

% Do not forget to set the filter to correspond with what you had when
% recording.
filter = 20000;
virtual_sweeps_1hz = [
    0.5688
    1.5688
    2.5688
    3.5688
    4.5688
    5.5688
    6.5688
    7.5688
    8.5688
    9.5688


] * filter;

virtual_sweeps_10hz = [
    0.5688
    0.6688
    0.7688
    0.8688
    0.9688
    1.0688
    1.1688
    1.2688
    1.3688
    1.4688

    
] * filter;

virtual_sweeps_30hz = [
    0.5688
    0.60215
    0.6355
    0.66885
    0.7022
    0.73555
    0.7689
    0.80225
    0.8356
    0.86895

  
] * filter;

virtual_sweeps_100hz = [
    0.5688
    0.5788
    0.5888
    0.5988
    0.6088
    0.6188
    0.6288
    0.6388
    0.6488
    0.6588

] * filter;

virtual_sweeps_300hz = [
    0.5688
    0.572133333
    0.575466667
    0.5788
    0.582133333
    0.585466667
    0.5888
    0.592133333
    0.595466667
    0.5988


] * filter;

use_virtual_sweeps = 1;

% If use_virtual_sweeps is 0, you can set one artifact, which will be taken
% be used in every sweep.
%stimulus_artifact = 0.17813 * filter;

% If you have all the action potentials in one sweep, you can instead set
% the list of artifacts in the list above. To use it, you need to set
% use_virtual_sweeps to 1.
%virtual_sweeps = virtual_sweeps_30hz;

k_rows = 4;
k_spot = 0;
k_figure = 0;

AP_times_all = zeros(sweeps, number_of_files);
AP_actual_sizes_all = zeros(sweeps, number_of_files);
Latency_all = zeros(sweeps, number_of_files);
speed_all = zeros(sweeps, number_of_files);
hw_list_all = zeros(sweeps, number_of_files);
max_second_derivatives_all=zeros(sweeps, number_of_files);
RMP_all = zeros(sweeps, number_of_files);
CV_all = zeros(sweeps, number_of_files);
Latency_all_means = zeros(1, number_of_files);
Latency_all_std = zeros(1, number_of_files);
width_list_all = zeros(sweeps, number_of_files);

for i = 1:number_of_files
    if use_virtual_sweeps == 1;
        if i==1;
          virtual_sweeps = virtual_sweeps_1hz;
        end

        if i==2| i==4| i==6 | i==8 | i==10 | i==12
          virtual_sweeps = virtual_sweeps_10hz;
        end

        if i==3;
          virtual_sweeps = virtual_sweeps_30hz;
        end

        if i==5;
          virtual_sweeps = virtual_sweeps_100hz;
        end

        if i==7| i==9| i==11
          continue;
        end
    end
    
    filename = filenames(i);
    fullname = strcat(path, filenames(i));
    data = abfload(char(fullname));
    
    if isempty(data)
        continue % data could not be loaded
    end
    
    % Preview file
    duration = size(data, 1);
    sweeps = size(data, 3);
    duration_s = (1 / filter):(1 / filter):(duration / filter);
    
    if use_virtual_sweeps
       sweeps = length(virtual_sweeps); 
       raw_data = data(1:duration, 1);
       data = zeros(duration, sweeps);
       
       for vs = 1:sweeps
          data(1:duration, vs) = raw_data;
          data(1:ceil(virtual_sweeps(vs)), vs) = raw_data(ceil(virtual_sweeps(vs)));
          if vs < sweeps
              data(ceil(virtual_sweeps(vs + 1)):duration, vs) = raw_data(ceil(virtual_sweeps(vs + 1)));    
          end
       end
       
       stimulus_artifacts = virtual_sweeps;
    else 
        stimulus_artifacts(1:sweeps) = stimulus_artifact; 
    end
    
    for j = 1:sweeps
        sweep_data = data(1:duration, j); % sweep is an argument
        
        k_spot = k_spot + 1;
        if k_spot > k_rows * k_rows
            k_figure = k_figure + 1;
            k_spot = 1;
        end
        
        figure(10 + k_figure);
        subplot(k_rows, k_rows, k_spot);
        plot(duration_s, sweep_data);
        xlabel('Time (sec)');
        ylabel('Voltage(mV)');
        title(filenames(i));
        set(figure(10 + k_figure), 'Visible', 'On');
        
        figure(30 + k_figure);
        subplot(k_rows, k_rows, k_spot);
        dvdt = diff(sweep_data(1:duration))./(diff(1:duration)/10)';
        plot(sweep_data(2:duration), dvdt);
    end
    
    k_figure = k_figure + 1;
    total_length = floor(duration * sweeps / filter);
    
    [ ...
        AP_times, ...
        AP_actual_sizes, ...
        Latency, ...
        AP_times_number, ...
        hw_list, ...
        max_second_derivatives, ...
        RMP, ...
        width, ...
        width_start, ...
        width_finish ...
    ] = parse(data, duration, stimulus_artifacts, sweeps, filter);
    m = m + 1;
    
    AP_times_all (:,i) = AP_times(1:sweeps);
    AP_actual_sizes_all (:,i) = AP_actual_sizes;
    AP_actual_sizes_all( :, ~any(AP_actual_sizes_all,1) ) = [];
    Latency_all (:,i) = Latency (1:sweeps);
    Latency_all( :, ~any(Latency_all,1) ) = [];
    
    speed_all (:,i) = distance./Latency;
    for k = 1:length(Latency)
        if speed_all(k,i) == Inf
            speed_all(k,i) = 0;
        end
    end    
     speed_all( :, ~any(speed_all,1) ) = [];
    
    CV(:,i) = std(Latency_all)/mean(Latency_all);
    CV( :, ~any(CV,1) ) = [];
    hw_list_all(:,i) = hw_list(1:sweeps)./filter*1000;
    hw_list_all( :, ~any(hw_list_all,1) ) = [];
    width_list_all(:,i) = width(1:sweeps)./filter*1000;
    width_list_all( :, ~any(width_list_all,1) ) = [];
    max_second_derivatives_all(:,i) = max_second_derivatives (1:sweeps)*filter/1000;
    max_second_derivatives_all( :, ~any(max_second_derivatives_all,1) ) = [];
    %RMP_all (:,i) = RMP(1:sweeps);
    
    %Latency_all_means(1, i) = mean(Latency_all(Latency_all(:, i) ~= 0, i));
    %Latency_all_std(1, i) = std(Latency_all(Latency_all(:, i) ~= 0, i));
    %speed_all_means (1, i) = mean(speed_all(speed_all(:, i) ~= 0, i));
    %AP_actual_sizes_all_means (1, i) = mean(AP_actual_sizes_all(AP_actual_sizes_all(:, i) ~= 0, i));
    %hw_list_all_means (1, i) = mean(hw_list_all(hw_list_all(:, i) ~= 0, i));
    %max_second_derivatives_all_means (1, i) = mean(max_second_derivatives_all(max_second_derivatives_all(:, i) ~= 0, i));
end



[ignore primary_filename] = fileparts(char(filenames(1)));

if number_of_files>1
    excel_name = sprintf('%s\\AP velocity_%s_and_more.xlsx', path, primary_filename) %it tells the full path of the file
else
    excel_name = sprintf('%s\\AP velocity_%s.xlsx', path, primary_filename) %it tells the full path of the file
end

if use_virtual_sweeps == 1;
    filenames(:,[7 9 11]) = [];
end

warning('off', 'MATLAB:xlswrite:AddSheet');
row_header={'1', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'Mean', 'Length'};
row_header2={'1', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'Mean', 'SD'};
xlswrite(excel_name, row_header2', 'Latency','A4');
xlswrite(excel_name, [filenames], 'Latency', 'B3');
xlswrite(excel_name, Latency_all*1000, 'Latency', 'B4');
xlswrite(excel_name, Latency_all_means*1000, 'Latency', 'B14');
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
xlswrite(excel_name, row_header', '20 width','A4');
xlswrite(excel_name, [filenames], '20 width', 'B3');
xlswrite(excel_name, width_list_all, '20 width', 'B4');
%xlswrite(excel_name, row_header', 'RMP','A4');
%xlswrite(excel_name, [filenames], 'RMP', 'B3');
%xlswrite(excel_name, RMP_all, 'RMP', 'B4');
%xlswrite(excel_name, mean(RMP_all), 'RMP', 'B14');

%data = abfload('D:\Clouds\One Drive\Electrophysiology\2014\2014\10 2014\31 10\14o31019.abf');