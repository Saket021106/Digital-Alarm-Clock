module aclk_timegen (
    input  logic clk,         
    input  logic reset,        
    input  logic reset_count,  
    input  logic fast_watch,   
    output logic one_minute,
    output logic one_second
);

    logic [13:0] count;

    always_ff @(posedge clk or posedge reset) begin
        if(reset) begin
            count <= 14'd0;
        end else if(reset_count) begin
            count <= 14'd0;
        end else if(count == 14'd15359) begin
            count <= 14'd0;
        end else begin
            count <= count + 14'd1;
        end
    end

    assign one_second = (count[7:0] == 8'hFF);
    assign one_minute = fast_watch ? one_second : (count == 14'd15359);

endmodule
