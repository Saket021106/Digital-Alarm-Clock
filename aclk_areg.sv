module aclk_areg (
    input  logic clk,
    input  logic reset,
    input  logic load_new_a,
    input  logic [3:0] new_alarm_ms_hr,
    input  logic [3:0] new_alarm_ms_min,
    input  logic [3:0] new_alarm_ls_hr,
    input  logic [3:0] new_alarm_ls_min,
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
