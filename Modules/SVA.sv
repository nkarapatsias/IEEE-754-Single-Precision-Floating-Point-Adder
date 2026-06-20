// Immediate Assertions
module test_status_bits (
    input logic [7:0] status
);
    // Status bits:
    // Bit 0: Zero, Bit 1: Infinity, Bit 2: Invalid (NaN)
    // Bit 3: Tiny (Underflow), Bit 4: Huge (Overflow), Bit 5: Inexact

    always_comb begin
        // NaN is exclusive with everything else
        if (status[2]) begin
            assert_nan_zero: assert(status[0] == 0) 
                $display("[PASS] NaN and Zero did not assert together."); 
                else $error("[FAIL] NaN and Zero asserted together!");
            
            assert_nan_inf: assert(status[1] == 0) 
                $display("[PASS] NaN and Inf did not assert together."); 
                else $error("[FAIL ] NaN and Inf asserted together!");
            
            assert_nan_tiny: assert(status[3] == 0) 
                $display("[PASS - IMM] NaN and Tiny did not assert together."); 
                else $error("[FAIL] NaN and Tiny asserted together!");
            
            assert_nan_huge: assert(status[4] == 0) 
                $display("[PASS] NaN and Huge did not assert together."); 
                else $error("[FAIL] NaN and Huge asserted together!");
        end

        // Zero and Huge cannot be true together (cannot be exactly 0 and > MaxNorm)
        if (status[0]) begin
            assert_zero_huge: assert(status[4] == 0) 
                $display("[PASS] Zero and Huge did not assert together."); 
                else $error("[FAIL] Zero and Huge asserted together!");
        end

        // Inf and Tiny cannot be true together (cannot be Inf and < MinNorm)
        if (status[1]) begin
            assert_inf_tiny: assert(status[3] == 0) 
                $display("[PASS] Inf and Tiny did not assert together."); 
                else $error("[FAIL] Inf and Tiny asserted together!");
        end

        // Tiny and Huge cannot be true together (< MinNorm and > MaxNorm)
        if (status[3]) begin
            assert_tiny_huge: assert(status[4] == 0) 
                $display("[PASS] Tiny and Huge did not assert together."); 
                else $error("[FAIL] Tiny and Huge asserted together!");
        end
    end
endmodule


// Concurrent Assertions
module test_status_z_combinations (
    input logic clk,
    input logic [31:0] a,
    input logic [31:0] b,
    input logic [31:0] result,
    input logic [7:0] status
);
    // 1. ZERO CHECK
    // If 'zero' asserts, all bits of 'z' exponent must be 0.
    property p_zero;
        @(posedge clk) status[0] |-> (result[30:23] == 8'h00);
    endproperty
    
    assert_zero: assert property (p_zero) 
        else $error("[FAIL] Zero status asserted, but exponent is not 0.");
    
    cover_zero: cover property (@(posedge clk) status[0] && (result[30:23] == 8'h00)) 
        $display("[PASS] Zero flag successfully matched with 0x00 exponent.");

    // 2. INFINITY CHECK
    // If 'inf' asserts, all bits of 'z' exponent must be 1.
    property p_inf;
        @(posedge clk) status[1] |-> (result[30:23] == 8'hFF);
    endproperty
    
    assert_inf: assert property (p_inf) 
        else $error("[FAIL] Inf status asserted, but exponent is not 0xFF.");
        
    cover_inf: cover property (@(posedge clk) status[1] && (result[30:23] == 8'hFF)) 
        $display("[PASS] Infinity flag successfully matched with 0xFF exponent.");

    // 3. NaN CHECK (Time Travel)
    // If 'nan' asserts, 2 cycles before (due to our pipeline), 'a' and 'b' 
    // must have been infinite with opposite signs (+Inf and -Inf).
    property p_nan;
        @(posedge clk) status[2] |-> ($past(a[30:23], 2) == 8'hFF && 
                                      $past(b[30:23], 2) == 8'hFF && 
                                      $past(a[31], 2) != $past(b[31], 2));
    endproperty
    
    assert_nan: assert property (p_nan) 
        else $error("[FAIL] NaN status asserted without opposite-sign Inf inputs 2 cycles prior.");
        
    cover_nan: cover property (@(posedge clk) status[2] && ($past(a[30:23], 2) == 8'hFF && $past(b[30:23], 2) == 8'hFF && $past(a[31], 2) != $past(b[31], 2))) 
        $display("[PASS] NaN flag successfully tracked back to +Inf/-Inf inputs.");

    // 4. HUGE (OVERFLOW) CHECK
    // If 'huge' asserts, result exponent must be 0xFF (Inf) OR 
    // 0xFE with all 1s mantissa (MaxNormal).
    property p_huge;
        @(posedge clk) status[4] |-> (result[30:23] == 8'hFF) || 
                                     (result[30:23] == 8'hFE && result[22:0] == 23'h7FFFFF);
    endproperty
    
    assert_huge: assert property (p_huge) 
        else $error("[FAIL] Huge status asserted without Inf or MaxNormal result.");
        
    cover_huge: cover property (@(posedge clk) status[4] && ((result[30:23] == 8'hFF) || (result[30:23] == 8'hFE && result[22:0] == 23'h7FFFFF))) 
        $display("[PASS] Huge flag successfully matched with Overflow boundaries.");

endmodule