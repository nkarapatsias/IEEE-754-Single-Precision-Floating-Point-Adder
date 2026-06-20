module lzc (
    input  logic [27:0] result_mant,
    output logic [4:0]  leading_zeroes
);

    always_comb begin
        
		  leading_zeroes = 5'd0;
		  // calculating the leading zeros from the last 1 we found from iteration 0 to 26
		for (int i = 0; i <= 26; i++) begin
			if (result_mant[i] == 1'b1) begin
				 leading_zeroes = 5'(26 - i);
			end
		end
	end

endmodule
