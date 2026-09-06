`timescale 1ns / 1ps

module tb_fir_filter;

    localparam DATA_WIDTH = 8;
    localparam CLK_PERIOD = 10;

    reg                          clk;
    reg                          rst_n;
    reg                          valid_in;
    reg  signed [DATA_WIDTH-1:0] data_in;

    wire                         valid_out;
    wire signed [DATA_WIDTH-1:0] data_out;

    integer i;

    // ---------------------------------------------------------
    // DUT instantiation
    // ---------------------------------------------------------
    fir_filter #(
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .valid_in  (valid_in),
        .data_in   (data_in),
        .valid_out (valid_out),
        .data_out  (data_out)
    );

    // ---------------------------------------------------------
    // Clock generation
    // ---------------------------------------------------------
    initial clk = 1'b0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // ---------------------------------------------------------
    // Helper task: apply one sample on the rising edge
    // ---------------------------------------------------------
    task apply_sample(input signed [DATA_WIDTH-1:0] val);
        begin
            @(negedge clk);
            data_in  = val;
            valid_in = 1'b1;
            @(negedge clk);
            valid_in = 1'b0;
        end
    endtask

    // ---------------------------------------------------------
    // Stimulus
    // ---------------------------------------------------------
    initial begin
        $dumpfile("fir_filter.vcd");
        $dumpvars(0, tb_fir_filter);

        rst_n    = 1'b0;
        valid_in = 1'b0;
        data_in  = 0;

        repeat (2) @(negedge clk);
        rst_n = 1'b1;

        $display("time\tx_in\tvalid_in\ty_out\tvalid_out");

        // ---------------- Test 1: Impulse response ----------------
        $display("\n--- Test 1: Impulse response ---");
        apply_sample(8'sd16);   // single impulse of height 16
        repeat (5) apply_sample(8'sd0);

        repeat (2) @(negedge clk);

        // ---------------- Test 2: Step response ----------------
        $display("\n--- Test 2: Step response ---");
        repeat (6) apply_sample(8'sd10);  // constant input of 10

        repeat (2) @(negedge clk);

        // ---------------- Test 3: Oscillating / noisy input ----------------
        $display("\n--- Test 3: Oscillating input (smoothing demo) ---");
        // Alternating +20 / -20 : high-frequency signal that a
        // low-pass FIR should attenuate strongly.
        for (i = 0; i < 8; i = i + 1) begin
            if (i % 2 == 0)
                apply_sample(8'sd20);
            else
                apply_sample(-8'sd20);
        end

        repeat (4) @(negedge clk);
        $display("\nSimulation complete.");
        $finish;
    end

    // ---------------------------------------------------------
    // Monitor
    // ---------------------------------------------------------
    always @(posedge clk) begin
        if (rst_n)
            $display("%0t\t%0d\t%0b\t%0d\t%0b",
                      $time, data_in, valid_in, data_out, valid_out);
    end

endmodule