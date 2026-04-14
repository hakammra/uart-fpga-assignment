

module nano_uart_top (
    input  wire        CLOCK_50,    

    input  wire [1:0]  KEY,         
    input  wire [3:0]  SW,          

    output wire [7:0]  LED,         

    // GPIO
    output wire        GPIO_00,     // TX seg a
    output wire        GPIO_01,     // TX seg b
    output wire        GPIO_02,     // TX seg c
    output wire        GPIO_03,     // TX seg d
    output wire        GPIO_04,     // TX seg e
    output wire        GPIO_05,     // TX seg f
    output wire        GPIO_06,     // TX seg g
    output wire        GPIO_07,     //  TX 
    input  wire        GPIO_08,     //  RX 
    output wire        GPIO_09,     // RX seg a
    output wire        GPIO_010,    // RX seg b
    output wire        GPIO_011,    // RX seg c
    output wire        GPIO_012,    // RX seg d
    output wire        GPIO_013,    // RX seg e
    output wire        GPIO_014,    // RX seg f
    output wire        GPIO_015     // RX seg g
);

    
    // 9600 baud
    localparam integer BAUD_DIVIDER = 5208;

    // Internal signals 
    wire        uart_tx;            
    wire        uart_tx_busy;       
    wire        uart_rx_ready;      
    wire [7:0]  uart_led;           
    wire [6:0]  uart_tx_seg;        
    wire [6:0]  uart_rx_seg;        

    // KEY[0] = RESET  
    // KEY[1] = SEND   
    wire rst_active_low;
    wire send_active_high;
    assign rst_active_low   = KEY[0];   
    assign send_active_high = ~KEY[1];  


    uart_core #(
        .CLOCKS_PER_PULSE(BAUD_DIVIDER)
    ) u_uart_core (
        .sw_nibble   (SW),                
        .send_btn    (send_active_high),   
        .clk         (CLOCK_50),          
        .rst_n       (rst_active_low),    

        .tx_wire     (uart_tx),           
        .tx_busy_out (uart_tx_busy),      

        .clr_ready   (1'b0),              
        .rx_wire     (GPIO_08),           
        .rx_rdy      (uart_rx_ready),     

        .led_byte    (uart_led),          
        .tx_seg_out  (uart_tx_seg),       
        .rx_seg_out  (uart_rx_seg)        
    );



    // The 8 LEDs 
    assign LED = uart_led;

    // UART TX  GPIO_07
    assign GPIO_07 = uart_tx;

    // TX 7-segment 
    assign GPIO_00 = uart_tx_seg[0];   // a
    assign GPIO_01 = uart_tx_seg[1];   // b
    assign GPIO_02 = uart_tx_seg[2];   // c
    assign GPIO_03 = uart_tx_seg[3];   // d
    assign GPIO_04 = uart_tx_seg[4];   // e
    assign GPIO_05 = uart_tx_seg[5];   // f
    assign GPIO_06 = uart_tx_seg[6];   // g

    // RX 7-segment 
    assign GPIO_09  = uart_rx_seg[0];  // a
    assign GPIO_010 = uart_rx_seg[1];  // b
    assign GPIO_011 = uart_rx_seg[2];  // c
    assign GPIO_012 = uart_rx_seg[3];  // d
    assign GPIO_013 = uart_rx_seg[4];  // e
    assign GPIO_014 = uart_rx_seg[5];  // f
    assign GPIO_015 = uart_rx_seg[6];  // g

endmodule
