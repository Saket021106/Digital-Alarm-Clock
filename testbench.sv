`timescale 1ns/1ps

module testbench;

    logic clk, reset, alarm_button, time_button, fast_watch;
    logic [3:0] key;
    logic sound_alarm;
    logic [7:0] display_ms_hr, display_ls_hr, display_ms_min, display_ls_min;

    // ---- DUT ----
    alarm_clk_rtl dut (
        .clk(clk),
        .reset(reset),
        .alarm_button(alarm_button),
        .time_button(time_button),
        .key(key),
        .fast_watch(fast_watch),
        .sound_alarm(sound_alarm),
        .display_ms_hr(display_ms_hr),
        .display_ls_hr(display_ls_hr),
        .display_ms_min(display_ms_min),
        .display_ls_min(display_ls_min)
    );

    // ---- 256 Hz clock, scaled for simulation (20ns period) ----
    initial clk = 1'b0;
    always #10 clk = ~clk;

    // Press one digit key, then release back to "no key" (10).
    //   - key is held across 2 posedges: the 1st moves
    //     SHOW_TIME/KEY_ENTRY -> KEY_STORED, the 2nd is the cycle the
    //     shift register actually captures the digit.
    //   - key is then released and 2 more posedges let
    //     KEY_STORED -> KEY_WAITED -> KEY_ENTRY settle before the next
    //     key can be accepted.
    task automatic press_key(input [3:0] k);
        begin
            @(negedge clk); key = k;
            repeat (2) @(posedge clk);
            @(negedge clk); key = 4'd10;      // release / "no key"
            repeat (2) @(posedge clk);
        end
    endtask

    // Enter all four digits in order MS_HR, LS_HR, MS_MIN, LS_MIN
    // (matches the shift order described in the spec).
    task automatic enter_digits(input [3:0] d_ms_hr, d_ls_hr, d_ms_min, d_ls_min);
        begin
            press_key(d_ms_hr);
            press_key(d_ls_hr);
            press_key(d_ms_min);
            press_key(d_ls_min);
        end
    endtask

    task automatic pulse_time_button();
        begin
            @(negedge clk); time_button = 1'b1;
            @(posedge clk);
            @(negedge clk); time_button = 1'b0;
            repeat (3) @(posedge clk);
        end
    endtask

    // Pulses alarm_button and HOLDS it for a few extra cycles so the
    // caller can observe the alarm time on display before it's released
    // (SHOW_ALARM only lasts while alarm_button is held -- see FSM notes
    // in design.sv).
    task automatic pulse_alarm_button();
        begin
            @(negedge clk); alarm_button = 1'b1;
            repeat (6) @(posedge clk);
            @(negedge clk); alarm_button = 1'b0;
            repeat (3) @(posedge clk);
        end
    endtask

    task automatic print_display(input string label);
        begin
            $display("%s : %c%c:%c%c   (sound_alarm=%b)",
                      label, display_ms_hr, display_ls_hr,
                      display_ms_min, display_ls_min, sound_alarm);
        end
    endtask

    initial begin
        $dumpfile("alarm_clk.vcd");
        $dumpvars(0, testbench);

        reset        = 1'b1;
        alarm_button = 1'b0;
        time_button  = 1'b0;
        key          = 4'd10;   // no key pressed
        fast_watch   = 1'b1;    // speed up simulation: one_minute = one_second
        repeat (5) @(posedge clk);
        @(negedge clk); reset = 1'b0;
        repeat (5) @(posedge clk);

        print_display("After reset       ");

        // ---- TEST 1: set current time to 09:43 ----
        $display("\n--- TEST 1: set current time to 09:43 ---");
        enter_digits(4'd0, 4'd9, 4'd4, 4'd3);
        pulse_time_button();
        repeat (5) @(posedge clk);
        print_display("Expect 09:43      ");

        // ---- TEST 2: set alarm time to 09:44 ----
        $display("\n--- TEST 2: set alarm time to 09:44 ---");
        enter_digits(4'd0, 4'd9, 4'd4, 4'd4);
        @(negedge clk); alarm_button = 1'b1;
        repeat (6) @(posedge clk);
        print_display("Expect 09:44, show_a active");   // alarm_button still held here
        @(negedge clk); alarm_button = 1'b0;
        repeat (5) @(posedge clk);
        print_display("Released -> back to current");

        // ---- TEST 3: run the clock until it rolls from :43 to :44 ----
        $display("\n--- TEST 3: run clock (fast_watch) until alarm matches ---");
        // one_second/one_minute pulse every 256 clk cycles regardless of
        // fast_watch; fast_watch just makes one_minute follow one_second.
        // 300 cycles > 256, guaranteeing at least one minute tick.
        repeat (300) @(posedge clk);
        print_display("Expect 09:44, sound_alarm=1");

        // ---- TEST 4: show alarm time on demand ----
        $display("\n--- TEST 4: press alarm_button to view alarm time ---");
        @(negedge clk); alarm_button = 1'b1;
        repeat (3) @(posedge clk);
        print_display("Showing alarm time");
        @(negedge clk); alarm_button = 1'b0;
        repeat (3) @(posedge clk);
        print_display("Back to current   ");

        $display("\nAll tests complete.");
        $finish;
    end

endmodule
