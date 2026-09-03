`include "hvsync_generator.v"

module top (
    input clk,
    output wire hsync,
    output wire vsync,
    output wire [2:0] rgb
);

    wire display_on;
    wire [9:0] hpos;
    wire [9:0] vpos;

    // 1. Generate CRT video timing signals
    hvsync_generator hvsync_gen(
        .clk(clk),
        .reset(1'b0),
        .hsync(hsync),
        .vsync(vsync),
        .hpos(hpos),
        .vpos(vpos),
        .display_on(display_on)
    );

    // 2. Slow down the clock for visibility (approximates ~1.5 Hz)
    reg [23:0] clk_div = 0;
    always @(posedge clk) begin
        clk_div <= clk_div + 1;
    end
    wire slow_clk = clk_div[23];

    // 3. Instantiate the Full Clock Logic
    wire [3:0] Q_out_1, Q_out_2, Q_out_3, Q_out_4, Q_out_5, Q_out_6;
    wire [6:0] s_0, s_1, m_0, m_1, h_0, h_1;

    seven_segment_display my_clock (
        .clk(slow_clk), 
        .Q_out_1(Q_out_1), .Q_out_2(Q_out_2), 
        .Q_out_3(Q_out_3), .Q_out_4(Q_out_4), 
        .Q_out_5(Q_out_5), .Q_out_6(Q_out_6), 
        .s_0(s_0), .s_1(s_1),
        .m_0(m_0), .m_1(m_1),
        .h_0(h_0), .h_1(h_1)
    );

    // 4. Map the 6 digits across the screen geometry (HH : MM : SS)
    
    // HOURS (Tens) - Base X: 50
    wire h1_a = h_1[0] && (hpos >= 50 && hpos <= 100 && vpos >= 60  && vpos <= 70);
    wire h1_b = h_1[1] && (hpos >= 90 && hpos <= 100 && vpos >= 70  && vpos <= 115);
    wire h1_c = h_1[2] && (hpos >= 90 && hpos <= 100 && vpos >= 125 && vpos <= 170);
    wire h1_d = h_1[3] && (hpos >= 50 && hpos <= 100 && vpos >= 170 && vpos <= 180);
    wire h1_e = h_1[4] && (hpos >= 50 && hpos <= 60  && vpos >= 125 && vpos <= 170);
    wire h1_f = h_1[5] && (hpos >= 50 && hpos <= 60  && vpos >= 70  && vpos <= 115);
    wire h1_g = h_1[6] && (hpos >= 50 && hpos <= 100 && vpos >= 115 && vpos <= 125);
    wire draw_h1 = h1_a | h1_b | h1_c | h1_d | h1_e | h1_f | h1_g;

    // HOURS (Ones) - Base X: 120
    wire h0_a = h_0[0] && (hpos >= 120 && hpos <= 170 && vpos >= 60  && vpos <= 70);
    wire h0_b = h_0[1] && (hpos >= 160 && hpos <= 170 && vpos >= 70  && vpos <= 115);
    wire h0_c = h_0[2] && (hpos >= 160 && hpos <= 170 && vpos >= 125 && vpos <= 170);
    wire h0_d = h_0[3] && (hpos >= 120 && hpos <= 170 && vpos >= 170 && vpos <= 180);
    wire h0_e = h_0[4] && (hpos >= 120 && hpos <= 130 && vpos >= 125 && vpos <= 170);
    wire h0_f = h_0[5] && (hpos >= 120 && hpos <= 130 && vpos >= 70  && vpos <= 115);
    wire h0_g = h_0[6] && (hpos >= 120 && hpos <= 170 && vpos >= 115 && vpos <= 125);
    wire draw_h0 = h0_a | h0_b | h0_c | h0_d | h0_e | h0_f | h0_g;

    // COLON 1 - X: 190-200
    wire col1 = (hpos >= 190 && hpos <= 200) && ((vpos >= 90 && vpos <= 100) || (vpos >= 140 && vpos <= 150));

    // MINUTES (Tens) - Base X: 220
    wire m1_a = m_1[0] && (hpos >= 220 && hpos <= 270 && vpos >= 60  && vpos <= 70);
    wire m1_b = m_1[1] && (hpos >= 260 && hpos <= 270 && vpos >= 70  && vpos <= 115);
    wire m1_c = m_1[2] && (hpos >= 260 && hpos <= 270 && vpos >= 125 && vpos <= 170);
    wire m1_d = m_1[3] && (hpos >= 220 && hpos <= 270 && vpos >= 170 && vpos <= 180);
    wire m1_e = m_1[4] && (hpos >= 220 && hpos <= 230 && vpos >= 125 && vpos <= 170);
    wire m1_f = m_1[5] && (hpos >= 220 && hpos <= 230 && vpos >= 70  && vpos <= 115);
    wire m1_g = m_1[6] && (hpos >= 220 && hpos <= 270 && vpos >= 115 && vpos <= 125);
    wire draw_m1 = m1_a | m1_b | m1_c | m1_d | m1_e | m1_f | m1_g;

    // MINUTES (Ones) - Base X: 290
    wire m0_a = m_0[0] && (hpos >= 290 && hpos <= 340 && vpos >= 60  && vpos <= 70);
    wire m0_b = m_0[1] && (hpos >= 330 && hpos <= 340 && vpos >= 70  && vpos <= 115);
    wire m0_c = m_0[2] && (hpos >= 330 && hpos <= 340 && vpos >= 125 && vpos <= 170);
    wire m0_d = m_0[3] && (hpos >= 290 && hpos <= 340 && vpos >= 170 && vpos <= 180);
    wire m0_e = m_0[4] && (hpos >= 290 && hpos <= 300 && vpos >= 125 && vpos <= 170);
    wire m0_f = m_0[5] && (hpos >= 290 && hpos <= 300 && vpos >= 70  && vpos <= 115);
    wire m0_g = m_0[6] && (hpos >= 290 && hpos <= 340 && vpos >= 115 && vpos <= 125);
    wire draw_m0 = m0_a | m0_b | m0_c | m0_d | m0_e | m0_f | m0_g;

    // COLON 2 - X: 360-370
    wire col2 = (hpos >= 360 && hpos <= 370) && ((vpos >= 90 && vpos <= 100) || (vpos >= 140 && vpos <= 150));

    // SECONDS (Tens) - Base X: 390
    wire s1_a = s_1[0] && (hpos >= 390 && hpos <= 440 && vpos >= 60  && vpos <= 70);
    wire s1_b = s_1[1] && (hpos >= 430 && hpos <= 440 && vpos >= 70  && vpos <= 115);
    wire s1_c = s_1[2] && (hpos >= 430 && hpos <= 440 && vpos >= 125 && vpos <= 170);
    wire s1_d = s_1[3] && (hpos >= 390 && hpos <= 440 && vpos >= 170 && vpos <= 180);
    wire s1_e = s_1[4] && (hpos >= 390 && hpos <= 400 && vpos >= 125 && vpos <= 170);
    wire s1_f = s_1[5] && (hpos >= 390 && hpos <= 400 && vpos >= 70  && vpos <= 115);
    wire s1_g = s_1[6] && (hpos >= 390 && hpos <= 440 && vpos >= 115 && vpos <= 125);
    wire draw_s1 = s1_a | s1_b | s1_c | s1_d | s1_e | s1_f | s1_g;

    // SECONDS (Ones) - Base X: 460
    wire s0_a = s_0[0] && (hpos >= 460 && hpos <= 510 && vpos >= 60  && vpos <= 70);
    wire s0_b = s_0[1] && (hpos >= 500 && hpos <= 510 && vpos >= 70  && vpos <= 115);
    wire s0_c = s_0[2] && (hpos >= 500 && hpos <= 510 && vpos >= 125 && vpos <= 170);
    wire s0_d = s_0[3] && (hpos >= 460 && hpos <= 510 && vpos >= 170 && vpos <= 180);
    wire s0_e = s_0[4] && (hpos >= 460 && hpos <= 470 && vpos >= 125 && vpos <= 170);
    wire s0_f = s_0[5] && (hpos >= 460 && hpos <= 470 && vpos >= 70  && vpos <= 115);
    wire s0_g = s_0[6] && (hpos >= 460 && hpos <= 510 && vpos >= 115 && vpos <= 125);
    wire draw_s0 = s0_a | s0_b | s0_c | s0_d | s0_e | s0_f | s0_g;

    // 5. Output white pixels when CRT beam hits any active segment or colon
    wire draw_any = draw_h1 | draw_h0 | col1 | draw_m1 | draw_m0 | col2 | draw_s1 | draw_s0;
    assign rgb = (display_on && draw_any) ? 3'b111 : 3'b000;

endmodule

// ==========================================
// Full 24-Hour Clock Logic
// ==========================================

module seven_segment_display (
    input clk,
    output [3:0] Q_out_1, output [3:0] Q_out_2, 
    output [3:0] Q_out_3, output [3:0] Q_out_4, 
    output [3:0] Q_out_5, output [3:0] Q_out_6, 
    output [6:0] s_0, output [6:0] s_1,
    output [6:0] m_0, output [6:0] m_1,
    output [6:0] h_0, output [6:0] h_1
);

    reg [3:0] Sec_0 = 4'd0; reg [3:0] Sec_1 = 4'd0;
    reg [3:0] Min_0 = 4'd0; reg [3:0] Min_1 = 4'd0;
    reg [3:0] Hr_0 = 4'd0;  reg [3:0] Hr_1 = 4'd0;

    assign Q_out_1 = Sec_0; assign Q_out_2 = Sec_1;
    assign Q_out_3 = Min_0; assign Q_out_4 = Min_1;
    assign Q_out_5 = Hr_0;  assign Q_out_6 = Hr_1;

    assign s_0[0] = Sec_0[3] | Sec_0[1] | (Sec_0[2] & Sec_0[0]) | (~Sec_0[2] & ~Sec_0[0]);
    assign s_0[1] = ~Sec_0[2] | (~Sec_0[1] & ~Sec_0[0]) | (Sec_0[1] & Sec_0[0]);
    assign s_0[2] = Sec_0[2] | ~Sec_0[1] | Sec_0[0];
    assign s_0[3] = Sec_0[3] | (~Sec_0[2] & ~Sec_0[0]) | (~Sec_0[2] & Sec_0[1]) | (Sec_0[1] & ~Sec_0[0]) | (Sec_0[2] & ~Sec_0[1] & Sec_0[0]);
    assign s_0[4] = (~Sec_0[2] & ~Sec_0[0]) | (Sec_0[1] & ~Sec_0[0]);
    assign s_0[5] = Sec_0[3] | (Sec_0[2] & ~Sec_0[1]) | (Sec_0[2] & ~Sec_0[0]) | (~Sec_0[1] & ~Sec_0[0]);
    assign s_0[6] = Sec_0[3] | (Sec_0[2] & ~Sec_0[1]) | (~Sec_0[2] & Sec_0[1]) | (Sec_0[1] & ~Sec_0[0]);

    assign s_1[0] = Sec_1[3] | Sec_1[1] | (Sec_1[2] & Sec_1[0]) | (~Sec_1[2] & ~Sec_1[0]);
    assign s_1[1] = ~Sec_1[2] | (~Sec_1[1] & ~Sec_1[0]) | (Sec_1[1] & Sec_1[0]);
    assign s_1[2] = Sec_1[2] | ~Sec_1[1] | Sec_1[0];
    assign s_1[3] = Sec_1[3] | (~Sec_1[2] & ~Sec_1[0]) | (~Sec_1[2] & Sec_1[1]) | (Sec_1[1] & ~Sec_1[0]) | (Sec_1[2] & ~Sec_1[1] & Sec_1[0]);
    assign s_1[4] = (~Sec_1[2] & ~Sec_1[0]) | (Sec_1[1] & ~Sec_1[0]);
    assign s_1[5] = Sec_1[3] | (Sec_1[2] & ~Sec_1[1]) | (Sec_1[2] & ~Sec_1[0]) | (~Sec_1[1] & ~Sec_1[0]);
    assign s_1[6] = Sec_1[3] | (Sec_1[2] & ~Sec_1[1]) | (~Sec_1[2] & Sec_1[1]) | (Sec_1[1] & ~Sec_1[0]);

    assign m_0[0] = Min_0[3] | Min_0[1] | (Min_0[2] & Min_0[0]) | (~Min_0[2] & ~Min_0[0]);
    assign m_0[1] = ~Min_0[2] | (~Min_0[1] & ~Min_0[0]) | (Min_0[1] & Min_0[0]);
    assign m_0[2] = Min_0[2] | ~Min_0[1] | Min_0[0];
    assign m_0[3] = Min_0[3] | (~Min_0[2] & ~Min_0[0]) | (~Min_0[2] & Min_0[1]) | (Min_0[1] & ~Min_0[0]) | (Min_0[2] & ~Min_0[1] & Min_0[0]);
    assign m_0[4] = (~Min_0[2] & ~Min_0[0]) | (Min_0[1] & ~Min_0[0]);
    assign m_0[5] = Min_0[3] | (Min_0[2] & ~Min_0[1]) | (Min_0[2] & ~Min_0[0]) | (~Min_0[1] & ~Min_0[0]);
    assign m_0[6] = Min_0[3] | (Min_0[2] & ~Min_0[1]) | (~Min_0[2] & Min_0[1]) | (Min_0[1] & ~Min_0[0]);

    assign m_1[0] = Min_1[3] | Min_1[1] | (Min_1[2] & Min_1[0]) | (~Min_1[2] & ~Min_1[0]);
    assign m_1[1] = ~Min_1[2] | (~Min_1[1] & ~Min_1[0]) | (Min_1[1] & Min_1[0]);
    assign m_1[2] = Min_1[2] | ~Min_1[1] | Min_1[0];
    assign m_1[3] = Min_1[3] | (~Min_1[2] & ~Min_1[0]) | (~Min_1[2] & Min_1[1]) | (Min_1[1] & ~Min_1[0]) | (Min_1[2] & ~Min_1[1] & Min_1[0]);
    assign m_1[4] = (~Min_1[2] & ~Min_1[0]) | (Min_1[1] & ~Min_1[0]);
    assign m_1[5] = Min_1[3] | (Min_1[2] & ~Min_1[1]) | (Min_1[2] & ~Min_1[0]) | (~Min_1[1] & ~Min_1[0]);
    assign m_1[6] = Min_1[3] | (Min_1[2] & ~Min_1[1]) | (~Min_1[2] & Min_1[1]) | (Min_1[1] & ~Min_1[0]);

    assign h_0[0] = Hr_0[3] | Hr_0[1] | (Hr_0[2] & Hr_0[0]) | (~Hr_0[2] & ~Hr_0[0]);
    assign h_0[1] = ~Hr_0[2] | (~Hr_0[1] & ~Hr_0[0]) | (Hr_0[1] & Hr_0[0]);
    assign h_0[2] = Hr_0[2] | ~Hr_0[1] | Hr_0[0];
    assign h_0[3] = Hr_0[3] | (~Hr_0[2] & ~Hr_0[0]) | (~Hr_0[2] & Hr_0[1]) | (Hr_0[1] & ~Hr_0[0]) | (Hr_0[2] & ~Hr_0[1] & Hr_0[0]);
    assign h_0[4] = (~Hr_0[2] & ~Hr_0[0]) | (Hr_0[1] & ~Hr_0[0]);
    assign h_0[5] = Hr_0[3] | (Hr_0[2] & ~Hr_0[1]) | (Hr_0[2] & ~Hr_0[0]) | (~Hr_0[1] & ~Hr_0[0]);
    assign h_0[6] = Hr_0[3] | (Hr_0[2] & ~Hr_0[1]) | (~Hr_0[2] & Hr_0[1]) | (Hr_0[1] & ~Hr_0[0]);

    assign h_1[0] = Hr_1[3] | Hr_1[1] | (Hr_1[2] & Hr_1[0]) | (~Hr_1[2] & ~Hr_1[0]);
    assign h_1[1] = ~Hr_1[2] | (~Hr_1[1] & ~Hr_1[0]) | (Hr_1[1] & Hr_1[0]);
    assign h_1[2] = Hr_1[2] | ~Hr_1[1] | Hr_1[0];
    assign h_1[3] = Hr_1[3] | (~Hr_1[2] & ~Hr_1[0]) | (~Hr_1[2] & Hr_1[1]) | (Hr_1[1] & ~Hr_1[0]) | (Hr_1[2] & ~Hr_1[1] & Hr_1[0]);
    assign h_1[4] = (~Hr_1[2] & ~Hr_1[0]) | (Hr_1[1] & ~Hr_1[0]);
    assign h_1[5] = Hr_1[3] | (Hr_1[2] & ~Hr_1[1]) | (Hr_1[2] & ~Hr_1[0]) | (~Hr_1[1] & ~Hr_1[0]);
    assign h_1[6] = Hr_1[3] | (Hr_1[2] & ~Hr_1[1]) | (~Hr_1[2] & Hr_1[1]) | (Hr_1[1] & ~Hr_1[0]);

    always @(posedge clk) begin
        if(Hr_1 == 4'd2 && Hr_0 == 4'd3 && Min_1 == 4'd5 && Min_0 == 4'd9 && Sec_1 == 4'd5 && Sec_0 == 4'd9) begin
            Hr_1 <= 4'd0; Hr_0 <= 4'd0;
            Min_1 <= 4'd0; Min_0 <= 4'd0;
            Sec_1 <= 4'd0; Sec_0 <= 4'd0;
        end else if(Min_1 == 4'd5 && Min_0 == 4'd9 && Sec_1 == 4'd5 && Sec_0 == 4'd9) begin
            Min_1 <= 4'd0; Min_0 <= 4'd0;
            Sec_1 <= 4'd0; Sec_0 <= 4'd0;
            if(Hr_0 == 4'd9) begin
                Hr_0 <= 4'd0; Hr_1 <= Hr_1 + 1'b1;
            end else begin
                Hr_0 <= Hr_0 + 1'b1;
            end
        end else if(Sec_1 == 4'd5 && Sec_0 == 4'd9) begin
            Sec_1 <= 4'd0; Sec_0 <= 4'd0;
            if(Min_0 == 4'd9) begin
                Min_0 <= 4'd0; Min_1 <= Min_1 + 1'b1;
            end else begin
                Min_0 <= Min_0 + 1'b1;
            end
        end else if(Sec_0 == 4'd9) begin
            Sec_0 <= 4'd0; Sec_1 <= Sec_1 + 1'b1;
        end else begin
            Sec_0 <= Sec_0 + 1'b1;
        end
    end

endmodule
