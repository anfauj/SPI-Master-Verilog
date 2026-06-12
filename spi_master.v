module spi_master #(
    parameter DATA_WIDTH      = 8,
    parameter CLOCK_DIV_RATIO = 4
)(
    input  wire                    clk,      
    input  wire                    rst_n,    
    input  wire                    start,    
    input  wire [DATA_WIDTH-1:0]   tx_data,  
    input  wire                    miso,     
    input  wire                    cpol,     
    input  wire                    cpha,     
    
    output reg                     sclk,     
    output reg                     mosi,     
    output reg                     cs_n,     
    output reg  [DATA_WIDTH-1:0]   rx_data,  
    output reg                     done      
);

    localparam IDLE     = 2'b00;
    localparam LOAD     = 2'b01;
    localparam TRANSFER = 2'b10;
    localparam DONE     = 2'b11;

    reg [1:0] state, next_state;

    reg [$clog2(CLOCK_DIV_RATIO)-1:0] clk_div;          
    reg [$clog2(DATA_WIDTH)-1:0]      bit_cnt;          
    reg                               edge_cnt;         
    reg [DATA_WIDTH-1:0]              tx_shift;         
    reg [DATA_WIDTH-1:0]              rx_shift;         

    wire sclk_en = (clk_div == CLOCK_DIV_RATIO - 1); 

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) clk_div <= 0;
        else if (state == TRANSFER) clk_div <= clk_div + 1'b1;
        else clk_div <= 0;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) state <= IDLE;
        else state <= next_state;
    end

    always @(*) begin
        next_state = state;
        case (state)
            IDLE:     if (start) next_state = LOAD;
            LOAD:     next_state = TRANSFER;
            TRANSFER: if (sclk_en && bit_cnt == (DATA_WIDTH - 1) && edge_cnt == 1'b1) next_state = DONE;
            DONE:     next_state = IDLE;
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sclk     <= 1'b0; 
            mosi     <= 1'b0;
            cs_n     <= 1'b1; 
            done     <= 1'b0;
            tx_shift <= {DATA_WIDTH{1'b0}};
            rx_shift <= {DATA_WIDTH{1'b0}};
            rx_data  <= {DATA_WIDTH{1'b0}};
            bit_cnt  <= 0;
            edge_cnt <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    cs_n <= 1'b1;
                    done <= 1'b0;
                    sclk <= cpol; 
                end
                
                LOAD: begin
                    tx_shift <= tx_data;
                    cs_n     <= 1'b0; 
                    bit_cnt  <= 0;
                    edge_cnt <= 1'b0;
                    
                    if (cpha == 1'b0) begin
                        mosi <= tx_data[DATA_WIDTH-1];
                        tx_shift <= {tx_data[DATA_WIDTH-2:0], 1'b0}; 
                    end
                end
                
                TRANSFER: begin
                    if (sclk_en) begin
                        sclk <= ~sclk;            
                        edge_cnt <= ~edge_cnt;   
                        
                        if (edge_cnt == cpha) begin
                            rx_shift <= {rx_shift[DATA_WIDTH-2:0], miso};
                        end else begin
                            mosi <= tx_shift[DATA_WIDTH-1];
                            tx_shift <= {tx_shift[DATA_WIDTH-2:0], 1'b0};
                            bit_cnt <= bit_cnt + 1'b1; 
                        end
                    end
                end
                
                DONE: begin
                    cs_n    <= 1'b1; 
                    done    <= 1'b1; 
                    rx_data <= rx_shift; 
                end
            endcase
        end
    end
endmodule