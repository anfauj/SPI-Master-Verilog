`timescale 1ns / 1ps

module tb_spi_master;

    parameter TEST_WIDTH = 16;
    parameter TEST_DIV   = 8;

    reg clk;
    reg rst_n;
    reg start;
    reg [TEST_WIDTH-1:0] tx_data;
    reg miso;
    reg cpol;
    reg cpha;

    wire sclk;
    wire mosi;
    wire cs_n;
    wire [TEST_WIDTH-1:0] rx_data;
    wire done;

    spi_master #(
        .DATA_WIDTH(TEST_WIDTH),
        .CLOCK_DIV_RATIO(TEST_DIV)
    ) uut (
        .clk(clk),     .rst_n(rst_n), .start(start), .tx_data(tx_data),
        .miso(miso),   .cpol(cpol),   .cpha(cpha),   .sclk(sclk),
        .mosi(mosi),   .cs_n(cs_n),   .rx_data(rx_data), .done(done)
    );

    always #10 clk = ~clk;

    reg [TEST_WIDTH-1:0] slave_tx_reg;
    reg [TEST_WIDTH-1:0] slave_rx_reg;

    always @(posedge sclk) begin
        if (!cs_n) slave_rx_reg <= {slave_rx_reg[TEST_WIDTH-2:0], mosi};
    end

    always @(negedge sclk or negedge cs_n) begin
        if (!cs_n) begin
            miso <= slave_tx_reg[TEST_WIDTH-1];
            slave_tx_reg <= {slave_tx_reg[TEST_WIDTH-2:0], 1'b0};
        end else begin
            miso <= 1'bz; 
        end
    end

    initial begin
        $dumpfile("spi_waves_16bit.vcd");
        $dumpvars(0, tb_spi_master);

        clk = 0; rst_n = 0; start = 0; tx_data = 0; cpol = 0; cpha = 0;
        #40 rst_n = 1; #20;

        $display("\n--- Starting 16-Bit Parameterized SPI Verification ---");

        tx_data = 16'hABCD; 
        slave_tx_reg = 16'h1234; 
        
        $display("Master sending: 16'hABCD | Slave sending: 16'h1234");
        
        start = 1; #20 start = 0;
        wait(done == 1'b1); #20;

        if (slave_rx_reg == 16'hABCD && rx_data == 16'h1234) begin
            $display("[PASS] 16-Bit Test Successful! Parameterization works flawlessly.");
        end else begin
            $display("[FAIL] 16-Bit Test Failed! Master rx: %h, Slave rx: %h", rx_data, slave_rx_reg);
        end

        $display("--- Verification Complete ---\n");
        $finish;
    end

endmodule