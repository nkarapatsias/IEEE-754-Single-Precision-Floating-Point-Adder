module exponent_calc (
input logic [7:0] Ea, Eb, 
output logic[7:0] max_exp,
output logic [8:0] exp_diff,
output logic sign_exp_diff
); 

	always_comb begin
		
		if (Ea[7:0]>=Eb[7:0]) begin // Setup a deault value in case they are equal
		
			sign_exp_diff = 1'b1;
			exp_diff = {1'b0, Ea[7:0]-Eb[7:0]};
			max_exp = Ea[7:0];
		
		end
		
		else begin 

			sign_exp_diff = 1'b0;
			exp_diff = {1'b0, Eb[7:0]-Ea[7:0]};
			max_exp = Eb[7:0];
		
		end	
		
	end		

endmodule