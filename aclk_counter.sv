module aclk_counter (
    input  logic clk,
    input  logic reset,
    input  logic one_minute,
    input  logic load_new_c,
    input  logic [3:0] new_current_time_ms_hr,
    input  logic [3:0] new_current_time_ms_min,
    input  logic [3:0] new_current_time_ls_hr,
    input  logic [3:0] new_current_time_ls_min,
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
