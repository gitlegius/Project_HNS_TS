function [part_percent,next_percent,start_time,time_left_last,time_elapsed] = processing_data_test(part_percent,percent_period,next_percent,start_time,k_read,time_left_last,time_elapsed)

percent = part_percent*k_read;
if ~round(mod(percent,percent_period),1)&&next_percent <= percent
    switch start_time
        case 0
            time_left = 0;
            time_elapsed = 0;
            start_time = start_time+1;
        case 1
            time_left = toc*((100-percent)/percent_period)/60;
            time_elapsed = time_elapsed + toc;
            start_time = start_time+1;
        case 2
            time_elapsed = time_elapsed + toc;
            time_left = (toc*((100-percent)/percent_period)/60+time_left_last)/2;
    end
    
    disp(['Percent of data proccessing = ' int2str(percent) ' %']);
    disp(['time elapsed ~= ' num2str(time_elapsed/60) ' min']);
    disp(['time left ~= ' num2str(time_left) ' min']);
    
    next_percent = percent+(percent_period-mod(percent,percent_period));
    time_left_last = time_left;
    tic;
end