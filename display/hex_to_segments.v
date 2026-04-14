
//
//      aaa
//     f   b
//     f   b
//      ggg
//     e   c
//     e   c
//      ddd


module hex_to_segments (
    input  wire [3:0] nibble_in,   // 4-bit value from DIP switches 
    output wire [6:0] seg_out      // 7 segment drive signals
);

    
    reg [6:0] seg_active_high;

    // Combinational lookup table
    always @(*) begin
        case (nibble_in)
            //             gfedcba  
            4'h0: seg_active_high = 7'b0111111; // 0  
            4'h1: seg_active_high = 7'b0000110; // 1  
            4'h2: seg_active_high = 7'b1011011; // 2  
            4'h3: seg_active_high = 7'b1001111; // 3  
            4'h4: seg_active_high = 7'b1100110; // 4  
            4'h5: seg_active_high = 7'b1101101; // 5  
            4'h6: seg_active_high = 7'b1111101; // 6  
            4'h7: seg_active_high = 7'b0000111; // 7  
            4'h8: seg_active_high = 7'b1111111; // 8  
            4'h9: seg_active_high = 7'b1101111; // 9  
            4'hA: seg_active_high = 7'b1110111; // 10 
            4'hB: seg_active_high = 7'b1111100; // 11 
            4'hC: seg_active_high = 7'b0111001; // 12 
            4'hD: seg_active_high = 7'b1011110; // 13 
            4'hE: seg_active_high = 7'b1111001; // 14 
            4'hF: seg_active_high = 7'b1110001; // 15 
            default: seg_active_high = 7'b0000000; // blank (all off)
        endcase
    end

    assign seg_out = seg_active_high;

endmodule
