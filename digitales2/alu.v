module alu (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [2:0]  op,
    output wire [31:0] ALU_out
);

    assign ALU_out =
        (op == 3'b000) ? (a + b) :
        (op == 3'b001) ? (a - b) :
        (op == 3'b010) ? (a & b) :
        (op == 3'b011) ? (a | b) :
        (op == 3'b100) ? (a ^ b) :
                         32'd0;

endmodule