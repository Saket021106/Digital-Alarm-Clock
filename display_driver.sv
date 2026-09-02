module aclk_lcd_driver (
    input logic show_a,
    input logic show_new_time,
    input logic [3:0] alarm_time,
    input logic [3:0] current_time,
    input logic [3:0] key,
    output logic sound_alarm,        
    output logic [7:0] display_time  
);
    logic [3:0] digit;
 
    always_comb begin
        if (show_a && !show_new_time)
            digit = alarm_time;              
        else if (!show_a && show_new_time)
            digit = key;                    
        else
            digit = current_time;            
    end
 
    assign display_time = 8'h30 + {4'b0000, digit};
    assign sound_alarm  = (current_time == alarm_time);
endmodule

module aclk_lcd_display (
    input logic [3:0] current_time_ms_hr,
    input logic [3:0] current_time_ms_min,
    input logic [3:0] current_time_ls_hr,
    input logic [3:0] current_time_ls_min,
    input logic [3:0] alarm_time_ms_hr,
    input logic [3:0] alarm_time_ms_min,
    input logic [3:0] alarm_time_ls_hr,
    input logic [3:0] alarm_time_ls_min,
    input logic [3:0] key_ms_hr,
    input logic [3:0] key_ms_min,
    input logic [3:0] key_ls_hr,
    input logic [3:0] key_ls_min,
    input logic show_new_time,
    input logic show_a,
    output logic sound_alarm,
    output logic [7:0] display_ms_hr,
    output logic [7:0] display_ms_min,
    output logic [7:0] display_ls_hr,
    output logic [7:0] display_ls_min
);
    logic m_ms_hr, m_ls_hr, m_ms_min, m_ls_min;
 
    aclk_lcd_driver u_ms_hr (
        .show_a(show_a), 
        .show_new_time(show_new_time),
        .alarm_time(alarm_time_ms_hr), 
        .current_time(current_time_ms_hr), 
        .key(key_ms_hr),
        .sound_alarm(m_ms_hr), 
        .display_time(display_ms_hr)
    );
    aclk_lcd_driver u_ls_hr (
        .show_a(show_a), 
        .show_new_time(show_new_time),
        .alarm_time(alarm_time_ls_hr), 
        .current_time(current_time_ls_hr), 
        .key(key_ls_hr),
        .sound_alarm(m_ls_hr), 
        .display_time(display_ls_hr)
    );
    aclk_lcd_driver u_ms_min (
        .show_a(show_a), 
        .show_new_time(show_new_time),
        .alarm_time(alarm_time_ms_min), 
        .current_time(current_time_ms_min), 
        .key(key_ms_min),
        .sound_alarm(m_ms_min), 
        .display_time(display_ms_min)
    );
    aclk_lcd_driver u_ls_min (
        .show_a(show_a), 
        .show_new_time(show_new_time),
        .alarm_time(alarm_time_ls_min), 
        .current_time(current_time_ls_min), 
        .key(key_ls_min),
        .sound_alarm(m_ls_min), 
        .display_time(display_ls_min)
    );
 
    assign sound_alarm = m_ms_hr & m_ls_hr & m_ms_min & m_ls_min;
endmodule
