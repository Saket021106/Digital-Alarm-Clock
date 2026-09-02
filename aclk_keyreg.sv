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
