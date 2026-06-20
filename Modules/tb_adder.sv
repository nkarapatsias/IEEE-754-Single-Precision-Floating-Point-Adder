`timescale 1ns/1ps

module tb_adder ();

	// Module ports
	logic [31:0] result;        
	logic [7:0] status;     	    
	logic [31:0] a, b;
	logic [2:0] round;          
	bit clk, resetn;            

	// Helping Variables
	int total_random_checked = 0;
	int success_random = 0;
	int total_corner_checked = 0;
	int success_corner = 0;
	logic is_random, valid_check;
	
	
	// Hardfloat ports and variables
	logic [31:0] results_hf ;    
	logic [31:0] results_ref;   
	logic [2:0] rnd_hf;			
	logic [31:0] a_hf, b_hf;    
	logic [32:0] recFN_a, recFN_b, recFN_out;
	logic [4:0] exc_hf;

	// Pipeline signals to match the 2-cycle difference between the dut and hardfloat
	logic is_random_d1, is_random_d2;
	logic valid_check_d1, valid_check_d2;
	logic [31:0] ref_delay1, ref_delay2;

	always_ff @(posedge clk or negedge resetn) begin
	  if (!resetn) begin
			is_random_d1 <= 0;
			is_random_d2 <= 0;
			valid_check_d1 <= 0;
			valid_check_d2 <= 0;
			ref_delay1 <= '0;
			ref_delay2 <= '0;
	  end else begin
			is_random_d1 <= is_random;
			is_random_d2 <= is_random_d1;
			valid_check_d1 <= valid_check;
			valid_check_d2 <= valid_check_d1;
			ref_delay1 <= results_ref; 
			ref_delay2 <= ref_delay1;
	  end
	end

	
	// DUT instantiation 
	fp_adder_top dut (
	  .a(a),
	  .b(b),
	  .round(round),
	  .clk(clk),
	  .resetn(resetn),
	  .result(result),
	  .status(status)
	);

	// Bind the Assertions to the DUT
	bind fp_adder_top test_status_bits dut_status_bits_inst (.status(status));
	bind fp_adder_top test_status_z_combinations dut_status_z_inst (
	  .clk(clk), .a(a), .b(b), .result(result), .status(status)
	);

	// Hardfloat model instantiation
	fNToRecFN #(8, 24) conv_a (
	  .in(a_hf),
	  .out(recFN_a)
	);

	fNToRecFN #(8, 24) conv_b (
	  .in(b_hf),
	  .out(recFN_b)
	);

	addRecFN #(8, 24) adder_ref (
	  .control(1'b0),
	  .subOp(1'b0),
	  .a(recFN_a),
	  .b(recFN_b),
	  .roundingMode(round),
	  .out(recFN_out),
	  .exceptionFlags(exc_hf)
	);

	recFNToFN #(8, 24) conv_out (
	  .in(recFN_out),
	  .out(results_hf)
	);

		// Update the reference model inputs 
	always_comb begin
		// If a is NaN => Inf
		if(a[30:23] == '1) begin
			a_hf = {a[31], {8{1'b1}}, {23{1'b0}}};
		end
		// If a is denorm => Zero
		else if(a[30:23] == '0 ) begin
			a_hf = {a[31], {31{1'b0}}};
		end
		else begin
			a_hf = a;
		end

		// If b is NaN => Inf
		if(b[30:23] == '1) begin
			b_hf = {b[31], {8{1'b1}}, {23{1'b0}}};
		end
		// If b is denorm => Zero
		 else if(b[30:23] == '0 ) begin
			b_hf = {b[31], {31{1'b0}}};
		end
		else begin
			b_hf = b;
		end

		// If result is denorm => Zero or Min normal
		if(results_hf[30:23] == '0 && |results_hf[22:0]) begin
			if (round == 3'b001 || round == 3'b000 || (round == 3'b010 && !results_hf[31]) || (round == 3'b011 && results_hf[31]) || round == 3'b100)
				results_ref = {results_hf[31], {31{1'b0}}};
			else
				results_ref = {results_hf[31], {7{1'b0}}, 1'b1, {23{1'b0}}};
		end
		// If result is NaN => Inf
		else if(results_hf[30:23] == '1 && |results_hf[22:0]) begin
			results_ref = {results_hf[31], {8{1'b1}}, {23{1'b0}}};
		end
		else
			results_ref = results_hf;
	end

	// ========================================================================
	// CORNER CASE ENUMERATION & FUNCTIONS
	// ========================================================================
	typedef enum logic [3:0] {
	  pos_nan,
	  neg_nan,
	  pos_inf,
	  neg_inf,
	  pos_norm,
	  neg_norm,
	  pos_denorm,
	  neg_denorm,
	  pos_zero,
	  neg_zero
	} corner_case_t;

	// Functions to match each corner case with enum
	function logic [31:0] get_corner_value(corner_case_t corner);
	  case (corner)
			pos_nan:    return 32'h7FC00000;
			neg_nan:    return 32'hFFC00000;
			pos_inf:    return 32'h7F800000;
			neg_inf:    return 32'hFF800000;
			pos_norm:   return 32'h40000000; 
			neg_norm:   return 32'hC0000000; 
			pos_denorm: return 32'h00400000;
			neg_denorm: return 32'h80400000;
			pos_zero:   return 32'h00000000;
			neg_zero:   return 32'h80000000;
			default:    return 32'h00000000;
	  endcase
	endfunction

	function corner_case_t get_corner_type(logic [31:0] val);
	  case (val)
			32'h7FC00000: return pos_nan;
			32'hFFC00000: return neg_nan;
			32'h7F800000: return pos_inf;
			32'hFF800000: return neg_inf;
			32'h40000000: return pos_norm;
			32'hC0000000: return neg_norm;
			32'h00400000: return pos_denorm;
			32'h80400000: return neg_denorm;
			32'h00000000: return pos_zero;
			32'h80000000: return neg_zero;
			default:      return pos_zero; 
	  endcase
	endfunction
	
	// Run corner cases
	task run_corner_cases();
	  $display("=======================================================");
	  $display("   STARTING CORNER CASE TESTS                          ");
	  $display("=======================================================");
	  
	  // Loop all 5 rounding modes
	  for (int r = 0; r < 5; r++) begin
			round = r[2:0];
			
			// Loop all 10 corner cases for input a
			for (int i = 0; i < 10; i++) begin
				 // Loop all 10 corner cases for input b
				 for (int j = 0; j < 10; j++) begin
					  @(negedge clk);
					  valid_check = 1;
					  is_random = 0;
					  a = get_corner_value(corner_case_t'(i));
					  b = get_corner_value(corner_case_t'(j));
				 end
			end
	  end
	  
	  @(negedge clk); valid_check = 0;
	  repeat(3) @(negedge clk);
	endtask

	task run_random_cases();
	  $display("=======================================================");
	  $display("   STARTING RANDOM TESTS                               ");
	  $display("=======================================================");

	  // 1000 random tests per rounding mode
	  for (int r = 0; r < 5; r++) begin
			round = r[2:0];
			
			for (int k = 0; k < 1000; k++) begin
				 @(negedge clk);
				 valid_check = 1;
				 is_random = 1;
				 a = {$urandom(), $urandom()};
				 b = {$urandom(), $urandom()};
			end
	  end

	  @(negedge clk); valid_check = 0;
	  repeat(3) @(negedge clk);
	endtask

	// Main Thread 
	initial begin
	  clk = 0;
	  forever #5 clk = ~clk; // 10ns/100Mhz clock
	end

	initial begin
	  resetn = 0;
	  a = 0; b = 0; round = 0;
	  is_random = 0;
	  valid_check = 0;
	  
	  #25; 
	  resetn = 1;

	  // Execute the testing tasks
	  run_corner_cases();
	  run_random_cases();

	  $display("=======================================================");
	  $display("						SIMULATION STATISTICS");
	  $display("=======================================================");
	  $display("Total Random Tests Executed : %0d", total_random_checked);
	  $display("Random Tests SUCCESS Rate   : %0d / %0d", success_random, total_random_checked);
	  $display("-------------------------------------------------------");
	  $display("Total Corner Tests Executed : %0d", total_corner_checked);
	  $display("Corner Tests SUCCESS Rate   : %0d / %0d", success_corner, total_corner_checked);
	  $display("=======================================================");

	  $finish;
	end

	// Result Comperator
	always_ff @(negedge clk) begin
	  if (resetn && valid_check_d2) begin
			if (is_random_d2) total_random_checked++;
			else total_corner_checked++;

			// Report Mismatches
			if (result !== ref_delay2) begin
				 if (is_random_d2)
					  $display("RANDOM ERROR | Rnd: %0d | Expected: %08X | Got: %08X", round, ref_delay2, result);
				 else
					  $display("CORNER ERROR | Rnd: %0d | Expected: %08X | Got: %08X", round, ref_delay2, result);
			end else begin
				 if (is_random_d2) success_random++;
				 else success_corner++;
			end
	  end
	end

endmodule