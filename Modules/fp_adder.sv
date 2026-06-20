module fp_adder(
    input logic [31:0] a1, b1,                          
    input logic [2:0] rnd1,                            
    output logic [31:0] z1,                         
    output logic [7:0] status1                           
);

	// Internal helping connections
	logic [31:0] z_out;
	wire logic [7:0] max_exp;
	wire logic [8:0] exp_diff;
	wire logic sign_exp_diff;
	wire logic [27:0] result_mant;
	wire logic [8:0] norm_exp;
	wire logic [26:0] norm_mant;
	wire logic [24:0] round_mant;
	wire logic inexact_bit;
	logic [8:0] post_round_exp;
	logic [22:0] post_round_frac;
	logic overflow;
	logic underflow;
	logic [31:0] z_calc;
	
	//assign z1 = z_out;	
	assign status1[6] = 1'b0; // Not used bit
	assign status1[7] = 1'b0; // Division by zero not applied 

	
	//-------------Sign Calculation Begin-------------//
	
	always_comb begin

		if(a1[31] == b1[31]) z_out[31] = a1[31]; // Checking sign bits
		else if (a1[30:23] > b1[30:23]) z_out[31] = a1[31]; // Checking exponent
		else if (a1[30:23] < b1[30:23]) z_out[31] = b1[31];
		else if (a1[22:0] > b1[22:0]) z_out[31] = a1[31]; // Checking mantissa
		else if (a1[22:0] < b1[22:0]) z_out[31] = b1[31];
		else z_out[31] = 1'b0; // Setting a deault value

	end

	//-------------Sign Calculation End-------------//



	//-------------Exponent Calculation Begin-------------//
	exponent_calc exponent_calc_1(
	.Ea(a1[30:23]), 
	.Eb(b1[30:23]), 
	.max_exp(max_exp),
	.exp_diff(exp_diff),
	.sign_exp_diff(sign_exp_diff)
	);

	//-------------Exponent Calculation End-------------//



	//-------------Mantissa Calculation Begin-------------//
	
	mantissa_calc mant_calc_1(
	.exp_diff(exp_diff),
	.mant_a({1'b1, a1[22:0]}),
	.mant_b({1'b1, b1[22:0]}),  	// CHECK THE LEADING ONE BIT ERRORRRRRRRRRRRRR
	.sign_exp_diff(sign_exp_diff),
	.sa(a1[31]),
	.sb(b1[31]),
	.result_mant(result_mant)
	);
	
	//-------------Mantissa Calculation End-------------//
	


	//-------------Normalization Calculation Begin-------------//

	norm_adder norm_adder_1(
	.max_exp(max_exp),
	.result_mant(result_mant),
	.norm_exp(norm_exp),
	.norm_mant(norm_mant)
	);
	
	//-------------Exponent Calculation End-------------//
	
	
	
	
	//-------------Rounding Calculation Begin-------------//
	
	round_adder round_adder_1(
	.round(rnd1),       // 3-bit round mode from package
	.norm_mant(norm_mant),   // 24-bit mantissa + 3 GRS bits
	.z_sign(z_out[31]),      // Sign bit of the result
	.round_mant(round_mant),  // 24-bit mantissa + 1 extra bit for overflow
	.inexact_bit(inexact_bit)  // Indicates if rounding occurred
	);
	
	//-------------Rounding Calculation End-------------//

	
	//-------------Post round normalization Begin-------------//
	
	always_comb begin
	
		// If the mantissa MSBis 1, indicated overflow during rounding
		if (round_mant[24] == 1'b1) begin
			post_round_exp = norm_exp + 1;
			post_round_frac = round_mant[23:1]; 
		end else begin
			post_round_exp = norm_exp;
			post_round_frac = round_mant[22:0];
		end

		// Overflow: If exponent reaches 255 
		if (post_round_exp >= 9'd255 && post_round_exp[8] == 1'b0) begin
			overflow = 1'b1;
		end else begin
			overflow = 1'b0;
		end

		// Underflow: If exponent is 0 or less.
		if (post_round_exp == 9'd0 || post_round_exp[8] == 1'b1) begin
			underflow = 1'b1;
		end else begin
			underflow = 1'b0;
		end

		// Produce the final result
		z_calc = {z_out[31], post_round_exp[7:0], post_round_frac};
		
	end
	//-------------Post round normalization End-------------//
	
	
	
	//-------------Exception handling Begin-------------//
	
	
	exception_adder exception_adder_1(
    .a(a1),
    .b(b1),
    .round(rnd1),
    .overflow(overflow),
    .underflow(underflow),
    .inexact_bit(inexact_bit),
    .z_calc(z_calc),
    .result(z1),
    .zero_f(status1[0]),
    .inf_f(status1[1]),
    .nan_f(status1[2]),
    .tiny_f(status1[3]),
    .huge_f(status1[4]),
    .inexact_f(status1[5])
	);

	//-------------Exception handling End-------------//
	
endmodule