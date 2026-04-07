

module uart_receiver #(
    parameter integer CLOCKS_PER_PULSE = 5208  //  50MHz / 9600 baud
)(
    input  wire       clk,          
    input  wire       rst_n,        
    input  wire       clear_ready,  
    input  wire       rx_line,      
    output reg        data_ready,   
    output wire [7:0] byte_out      
);

    
    localparam [1:0] ST_IDLE  = 2'd0,
                     ST_START = 2'd1,
                     ST_DATA  = 2'd2,
                     ST_STOP  = 2'd3;

    reg [1:0] cur_state;

    
    reg rx_ff1, rx_ff2;   

    // Internal registers
    reg [2:0]  bit_idx;    
    reg [12:0] baud_cnt;   
    reg [7:0]  data_reg;   // shift register 

    
    assign byte_out = data_reg;

    
    // Both flip-flops reset to 1 because UART idle state is HIGH.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_ff1 <= 1'b1;
            rx_ff2 <= 1'b1;
        end else begin
            rx_ff1 <= rx_line;   
            rx_ff2 <= rx_ff1;    
        end
    end

    // Main FSM 
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cur_state  <= ST_IDLE;
            baud_cnt   <= 13'd0;
            bit_idx    <= 3'd0;
            data_reg   <= 8'd0;
            data_ready <= 1'b0;
        end else begin

            
            if (clear_ready)
                data_ready <= 1'b0;

            case (cur_state)

                
                // IDLE
                ST_IDLE: begin
                    baud_cnt <= 13'd0;
                    bit_idx  <= 3'd0;
                    if (rx_ff2 == 1'b0)
                        cur_state <= ST_START;
                end

                
                // START
                ST_START: begin
                    if (baud_cnt == (CLOCKS_PER_PULSE / 2) - 1) begin
                        baud_cnt <= 13'd0;
                        if (rx_ff2 == 1'b0)
                            cur_state <= ST_DATA;  // confirmed start bit
                        else
                            cur_state <= ST_IDLE;  
                    end else begin
                        baud_cnt <= baud_cnt + 1'b1;
                    end
                end

                
                // DATA
                ST_DATA: begin
                    if (baud_cnt == CLOCKS_PER_PULSE - 1) begin
                        baud_cnt <= 13'd0;
                        data_reg[bit_idx] <= rx_ff2;  // sample the bit
                        if (bit_idx == 3'd7) begin
                            bit_idx   <= 3'd0;
                            cur_state <= ST_STOP;
                        end else begin
                            bit_idx <= bit_idx + 1'b1;
                        end
                    end else begin
                        baud_cnt <= baud_cnt + 1'b1;
                    end
                end

                
                // STOP
                ST_STOP: begin
                    if (baud_cnt == CLOCKS_PER_PULSE - 1) begin
                        baud_cnt <= 13'd0;
                        if (rx_ff2 == 1'b1)
                            data_ready <= 1'b1;  // valid byte received
                        cur_state <= ST_IDLE;
                    end else begin
                        baud_cnt <= baud_cnt + 1'b1;
                    end
                end

                default: cur_state <= ST_IDLE;

            endcase
        end
    end

endmodule
