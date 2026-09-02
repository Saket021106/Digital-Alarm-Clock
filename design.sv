module aclk_timegen (
    input logic clk,      
    input logic reset,      
    input logic reset_count,  
    input logic fast_watch,   
    output logic one_minute,
    output logic one_second
);
    logic [13:0] count; 
 
    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            count <= 14'd0;
        else if (reset_count)
            count <= 14'd0;
        else if (count == 14'd15359)
            count <= 14'd0;
        else
            count <= count + 14'd1;
    end
 
    assign one_second = (count[7:0] == 8'hFF);                
    assign one_minute  = fast_watch ? one_second : (count == 14'd15359);      
endmodule

module aclk_controller (
    input logic clk,
    input logic reset,
    input logic one_second,
    input logic alarm_button,
    input logic time_button,
    input logic [3:0] key,          
    output logic reset_count,
    output logic load_new_c,
    output logic show_new_time,
    output logic show_a,
    output logic load_new_a,
    output logic shift
);
    typedef enum logic [2:0] {
        SHOW_TIME, SHOW_ALARM, KEY_ENTRY, KEY_STORED, KEY_WAITED,
        SET_ALARM_TIME, SET_CURRENT_TIME
    } state_t;
 
    state_t state, next_state;
    logic [3:0] timeout_cnt;   
    logic timeout;
 
    assign timeout = (timeout_cnt >= 4'd10);
 
    // ---- state register ----
    always_ff @(posedge clk or posedge reset) begin
        if (reset) state <= SHOW_TIME;
        else state <= next_state;
    end
 
    // ---- 10-second key-entry timeout counter ----
    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            timeout_cnt <= 4'd0;
        else if (state == SHOW_TIME)
            timeout_cnt <= 4'd0;                 
        else if (state == KEY_STORED)
            timeout_cnt <= 4'd0;                 
        else if ((state == KEY_ENTRY || state == KEY_WAITED) && one_second)
            timeout_cnt <= timeout_cnt + 4'd1;
    end
 
    // ---- next-state logic ----
    always_comb begin
        next_state = state;
        case (state)
            SHOW_TIME: begin
                if (alarm_button) next_state = SHOW_ALARM;
                else if (key != 4'd10) next_state = KEY_STORED;
            end
 
            SHOW_ALARM: begin
                if (!alarm_button) next_state = SHOW_TIME;
            end
 
            KEY_STORED: begin
                next_state = KEY_WAITED;          
            end
 
            KEY_WAITED: begin
                if (timeout) next_state = SHOW_TIME;
                else if (key == 4'd10) next_state = KEY_ENTRY;   
            end
 
            KEY_ENTRY: begin
                if (alarm_button) next_state = SET_ALARM_TIME;
                else if (time_button) next_state = SET_CURRENT_TIME;
                else if (key != 4'd10) next_state = KEY_STORED;
                else if (timeout) next_state = SHOW_TIME;
            end
 
            SET_ALARM_TIME: begin
                next_state = SHOW_ALARM;          
            end
 
            SET_CURRENT_TIME: begin
                next_state = SHOW_TIME;           
            end
 
            default: next_state = SHOW_TIME;
        endcase
    end
 
    // ---- Moore outputs (function of current state only) ----
    always_comb begin
        reset_count = (state == SET_CURRENT_TIME);
        load_new_c = (state == SET_CURRENT_TIME);
        load_new_a = (state == SET_ALARM_TIME);
        show_a = (state == SHOW_ALARM);
        show_new_time = (state == KEY_ENTRY) || (state == KEY_STORED) || (state == KEY_WAITED);
        shift = (state == KEY_STORED);
    end
endmodule

module aclk_keyreg (
    input logic clk,
    input logic reset,
    input logic [3:0] key,
    input logic shift,
    output logic [3:0] key_buffer_ms_hr,
    output logic [3:0] key_buffer_ls_hr,
    output logic [3:0] key_buffer_ms_min,
    output logic [3:0] key_buffer_ls_min
);
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            key_buffer_ms_hr <= 4'd0;
            key_buffer_ls_hr <= 4'd0;
            key_buffer_ms_min <= 4'd0;
            key_buffer_ls_min <= 4'd0;
        end else if (shift) begin
            key_buffer_ms_hr <= key_buffer_ls_hr;
            key_buffer_ls_hr <= key_buffer_ms_min;
            key_buffer_ms_min <= key_buffer_ls_min;
            key_buffer_ls_min <= key;
        end
    end
endmodule

module aclk_areg (
    input logic clk,
    input logic reset,
    input logic load_new_a,
    input logic [3:0] new_alarm_ms_hr,
    input logic [3:0] new_alarm_ms_min,
    input logic [3:0] new_alarm_ls_hr,
    input logic [3:0] new_alarm_ls_min,
    output logic [3:0] alarm_time_ms_hr,
    output logic [3:0] alarm_time_ms_min,
    output logic [3:0] alarm_time_ls_hr,
    output logic [3:0] alarm_time_ls_min
);
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            alarm_time_ms_hr <= 4'd0;
            alarm_time_ms_min <= 4'd0;
            alarm_time_ls_hr <= 4'd0;
            alarm_time_ls_min <= 4'd0;
        end else if (load_new_a) begin
            alarm_time_ms_hr <= new_alarm_ms_hr;
            alarm_time_ms_min <= new_alarm_ms_min;
            alarm_time_ls_hr <= new_alarm_ls_hr;
            alarm_time_ls_min <= new_alarm_ls_min;
        end
    end
endmodule

module aclk_counter (
    input logic clk,
    input logic reset,
    input logic one_minute,
    input logic load_new_c,
    input logic [3:0] new_current_time_ms_hr,
    input logic [3:0] new_current_time_ms_min,
    input logic [3:0] new_current_time_ls_hr,
    input logic [3:0] new_current_time_ls_min,
    output logic [3:0] current_time_ms_hr,
    output logic [3:0] current_time_ms_min,
    output logic [3:0] current_time_ls_hr,
    output logic [3:0] current_time_ls_min
);
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            current_time_ms_hr <= 4'd0;
            current_time_ms_min <= 4'd0;
            current_time_ls_hr <= 4'd0;
            current_time_ls_min <= 4'd0;
        end else if (load_new_c) begin
            current_time_ms_hr <= new_current_time_ms_hr;
            current_time_ms_min <= new_current_time_ms_min;
            current_time_ls_hr <= new_current_time_ls_hr;
            current_time_ls_min <= new_current_time_ls_min;
        end else if (one_minute) begin
            if (current_time_ms_hr == 4'd2 && current_time_ls_hr == 4'd3 && current_time_ms_min == 4'd5 && current_time_ls_min == 4'd9) begin
                current_time_ms_hr <= 4'd0;
                current_time_ls_hr <= 4'd0;
                current_time_ms_min <= 4'd0;
                current_time_ls_min <= 4'd0;
            end else if (current_time_ls_hr == 4'd9 && current_time_ms_min == 4'd5 && current_time_ls_min == 4'd9) begin
                current_time_ms_hr <= current_time_ms_hr + 4'd1;
                current_time_ls_hr <= 4'd0;
                current_time_ms_min <= 4'd0;
                current_time_ls_min <= 4'd0;
            end else if (current_time_ms_min == 4'd5 && current_time_ls_min == 4'd9) begin
                current_time_ls_hr <= current_time_ls_hr + 4'd1;
                current_time_ms_min <= 4'd0;
                current_time_ls_min <= 4'd0;
            end else if (current_time_ls_min == 4'd9) begin
                current_time_ms_min <= current_time_ms_min + 4'd1;
                current_time_ls_min <= 4'd0;
            end else begin
                current_time_ls_min <= current_time_ls_min + 4'd1;
            end
        end
    end
endmodule

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
