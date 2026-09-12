`timescale 1ns/1ps

module tb_riscv;

    // Señales de prueba
    reg [31:0] instr;
    reg clk;
    reg rst;

    // Instancia del procesador
    riscv uut (
        .clk(clk),
        .rst(rst),
        .instr(instr)
    );

    integer i;

    initial begin

        // Archivo de simulación
        $dumpfile("tb_riscv.vcd");
        $dumpvars(0, tb_riscv);

        // Guardar todos los registros
        for (i = 0; i < 32; i = i + 1)
            $dumpvars(0, uut.rf.RF[i]);

        // Inicializar los registros
        // xN = N
        for (i = 0; i < 32; i = i + 1)
            uut.rf.RF[i] = i;

        // Mostrar registros importantes
        $monitor($time,
                 " clk=%d | instr=%h | x4=%h | x5=%h | x6=%h | x7=%h | x8=%h",
                 clk,
                 instr,
                 uut.rf.RF[4],
                 uut.rf.RF[5],
                 uut.rf.RF[6],
                 uut.rf.RF[7],
                 uut.rf.RF[8]);

        // Estado inicial
        #0;
        clk = 0;
        rst = 1;
        instr = 32'b0;

        // Liberar reset
        #3;
        rst = 0;


        // ------------------------------------------------
        // PRUEBA 1: ADD
        // x4 = x3 + x2
        // x4 = 3 + 2 = 5
        // ------------------------------------------------

        instr = 32'b0000000_00010_00011_000_00100_0110011;
        $display("ADD x4, x3, x2");

        #12;


        // ------------------------------------------------
        // PRUEBA 2: SUB
        // x5 = x3 - x2
        // x5 = 3 - 2 = 1
        // ------------------------------------------------

        instr = 32'b0100000_00010_00011_000_00101_0110011;
        $display("SUB x5, x3, x2");

        #12;


        // ------------------------------------------------
        // PRUEBA 3: AND
        // x6 = x10 & x12
        // 10 & 12 = 8
        // ------------------------------------------------

        instr = 32'b0000000_01100_01010_111_00110_0110011;
        $display("AND x6, x10, x12");

        #12;


        // ------------------------------------------------
        // PRUEBA 4: OR
        // x8 = x10 | x12
        // 10 | 12 = 14
        // ------------------------------------------------

        instr = 32'b0000000_01100_01010_110_01000_0110011;
        $display("OR x8, x10, x12");

        #12;


        // ------------------------------------------------
        // PRUEBA 5: XOR
        // x7 = x10 ^ x12
        // 10 ^ 12 = 6
        // ------------------------------------------------

        instr = 32'b0000000_01100_01010_100_00111_0110011;
        $display("XOR x7, x10, x12");

        #16;


        // Fin de la simulación
        $finish;

    end


    // Generador de reloj
    always begin
        #2 clk = ~clk;
    end

endmodule