module mantissa_calc(
	input logic [8:0] exp_diff,
	input logic [23:0] mant_a,
	input logic [23:0] mant_b,
	input logic sign_exp_diff,
	input logic sa,
	input logic sb,
	output logic [27:0] result_mant
	);
	
	// Setting up helping variables
	
   logic [26:0] larger_mant; // Holding the larger mantissa based on the sign_exp_diff
   logic [26:0] smaller_mant; // Holding the smaller mantissa based on the sign_exp_diff
   logic [26:0] shifted_smaller; // Holding the final aligned smaller mantissa
	logic [48:0] shift_capture; // Big enough buffer to hold shift result without loosing data
   logic sticky_bit;  // Holds the sticky bit 
	 
   always_comb begin

		// Choosing the bigggest and smallest mantissas
		if (sign_exp_diff == 1'b1) begin 
			larger_mant  = {mant_a, 3'b000};
			smaller_mant = {mant_b, 3'b000};
		end else begin
			larger_mant  = {mant_b, 3'b000};
			smaller_mant = {mant_a, 3'b000};
		end
		
		
		if (exp_diff >= 9'd48) begin // If d is bigger than 48, the entire mantissa is shifted into the sticky zone
			shift_capture = '0;  
			sticky_bit = (smaller_mant != 0); 
			shifted_smaller = {26'b0, sticky_bit}; 
		end 
		
		else begin 
			shift_capture = {smaller_mant, 22'b0} >> exp_diff; // Perform the shift operation
			sticky_bit = |shift_capture[21:0];
			shifted_smaller = {shift_capture[48:23], shift_capture[22] | sticky_bit}; // G and R bits are already in shift_capture buffer
		end

		
		if (sa == sb) begin
			result_mant = larger_mant + shifted_smaller; // If both numbers have the same sign then addition
		end 
		
		else begin 
			result_mant = larger_mant - shifted_smaller; // If both numbers have different sign then subtraction
		end
		
	end
	
endmodule