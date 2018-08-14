function [RMP] = Analysis_RMP(data, duration)

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
     
        RMP = mean(data);
end
   

