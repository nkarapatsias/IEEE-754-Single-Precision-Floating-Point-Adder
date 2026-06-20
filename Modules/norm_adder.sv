module norm_adder(

	input logic [7:0] max_exp,
	input logic [27:0] result_mant,
	output logic [8:0] norm_exp,
	output logic [26:0] norm_mant
);

	logic [4:0] leading_zeroes;
	lzc lzc_1(.result_mant(result_mant), .leading_zeroes(leading_zeroes));
	
	always_comb	begin
		
		if (result_mant[27] == 1'b1) begin // Mantissa is bigger or equal than 2, 1x.xxx
			norm_mant = {result_mant[27:2], result_mant[1] | result_mant[0]}; // Preserving sticky bit by or it with the lost bit
			norm_exp = max_exp + 1;
			
		end
		
		else if (result_mant[26] == 1'b1) begin //Mantissa is in the right format 1.xxxx
			norm_mant = result_mant[26:0];
			norm_exp = {1'b0, max_exp};		
		end
		
		else begin
			
			if (result_mant == 28'd0) begin 	// Avoid doing calculations with the 
				 norm_mant = 27'd0;		// trash data received from the lead zero counter module
				 norm_exp  = 9'd0;
			end
			
			else begin // Mantissa is smaller than 1, 0.xxx
				norm_mant = result_mant[26:0] << leading_zeroes;
				norm_exp = max_exp-leading_zeroes;
				
			end
		end
end


endmodule