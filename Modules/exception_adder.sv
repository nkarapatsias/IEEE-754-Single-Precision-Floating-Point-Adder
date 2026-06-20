import round_pkg::*;

module exception_adder (
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [2:0]  round,
    input  logic        overflow,
    input  logic        underflow,
    input  logic        inexact_bit,
    input  logic [31:0] z_calc,
    output logic [31:0] result,
    output logic        zero_f,
    output logic        inf_f,
    output logic        nan_f,
    output logic        tiny_f,
    output logic        huge_f,
    output logic        inexact_f
);

    typedef enum logic [2:0] {ZERO, INF, NORM, MIN_NORM, MAX_NORM} interp_t;

    function interp_t num_interp(input logic [31:0] num);
        if (num[30:23] == 8'h00) 
            return ZERO;
        else if (num[30:23] == 8'hFF) 
            return INF;
        else 
            return NORM;
    endfunction

    function logic [30:0] z_num(input interp_t type_val);
        case (type_val)
            ZERO:     return 31'h00000000;
            INF:      return {8'hFF, 23'h000000};
            MIN_NORM: return {8'h01, 23'h000000};
            MAX_NORM: return {8'hFE, 23'h7FFFFF};
            default:  return 31'h00000000;
        endcase
    endfunction

    interp_t type_a, type_b;
    assign type_a = num_interp(a);
    assign type_b = num_interp(b);

    always_comb begin
        zero_f    = 1'b0;
        inf_f     = 1'b0;
        nan_f     = 1'b0;
        tiny_f    = 1'b0;
        huge_f    = 1'b0;
        inexact_f = 1'b0;
        result    = z_calc;

        // Corner Cases 
        if (type_a == ZERO && type_b == ZERO) begin
            result = {z_calc[31], z_num(ZERO)};
            zero_f = 1'b1;
        end
        else if ((type_a == ZERO && type_b == INF) || (type_a == INF && type_b == ZERO)) begin
            result = {z_calc[31], z_num(INF)};
            inf_f = 1'b1;
        end
        else if ((type_a == ZERO && type_b == NORM) || (type_a == NORM && type_b == ZERO)) begin
            result = z_calc;
            inexact_f = inexact_bit;
        end
        else if (type_a == INF && type_b == INF) begin
            if (a[31] != b[31]) begin // +INF and -INF produces NaN
                result = {1'b0, 8'hFF, 23'h400000}; 
                nan_f = 1'b1;
            end else begin
                result = {z_calc[31], z_num(INF)};
                inf_f = 1'b1;
            end
        end
        else if ((type_a == INF && type_b == NORM) || (type_a == NORM && type_b == INF)) begin
            result = {z_calc[31], z_num(INF)};
            inf_f = 1'b1;
        end
        
        // Normal x Normal Combinations 
        else begin
            if (overflow) begin
                huge_f = 1'b1;
                inexact_f = 1'b1;
                // Overflow
                case (round)
                    IEEE_near, near_maxMag: begin
                        result = {z_calc[31], z_num(INF)};
                        inf_f = 1'b1;
                    end
                    IEEE_zero: begin
                        result = {z_calc[31], z_num(MAX_NORM)};
                    end
                    IEEE_pinf: begin
                        if (z_calc[31] == 1'b0) begin // Positive
                            result = {z_calc[31], z_num(INF)};
                            inf_f = 1'b1;
                        end else begin // Negative
                            result = {z_calc[31], z_num(MAX_NORM)};
                        end
                    end
                    IEEE_ninf: begin
                        if (z_calc[31] == 1'b1) begin // Negative
                            result = {z_calc[31], z_num(INF)};
                            inf_f = 1'b1;
                        end else begin // Positive
                            result = {z_calc[31], z_num(MAX_NORM)};
                        end
                    end
                    default: begin
                        result = {z_calc[31], z_num(INF)};
                        inf_f = 1'b1;
                    end
                endcase
            end
            else if (underflow) begin
                tiny_f = 1'b1;
                inexact_f = 1'b1;
                // Underflow
                case (round)
                    IEEE_near, near_maxMag, IEEE_zero: begin
                        result = {z_calc[31], z_num(ZERO)};
                        zero_f = 1'b1;
                    end
                    IEEE_pinf: begin
                        if (z_calc[31] == 1'b0) begin // Positive
                            result = {z_calc[31], z_num(MIN_NORM)};
                        end else begin
                            result = {z_calc[31], z_num(ZERO)};
                            zero_f = 1'b1;
                        end
                    end
                    IEEE_ninf: begin
                        if (z_calc[31] == 1'b1) begin // Negative
                            result = {z_calc[31], z_num(MIN_NORM)};
                        end else begin
                            result = {z_calc[31], z_num(ZERO)};
                            zero_f = 1'b1;
                        end
                    end
                    default: begin
                        result = {z_calc[31], z_num(ZERO)};
                        zero_f = 1'b1;
                    end
                endcase
            end
            else begin
                // No exceptions
                result = z_calc;
                inexact_f = inexact_bit;
            end
        end
    end

endmodule