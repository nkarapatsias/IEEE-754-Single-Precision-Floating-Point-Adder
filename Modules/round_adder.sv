import round_pkg::*;

module round_adder (
    input logic [2:0] round ,       
    input logic [26:0] norm_mant, 
    input logic z_sign,     
    output logic [24:0] round_mant, 
    output logic inexact_bit 
);

	logic        g, r, s;
	logic [23:0] base_mant;
	logic        round_up;

	assign base_mant = norm_mant[26:3];
	assign g = norm_mant[2]; // Guard bit
	assign r = norm_mant[1]; // Round bit
	assign s = norm_mant[0]; // Sticky bit


	assign inexact_bit = g | r | s;

	assign round_mant = {1'b0, base_mant} + round_up; // Apply rounding

	
	always_comb begin

	  case (round)
			IEEE_near: begin
				 round_up = g & (r | s | base_mant[0]);	// Round to nearest value
			end
			
			IEEE_zero: begin
				 round_up = 1'b0;		// Round towards zero 
			end
			
			IEEE_ninf: begin
				 round_up = inexact_bit & z_sign;	// Round to -Inf
			end
			
			IEEE_pinf: begin
				 round_up = inexact_bit & ~z_sign;	// Round to +Inf
			end
			
			near_maxMag: begin
				 round_up = g;	// Round near_maxMag
			end
			
			default: begin
				 round_up = 1'b0; 
			end
	  endcase
	end

endmodule