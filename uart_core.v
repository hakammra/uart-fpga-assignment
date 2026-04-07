

module uart_core #(
    parameter integer CLOCKS_PER_PULSE = 5208   // 50 MHz / 9600 baud
)(
    input  wire [3:0] sw_nibble,    
    input  wire       send_btn,     
    input  wire       clk,
    input  wire       rst_n,

    output wire       tx_wire,      
    output wire       tx_busy_out,  

    input  wire       clr_ready,    
    input  wire       rx_wire,      
    output wire       rx_rdy,       

    output wire [7:0] led_byte,     
    output wire [6:0] tx_seg_out,   
    output wire [6:0] rx_seg_out    
);

    //  8-bit  payload 
    //  upper nibble is always 0.
    
    wire [7:0] tx_payload;
    assign tx_payload = {4'b0000, sw_nibble};

    
    wire [7:0] rx_byte;

    
    assign led_byte = rx_byte;

    
    

    //  UART Transmitter
    
    uart_transmitter #(
        .CLOCKS_PER_PULSE(CLOCKS_PER_PULSE)
    ) u_tx (
        .byte_in   (tx_payload),   // 8-bit data to send
        .send_req  (send_btn),     
        .clk       (clk),
        .rst_n     (rst_n),
        .tx_line   (tx_wire),      
        .tx_active (tx_busy_out)   
    );

    //  UART Receiver 
    
    uart_receiver #(
        .CLOCKS_PER_PULSE(CLOCKS_PER_PULSE)
    ) u_rx (
        .clk         (clk),
        .rst_n       (rst_n),
        .clear_ready (clr_ready),  
        .rx_line     (rx_wire),    
        .data_ready  (rx_rdy),     
        .byte_out    (rx_byte)     
    );

    // 7-Segment Decoder TX 

    hex_to_segments u_tx_seg (
        .nibble_in (sw_nibble),    
        .seg_out   (tx_seg_out)    
    );

    //  7-Segment Decoder RX side
    
    
    hex_to_segments u_rx_seg (
        .nibble_in (rx_byte[3:0]),  // lower 4 bits of received byte
        .seg_out   (rx_seg_out)     // drives 7 segments Rx
    );

endmodule
