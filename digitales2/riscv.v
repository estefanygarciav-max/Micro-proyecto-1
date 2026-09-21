module riscv (
    input wire clk,
    input wire rst,
    input wire [31:0] instr
);

    // ------------------------------------------------
    // REGISTRO DE INSTRUCCIÓN (IR)
    // ------------------------------------------------
    reg [31:0] IR;

    always @(posedge clk) begin
        if (rst)
            IR <= 32'b0;
        else
            IR <= instr;
    end

    // ------------------------------------------------
    // DECODIFICACIÓN DE CAMPOS
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
    // TIPOS DE INSTRUCCIÓN SEGÚN OPCODE[6:2] 
    // ------------------------------------------------
    wire is_r_instr;
    wire is_i_instr;
    wire is_s_instr;
    wire is_b_instr;
    wire is_u_instr;
    wire is_j_instr;
    wire is_valid;

    // Validación de bits [1:0] (Deben ser 2'b11 según la guía)
    assign is_valid = (opcode[1:0] == 2'b11);

    // Detección por opcode[6:2]
    assign is_i_instr = is_valid && (
                            (opcode[6:2] == 5'b00000) || // Load
                            (opcode[6:2] == 5'b00001) || // Fence
                            (opcode[6:2] == 5'b00100) || // OP-IMM (addi, andi, etc.)
                            (opcode[6:2] == 5'b11001)    // JALR
                        );

    assign is_r_instr = is_valid && (
                            (opcode[6:2] == 5'b01100) || // OP (add, sub, etc.)
                            (opcode[6:2] == 5'b01101) || 
                            (opcode[6:2] == 5'b10100)
                        );

    assign is_s_instr = is_valid && ((opcode[6:2] == 5'b01000) || (opcode[6:2] == 5'b01001));
    assign is_b_instr = is_valid && (opcode[6:2] == 5'b11000);
    assign is_u_instr = is_valid && ((opcode[6:2] == 5'b00101) || (opcode[6:2] == 5'b01101));
    assign is_j_instr = is_valid && (opcode[6:2] == 5'b11011);

    // ------------------------------------------------
    // EXTENSOR DE SIGNO (INMEDIATO)
    // ------------------------------------------------
    wire [31:0] imm;
    wire imm_valid;

    assign imm = is_i_instr ? {{21{IR[31]}}, IR[30:20]} :
                 is_s_instr ? {{21{IR[31]}}, IR[30:25], IR[11:7]} :
                 is_b_instr ? {{20{IR[31]}}, IR[7], IR[30:25], IR[11:8], 1'b0} :
                 is_u_instr ? {IR[31], IR[30:20], IR[19:12], 12'b0} :
                 is_j_instr ? {{12{IR[31]}}, IR[19:12], IR[20], IR[30:25], IR[24:21], 1'b0} :
                 32'b0;

    assign imm_valid = is_i_instr || is_s_instr || is_b_instr || is_u_instr || is_j_instr;

    // ------------------------------------------------
    // DECODIFICACIÓN DE OPERACIONES ALU
    // ------------------------------------------------
    wire [10:0] dec_bits;
    wire [9:0]  dec_bits2;

    wire is_add, is_sub, is_and, is_or, is_xor;
    wire is_addi, is_andi, is_ori, is_xori;

    assign dec_bits  = {funct7[5], funct3, opcode};
    assign dec_bits2 = {funct3, opcode};

    // Instrucciones R
    assign is_add = (dec_bits == 11'b0_000_0110011);
    assign is_sub = (dec_bits == 11'b1_000_0110011);
    assign is_and = (dec_bits == 11'b0_111_0110011);
    assign is_or  = (dec_bits == 11'b0_110_0110011);
    assign is_xor = (dec_bits == 11'b0_100_0110011);

    // Instrucciones I
    assign is_addi = (dec_bits2 == 10'b000_0010011);
    assign is_andi = (dec_bits2 == 10'b111_0010011);
    assign is_ori  = (dec_bits2 == 10'b110_0010011);
    assign is_xori = (dec_bits2 == 10'b100_0010011);

    // Habilitación de Escritura (wr_en)
    wire wr_en;
    assign wr_en = is_r_instr || is_i_instr || is_u_instr || is_j_instr;

    // ------------------------------------------------
    // CONEXIÓN DEL REGISTER FILE Y LA ALU
    // ------------------------------------------------
    wire [31:0] src1_value;
    wire [31:0] src2_value;
    wire [31:0] alu_a;
    wire [31:0] alu_b;
    wire [31:0] alu_out;

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

    // Selección de la entrada B de la ALU
    assign alu_a = src1_value;
    assign alu_b = imm_valid ? imm : src2_value;

    alu rv_alu (
        .a(alu_a),
        .b(alu_b),
        .op(
            (is_add || is_addi) ? 3'b000 :
            (is_sub)            ? 3'b001 :
            (is_and || is_andi) ? 3'b010 :
            (is_or  || is_ori)  ? 3'b011 :
                                  3'b100  // XOR / XORI
        ),
        .ALU_out(alu_out)
    );

endmodule