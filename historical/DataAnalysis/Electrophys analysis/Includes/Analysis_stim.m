function [AP_times, AP_actual_sizes, Latency, AP_times_number, hw_list, max_second_derivatives, RMP, width, width_start, width_finish] = Analysis_stim(data, sweep, k, k_total, filter, output_folder, name, file, duration, stimulus_artifact, distance, sweeps, filenames, number_of_files)
% Function Analysis

% after '=' is the name of the funtion and in brackets there is a list of
% arguments


% Arguments:
%  matrix @data -
%  int @sweep - which sweep I am analysing
%  int @k - kelintas failas is visu failu yra nagrinejamas
%  int @k_total - kiek failu is viso yra atidaroma vienu kartu
%  int @filter (default: 10000) -
%  string @filename (default: Data file) -
%  string @output_folder (default: Default) -
% Returns (lauztiniai skliaustai salia function, which values the function will return)
%  matrix ISI_values -
%  matrix AP_sizes -
%  int AP_number -

% arguments are taken from the file that funtion is called out from. The
% ORDER of the arguments matters, not the names

formatOut = 'HH-MM-SS';
fulltime = strcat(date,{' '}, datestr(now,formatOut));

if nargin < 5 % if less than 5 arguments, filter becomes default
    filter = 10000;
end

if nargin < 6
    filename = 'Data file'; %just a default heading
end

if nargin < 7
    output_folder = 'Default'; %just a name, we do not use it anywhere
end

%these are necessary so I would not need to pass these arguments when I do
%not need to pass them

k_rows = ceil(sqrt(k_total)); %apvalinti i virsu
k_spot = k; %kelintas grafikelis is grafiku grid
k_figure = 0; %numeris kelintas
while k_spot > k_rows * k_rows %jeigu jau nebetelpa,pradeti numeruoti is naujo. I need this as sometimes I make a limit of
    k_spot = k_spot - k_rows * k_rows;
    k_figure = k_figure + 10;
end

thresh_AP = -30; %what threshold voltage needs to pass to be considered as firing an AP

AP_times = zeros(sweeps, 1);
AP_max = -1000;
declining = 0;
AP_times_number = 0;
AP_sizes = zeros(10, 1);
AP_min_list = zeros(10, 1);
Latency = zeros(sweeps, 1);
speed = zeros(sweeps, 1);
hw_list = zeros(sweeps, 1);
ap_threshold_list = zeros(sweeps, 1);
max_second_derivatives=zeros(sweeps, 1);
RMP = zeros (sweeps, 1);
CV = zeros (sweeps, 1);
width = zeros(sweeps,1);

duration_s = (1/filter):(1/filter):(duration/filter);%zero does not exist in matlab, therefore it starts at the smallest point.
%1/filter pirmasis element in the graph or matrix, 1/filter step size, and duration/filter paskutinis elemnet in the graph/matrix

for j = 1:sweeps
    sweep_data = data(1:duration, j); % sweep is an argument
    RMP (j) = mean(sweep_data (1:1770));
    
    figure(1 + k_figure);
    subplot(k_rows, k_rows, k_spot);
    plot(duration_s, sweep_data);
    xlabel('Time (sec)');
    ylabel('Voltage(mV)');
    title(file);
    set(figure(1 + k_figure), 'Visible', 'On');
    
    start_i = -1;
    finish_i = -1;
    width_start = -1;
    width_finish = -1;
    
    for i = 1:duration
        if sweep_data(i) > thresh_AP || (declining == 0 && AP_max > thresh_AP)
            if declining == 0
                if start_i == -1
                    for ii = i:-1:6
                        start_i = ii;
                        if sweep_data(ii) - sweep_data(ii-1) <= 0
                            break;
                        end
                    end
                end
                
                if sweep_data(i) > -20 && width_start == -1
                    width_start = i;
                end
                
                
                if sweep_data(i) > AP_max
                    AP_max = sweep_data(i);
                else
                    declining = 1;
                    AP_times_number = AP_times_number + 1;
                    AP_times(j) = i - 1;
                    AP_sizes(j) = AP_max;
                end
            end
        else            
            if declining == 1 && sweep_data(i) > sweep_data(i-1) && AP_times_number > 0
                declining = 0;
                AP_min_list(j) = sweep_data(i-1);
                AP_hh = AP_sizes(j) - (AP_sizes(j) - AP_min_list(j)) / 2;
                AP_max = -10000;
                
                if finish_i == -1
                    for ii = i:duration
                        finish_i = ii;
                        if sweep_data(ii) - sweep_data(ii-1) >= 0
                            break;
                        end
                    end
                end
            end
        end
        
        if declining == 1 && sweep_data(i) < -20 && width_finish == -1
            width_finish = i - 1;
        end
    end
    
    width(j) = width_finish - width_start;
    
    if start_i < 1 || finish_i < 1
        AP_times(j) = stimulus_artifact;
        continue;
    end
    
    half_start_i = -1;
    for i = 1:(duration - 1)
        if half_start_i == -1 && sweep_data(i) <= AP_hh && sweep_data(i+1) >= AP_hh
            half_start_i = i;
        end
        
        if half_start_i ~= -1 && sweep_data(i) >= AP_hh && sweep_data(i+1) <= AP_hh
            half_finish_i = i;
            hw_list(j) = half_finish_i - half_start_i;
            break;
        end
    end
    
    figure(2);
    
    min_threshold = 1; % 10V/s
    dvdt = diff(sweep_data(1:duration))./(diff(1:duration)/10)';
    plot(sweep_data(2:duration), dvdt);
    
    for k = 1:(duration-1)
        if dvdt(k) > min_threshold
            ap_threshold_list(j) = sweep_data(k-1);
            break;
        end
    end
    
    max_second_derivatives(j) = 0;
    for k = start_i:finish_i
        if dvdt(k+1) - dvdt(k) > max_second_derivatives(j)
            max_second_derivatives(j) = dvdt(k+1) - dvdt(k);
        end
    end
end

AP_sizes = AP_sizes(1:sweeps);
AP_min_list = AP_min_list(1:sweeps);
AP_actual_sizes = AP_sizes-AP_min_list;
Latency = (AP_times-stimulus_artifact)./100;

end

