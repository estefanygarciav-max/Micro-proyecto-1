`timescale 1ns/1ps

module riscv (
    input wire clk,
    input wire rst,
    input wire [31:0] instr,
    output wire [31:0] iaddr,
    output wire [31:0] daddr,
    output wire [31:0] ddata_out,
    input wire [31:0] ddata_in,
    output wire dwr_en,
    output wire drd_en
);

    // Asignaciones temporales para la memoria de datos (DMEM)
    assign daddr     = 32'b0;
    assign ddata_out = 32'b0;
    assign dwr_en    = 1'b0;
    assign drd_en    = 1'b0;

    // ----------------------------------------------------
    // C) UNIDAD DE FETCH Y CICLO DE INSTRUCCIÓN (3 ESTADOS)
    // ----------------------------------------------------
    reg [31:0] pc; // Contador de programa

    // Conecta el PC al bus de direcciones de la IMEM
    assign iaddr = pc;

    // Contador en anillo para los estados
    reg state_fetch, state_decode, state_execute;

    always @(negedge clk) begin
        if (rst) begin
            state_fetch   <= 1'b1;
            state_decode  <= 1'b0;
            state_execute <= 1'b0;
        end else begin
            state_fetch   <= state_execute;
            state_decode  <= state_fetch;
            state_execute <= state_decode;
        end
    end

    // Registro de instrucción (IR)
    reg [31:0] IR; 
    always @(posedge clk) begin
        if (rst)
            IR <= 32'd0;
        else if (state_fetch)
            IR <= instr; // Captura en la fase FETCH
    end

    // ----------------------------------------------------
    // DECODIFICACIÓN DE CAMPOS
    // ----------------------------------------------------
    wire [6:0] funct7 = IR[31:25];
    wire [4:0] rs2    = IR[24:20];
    wire [4:0] rs1    = IR[19:15];
    wire [2:0] funct3 = IR[14:12];
    wire [4:0] rd     = IR[11:7];
    wire [6:0] opcode = IR[6:0];

    // Validación de bits [1:0]
    wire is_valid = (opcode[1:0] == 2'b11);

    // Detección por opcode[6:2]
    wire is_i_instr = is_valid && (
                        (opcode[6:2] == 5'b00000) || 
                        (opcode[6:2] == 5'b00001) || 
                        (opcode[6:2] == 5'b00100) || 
                        (opcode[6:2] == 5'b11001)
                      );

    wire is_r_instr = is_valid && (
                        (opcode[6:2] == 5'b01100) || 
                        (opcode[6:2] == 5'b01101) || 
                        (opcode[6:2] == 5'b10100)
                      );

    wire is_s_instr = is_valid && ((opcode[6:2] == 5'b01000) || (opcode[6:2] == 5'b01001));
    wire is_b_instr = is_valid && (opcode[6:2] == 5'b11000);
    wire is_u_instr = is_valid && ((opcode[6:2] == 5'b00101) || (opcode[6:2] == 5'b01101));
    wire is_j_instr = is_valid && (opcode[6:2] == 5'b11011);

    // ----------------------------------------------------
    // D) DECODIFICACIÓN DE INSTRUCCIONES DE SALTO
    // ----------------------------------------------------
    wire is_beq  = is_b_instr && (funct3 == 3'b000);
    wire is_bne  = is_b_instr && (funct3 == 3'b001);
    wire is_blt  = is_b_instr && (funct3 == 3'b100);
    wire is_bge  = is_b_instr && (funct3 == 3'b101);
    wire is_bltu = is_b_instr && (funct3 == 3'b110);
    wire is_bgeu = is_b_instr && (funct3 == 3'b111);

    // ----------------------------------------------------
    // EXTENSOR DE SIGNO (INMEDIATO)
    // ----------------------------------------------------
    wire [31:0] imm;
    wire imm_valid;

    assign imm = is_i_instr ? {{21{IR[31]}}, IR[30:20]} :
                 is_s_instr ? {{21{IR[31]}}, IR[30:25], IR[11:7]} :
                 is_b_instr ? {{20{IR[31]}}, IR[7], IR[30:25], IR[11:8], 1'b0} :
                 is_u_instr ? {IR[31], IR[30:20], IR[19:12], 12'b0} :
                 is_j_instr ? {{12{IR[31]}}, IR[19:12], IR[20], IR[30:25], IR[24:21], 1'b0} :
                 32'b0;

    assign imm_valid = is_i_instr || is_s_instr || is_b_instr || is_u_instr || is_j_instr;

    // ----------------------------------------------------
    // DECODIFICACIÓN DE OPERACIONES ALU
    // ----------------------------------------------------
    wire [10:0] dec_bits  = {funct7[5], funct3, opcode};
    wire [9:0]  dec_bits2 = {funct3, opcode};

    wire is_add  = (dec_bits  == 11'b0_000_0110011);
    wire is_sub  = (dec_bits  == 11'b1_000_0110011);
    wire is_and  = (dec_bits  == 11'b0_111_0110011);
    wire is_or   = (dec_bits  == 11'b0_110_0110011);
    wire is_xor  = (dec_bits  == 11'b0_100_0110011);

    wire is_addi = (dec_bits2 == 10'b000_0010011);
    wire is_andi = (dec_bits2 == 10'b111_0010011);
    wire is_ori  = (dec_bits2 == 10'b110_0010011);
    wire is_xori = (dec_bits2 == 10'b100_0010011);

    // Habilitación de Escritura (Solo activa en el estado EXECUTE)
    wire wr_en_dec = is_r_instr || is_i_instr || is_u_instr || is_j_instr;

    // ----------------------------------------------------
    // CONEXIÓN DEL REGISTER FILE Y LA ALU
    // ----------------------------------------------------
    wire [31:0] src1_value;
    wire [31:0] src2_value;
    wire [31:0] alu_a;
    wire [31:0] alu_b;
    wire [31:0] alu_out;

    // Escritura condicional sincronizada con EXECUTE
    registerfile rf (
        .clk(clk),
        .wr_en(wr_en_dec & state_execute),
        .wr_index(rd),
        .wr_data(alu_out),
        .rd_index1(rs1),
        .rd_data1(src1_value),
        .rd_index2(rs2),
        .rd_data2(src2_value)
    );

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
                                  3'b100
        ),
        .ALU_out(alu_out)
    );

    // ----------------------------------------------------
    // D) COMPARADOR Y LÓGICA DEL PROGRAM COUNTER (PC)
    // ----------------------------------------------------
    // Comparaciones entre rs1 y rs2
    wire eq  = (src1_value == src2_value);
    wire ne  = (src1_value != src2_value);
    wire lt  = ($signed(src1_value) < $signed(src2_value));
    wire ge  = ($signed(src1_value) >= $signed(src2_value));
    wire ltu = (src1_value < src2_value);
    wire geu = (src1_value >= src2_value);

    // Evaluación de la condición de salto
    wire taken_br = is_beq  ? eq  :
                    is_bne  ? ne  :
                    is_blt  ? lt  :
                    is_bge  ? ge  :
                    is_bltu ? ltu :
                    is_bgeu ? geu : 1'b0;

    // Cálculo de direcciones objetivo
    wire [31:0] pc_plus_4 = pc + 32'd4;
    wire [31:0] br_tgt_pc = pc + imm;
    wire [31:0] next_pc   = (taken_br || is_j_instr) ? br_tgt_pc : pc_plus_4;

    // Actualización del PC únicamente en la fase EXECUTE
    always @(posedge clk) begin
        if (rst)
            pc <= 32'd0;
        else if (state_execute)
            pc <= next_pc;
    end

endmodule