`timescale 1ns/1ps

module uart_tb();
    reg [3:0] tb_switches;
    reg tb_send;
    reg tb_clk;
    reg tb_rst_n;
    reg tb_clr;
    wire tb_tx;
    wire tb_busy;
    wire tb_ready;
    wire [7:0] tb_leds;
    wire [6:0] tb_tx_seg;
    wire [6:0] tb_rx_seg;

    
    uart_core #(
        .CLOCKS_PER_PULSE(16)
    ) dut (
        .sw_nibble(tb_switches),
        .send_btn(tb_send),
        .clk(tb_clk),
        .rst_n(tb_rst_n),
        .tx_wire(tb_tx),
        .tx_busy_out(tb_busy),
        .clr_ready(tb_clr),
        .rx_wire(tb_tx),
        .rx_rdy(tb_ready),
        .led_byte(tb_leds),
        .tx_seg_out(tb_tx_seg),
        .rx_seg_out(tb_rx_seg)
    );

    
    always #5 tb_clk = ~tb_clk;
    localparam RX_TIMEOUT = 12 * 16 + 20;
    task send_nibble(input [3:0] value);
        integer wait_cnt;
        begin
            tb_switches = value;
            tb_send = 1'b0;
            @(posedge tb_clk);
            tb_send = 1'b1;
            @(posedge tb_clk);
            @(posedge tb_clk);
            tb_send = 1'b0;
            wait_cnt = 0;
            while (!tb_busy && wait_cnt < 10) begin
                @(posedge tb_clk);
                wait_cnt = wait_cnt + 1;
            end
            if (!tb_busy) begin
                $display("ERROR at time %0t: TX never went busy for value 0x%h", $time, value);
                $finish;
            end
            wait (tb_busy == 1'b0);
        end
    endtask
    task wait_for_ready(input [3:0] sent_val);
        integer t;
        begin
            t = 0;
            while (!tb_ready && t < RX_TIMEOUT) begin
                @(posedge tb_clk);
                t = t + 1;
            end
            if (!tb_ready) begin
                $display("TIMEOUT at time %0t: rx_rdy never asserted for sent=0x%h (leds=0x%h)",
                          $time, sent_val, tb_leds);
                $finish;
            end
        end
    endtask
    function [6:0] expected_seg(input [3:0] nibble);
        reg [6:0] ah;
        begin
            case (nibble)
                4'h0: ah = 7'b0111111;
                4'h1: ah = 7'b0000110;
                4'h2: ah = 7'b1011011;
                4'h3: ah = 7'b1001111;
                4'h4: ah = 7'b1100110;
                4'h5: ah = 7'b1101101;
                4'h6: ah = 7'b1111101;
                4'h7: ah = 7'b0000111;
                4'h8: ah = 7'b1111111;
                4'h9: ah = 7'b1101111;
                4'hA: ah = 7'b1110111;
                4'hB: ah = 7'b1111100;
                4'hC: ah = 7'b0111001;
                4'hD: ah = 7'b1011110;
                4'hE: ah = 7'b1111001;
                4'hF: ah = 7'b1110001;
                default: ah = 7'b0000000;
            endcase
            expected_seg = ah;
        end
    endfunction
    integer loop_idx;
    initial begin
        tb_clk = 0;
        tb_switches = 4'h0;
        tb_send = 1'b0;
        tb_rst_n = 1'b0;
        tb_clr = 1'b0;
        #100;
        tb_rst_n = 1'b1;
        #100;
        for (loop_idx = 0; loop_idx < 16; loop_idx = loop_idx + 1) begin
            send_nibble(loop_idx[3:0]);
            wait_for_ready(loop_idx[3:0]);
            if (tb_leds[3:0] !== loop_idx[3:0]) begin
                $display("FAIL at time %0t: sent=0x%h  received=0x%h",
                          $time, loop_idx[3:0], tb_leds[3:0]);
                $finish;
            end else begin
                $display("PASS at time %0t: sent=0x%h  received=0x%h",
                          $time, loop_idx[3:0], tb_leds[3:0]);
            end
            if (tb_tx_seg !== expected_seg(loop_idx[3:0]))
                $display("SEG-TX MISMATCH at time %0t: nibble=0x%h  got=0x%02h  expected=0x%02h",
                          $time, loop_idx[3:0], tb_tx_seg, expected_seg(loop_idx[3:0]));
            if (tb_rx_seg !== expected_seg(loop_idx[3:0]))
                $display("SEG-RX MISMATCH at time %0t: nibble=0x%h  got=0x%02h  expected=0x%02h",
                          $time, loop_idx[3:0], tb_rx_seg, expected_seg(loop_idx[3:0]));
            tb_clr = 1'b1;
            @(posedge tb_clk);
            tb_clr = 1'b0;
            #50000;
        end
        $display("ALL 16 VALUES PASSED — UART loopback test complete.");
        $stop;
    end
endmodule
