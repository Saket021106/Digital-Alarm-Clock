module alarm_clk_rtl (
    input logic clk,         
    input logic reset,        
    input logic alarm_button,
    input logic time_button,
    input logic [3:0] key,
    input logic fast_watch,
    output logic sound_alarm,
    output logic [7:0] display_ms_hr,
    output logic [7:0] display_ls_hr,
    output logic [7:0] display_ms_min,
    output logic [7:0] display_ls_min
);
    logic one_minute, one_second;
    logic reset_count, load_new_c, show_new_time, show_a, load_new_a, shift;
 
    logic [3:0] current_time_ms_hr, current_time_ls_hr, current_time_ms_min, current_time_ls_min;
    logic [3:0] alarm_time_ms_hr,  alarm_time_ls_hr,  alarm_time_ms_min,  alarm_time_ls_min;
    logic [3:0] key_buffer_ms_hr,  key_buffer_ls_hr,  key_buffer_ms_min,  key_buffer_ls_min;
 
    aclk_timegen u_timegen (
        .clk(clk), 
        .reset(reset), 
        .reset_count(reset_count), 
        .fast_watch(fast_watch),
        .one_minute(one_minute), 
        .one_second(one_second)
    );
 
    aclk_controller u_controller (
        .clk(clk), 
        .reset(reset), 
        .one_second(one_second),
        .alarm_button(alarm_button), 
        .time_button(time_button), 
        .key(key),
        .reset_count(reset_count), 
        .load_new_c(load_new_c),
        .show_new_time(show_new_time), 
        .show_a(show_a),
        .load_new_a(load_new_a), 
        .shift(shift)
    );
 
    aclk_keyreg u_keyreg (
        .clk(clk), 
        .reset(reset), 
        .key(key), 
        .shift(shift),
        .key_buffer_ms_hr(key_buffer_ms_hr), 
        .key_buffer_ls_hr(key_buffer_ls_hr),
        .key_buffer_ms_min(key_buffer_ms_min), 
        .key_buffer_ls_min(key_buffer_ls_min)
    );
 
    aclk_counter u_counter (
        .clk(clk), 
        .reset(reset), 
        .one_minute(one_minute), 
        .load_new_c(load_new_c),
        .new_current_time_ms_hr(key_buffer_ms_hr), 
        .new_current_time_ms_min(key_buffer_ms_min),
        .new_current_time_ls_hr(key_buffer_ls_hr), 
        .new_current_time_ls_min(key_buffer_ls_min),
        .current_time_ms_hr(current_time_ms_hr), 
        .current_time_ms_min(current_time_ms_min),
        .current_time_ls_hr(current_time_ls_hr), 
        .current_time_ls_min(current_time_ls_min)
    );
 
    aclk_areg u_areg (
        .clk(clk), 
        .reset(reset), 
        .load_new_a(load_new_a),
        .new_alarm_ms_hr(key_buffer_ms_hr), 
        .new_alarm_ms_min(key_buffer_ms_min),
        .new_alarm_ls_hr(key_buffer_ls_hr), 
        .new_alarm_ls_min(key_buffer_ls_min),
        .alarm_time_ms_hr(alarm_time_ms_hr), 
        .alarm_time_ms_min(alarm_time_ms_min),
        .alarm_time_ls_hr(alarm_time_ls_hr), 
        .alarm_time_ls_min(alarm_time_ls_min)
    );
 
    aclk_lcd_display u_display (
        .current_time_ms_hr(current_time_ms_hr), 
        .current_time_ms_min(current_time_ms_min),
        .current_time_ls_hr(current_time_ls_hr), 
        .current_time_ls_min(current_time_ls_min),
        .alarm_time_ms_hr(alarm_time_ms_hr), 
        .alarm_time_ms_min(alarm_time_ms_min),
        .alarm_time_ls_hr(alarm_time_ls_hr), 
        .alarm_time_ls_min(alarm_time_ls_min),
        .key_ms_hr(key_buffer_ms_hr), 
        .key_ms_min(key_buffer_ms_min),
        .key_ls_hr(key_buffer_ls_hr), 
        .key_ls_min(key_buffer_ls_min),
        .show_new_time(show_new_time), 
        .show_a(show_a),
        .sound_alarm(sound_alarm),
        .display_ms_hr(display_ms_hr), 
        .display_ms_min(display_ms_min),
        .display_ls_hr(display_ls_hr), 
        .display_ls_min(display_ls_min)
    );
endmodule
