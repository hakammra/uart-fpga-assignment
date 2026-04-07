

module uart_transmitter #(
    parameter integer CLOCKS_PER_PULSE = 5208  //  50MHz / 9600 baud we are keeping same
)(
    input  wire [7:0] byte_in,    
    input  wire       send_req,   
    input  wire       clk,        
    input  wire       rst_n,      
    output reg        tx_line,    
    output wire       tx_active   
);

    
    // represent the four FSM states
    localparam [1:0] ST_IDLE  = 2'd0,
                     ST_START = 2'd1,
                     ST_DATA  = 2'd2,
                     ST_STOP  = 2'd3;

    reg [1:0] cur_state;   

    
    reg [7:0] shift_reg;   
    reg [2:0] bit_idx;     
    reg [12:0] baud_cnt;   
                           // 13 bits for values up to 8191 (5208)

    
    reg send_req_prev;     
    wire start_pulse;      
    assign start_pulse = send_req & ~send_req_prev;

    
    assign tx_active = (cur_state != ST_IDLE);

    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset everything to a known safe state
            send_req_prev <= 1'b0;
            cur_state     <= ST_IDLE;
            shift_reg     <= 8'd0;
            bit_idx       <= 3'd0;
            baud_cnt      <= 13'd0;
            tx_line       <= 1'b1;   
        end else begin
            
            send_req_prev <= send_req;

            case (cur_state)

                
                // IDLE
                ST_IDLE: begin
                    tx_line   <= 1'b1;     // keep line high while idle
                    baud_cnt  <= 13'd0;
                    bit_idx   <= 3'd0;
                    if (start_pulse) begin
                        shift_reg <= byte_in;  // capture the byte to send
                        cur_state <= ST_START;
                    end
                end

                
                // START
                ST_START: begin
                    tx_line <= 1'b0;   // start bit is always 0
                    if (baud_cnt == CLOCKS_PER_PULSE - 1) begin
                        baud_cnt  <= 13'd0;
                        cur_state <= ST_DATA;  
                    end else begin
                        baud_cnt <= baud_cnt + 1'b1;
                    end
                end

                
                // DATA
                ST_DATA: begin
                    tx_line <= shift_reg[bit_idx];  
                    if (baud_cnt == CLOCKS_PER_PULSE - 1) begin
                        baud_cnt <= 13'd0;
                        if (bit_idx == 3'd7) begin
                            // All 8 bits sent,  so STOP
                            bit_idx   <= 3'd0;
                            cur_state <= ST_STOP;
                        end else begin
                            bit_idx <= bit_idx + 1'b1;  // next bit
                        end
                    end else begin
                        baud_cnt <= baud_cnt + 1'b1;
                    end
                end

                
                // STOP
                ST_STOP: begin
                    tx_line <= 1'b1;   // stop bit is always 1
                    if (baud_cnt == CLOCKS_PER_PULSE - 1) begin
                        baud_cnt  <= 13'd0;
                        cur_state <= ST_IDLE;
                    end else begin
                        baud_cnt <= baud_cnt + 1'b1;
                    end
                end

                // if we end up in an unknown state, reset
                default: begin
                    cur_state <= ST_IDLE;
                    tx_line   <= 1'b1;
                end

            endcase
        end
    end

endmodule
