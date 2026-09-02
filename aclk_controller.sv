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
