module riscv (
    input wire clk,
    input wire rst,
    input wire [31:0] instr
);

    // ------------------------------------------------
    // REGISTRO DE INSTRUCCIÓN
    // ------------------------------------------------

    reg [31:0] IR;

    always @(posedge clk) begin
        IR <= instr;
    end


    // ------------------------------------------------
    // CAMPOS DE LA INSTRUCCIÓN TIPO R
    // ------------------------------------------------

    wire [6:0] funct7;
    wire [4:0] rs2;
    wire [4:0] rs1;
    wire [2:0] funct3;
    wire [4:0] rd;
    wire [6:0] opcode;

    assign funct7 = IR[31:25];
    assign rs2    = IR[24:20];
    assign rs1    = IR[19:15];
    assign funct3 = IR[14:12];
    assign rd     = IR[11:7];
    assign opcode = IR[6:0];


    // ------------------------------------------------
    // SEÑALES DEL REGISTER FILE
    // ------------------------------------------------

    wire [31:0] src1_value;
    wire [31:0] src2_value;

    wire [31:0] alu_a;
    wire [31:0] alu_b;
    wire [31:0] alu_out;


    // ------------------------------------------------
    // DECODIFICACIÓN DE INSTRUCCIONES
    // ------------------------------------------------

    wire [10:0] dec_bits;

    wire is_add;
    wire is_sub;
    wire is_and;
    wire is_or;
    wire is_xor;

    assign dec_bits = {funct7[5], funct3, opcode};

    // ADD
    assign is_add = (dec_bits == 11'b0_000_0110011);

    // SUB
    assign is_sub = (dec_bits == 11'b1_000_0110011);

    // AND
    assign is_and = (dec_bits == 11'b0_111_0110011);

    // OR
    assign is_or = (dec_bits == 11'b0_110_0110011);

    // XOR
    assign is_xor = (dec_bits == 11'b0_100_0110011);


    // ------------------------------------------------
    // HABILITACIÓN DE ESCRITURA
    // ------------------------------------------------

    wire wr_en;

    assign wr_en = is_add |
                   is_sub |
                   is_and |
                   is_or  |
                   is_xor;


    // ------------------------------------------------
    // REGISTER FILE
    // ------------------------------------------------

    registerfile rf (
        .clk(clk),
        .wr_en(wr_en),
        .wr_index(rd),
        .wr_data(alu_out),

        .rd_index1(rs1),
        .rd_data1(src1_value),

        .rd_index2(rs2),
        .rd_data2(src2_value)
    );


    // ------------------------------------------------
    // ENTRADAS DE LA ALU
    // ------------------------------------------------

    assign alu_a = src1_value;
    assign alu_b = src2_value;


    // ------------------------------------------------
    // ALU
    // ------------------------------------------------

    alu rv_alu (
        .a(alu_a),
        .b(alu_b),

        .op(
            is_add ? 3'b000 :
            is_sub ? 3'b001 :
            is_and ? 3'b010 :
            is_or  ? 3'b011 :
                     3'b100
        ),

        .ALU_out(alu_out)
    );

endmodule