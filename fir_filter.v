module fir_filter #(
    parameter DATA_WIDTH = 8   // width of input/output samples
)(
    input                               clk,
    input                               rst_n,     // active-low synchronous reset
    input                               valid_in,  // new input sample available
    input  signed [DATA_WIDTH-1:0]      data_in,   // input sample x[n]

    output reg                          valid_out, // output sample available
    output reg  signed [DATA_WIDTH-1:0] data_out   // filtered output y[n]
);

    // ---------------------------------------------------------
    // Fixed filter coefficients
    // ---------------------------------------------------------
    localparam signed [3:0] H0 = 4'sd1;
    localparam signed [3:0] H1 = 4'sd3;
    localparam signed [3:0] H2 = 4'sd3;
    localparam signed [3:0] H3 = 4'sd1;

    // ---------------------------------------------------------
    // History registers: hold x[n-1], x[n-2], x[n-3]
    // (x[n] itself arrives live on data_in this cycle)
    // ---------------------------------------------------------
    reg signed [DATA_WIDTH-1:0] xm1, xm2, xm3;

    // Combinational taps for this cycle's convolution
    wire signed [DATA_WIDTH-1:0] tap0 = data_in; // x[n]
    wire signed [DATA_WIDTH-1:0] tap1 = xm1;     // x[n-1]
    wire signed [DATA_WIDTH-1:0] tap2 = xm2;     // x[n-2]
    wire signed [DATA_WIDTH-1:0] tap3 = xm3;     // x[n-3]

    // Products need extra headroom: DATA_WIDTH + coeff width
    wire signed [DATA_WIDTH+3:0] p0 = tap0 * H0;
    wire signed [DATA_WIDTH+3:0] p1 = tap1 * H1;
    wire signed [DATA_WIDTH+3:0] p2 = tap2 * H2;
    wire signed [DATA_WIDTH+3:0] p3 = tap3 * H3;

    wire signed [DATA_WIDTH+5:0] sum = p0 + p1 + p2 + p3; // guard bits

    // ---------------------------------------------------------
    // Sequential logic: history shift + registered output
    // ---------------------------------------------------------
    always @(posedge clk) begin
        if (!rst_n) begin
            xm1 <= {DATA_WIDTH{1'b0}};
            xm2 <= {DATA_WIDTH{1'b0}};
            xm3 <= {DATA_WIDTH{1'b0}};
            data_out  <= {DATA_WIDTH{1'b0}};
            valid_out <= 1'b0;
        end else begin
            valid_out <= valid_in;   // 1-cycle output latency

            if (valid_in) begin
                // arithmetic right shift by 3 = divide by 8, sign-preserving
                data_out <= sum[DATA_WIDTH+4:3];

                // push history: x[n] becomes x[n-1] next cycle, etc.
                xm3 <= xm2;
                xm2 <= xm1;
                xm1 <= data_in;
            end
        end
    end

endmodule