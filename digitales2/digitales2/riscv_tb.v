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

        // Inicializar los registros: xN = N
        for (i = 0; i < 32; i = i + 1)
            uut.rf.RF[i] = i;

        // Mostrar registros importantes en tiempo de simulación
        $monitor($time,
                 " clk=%d | rst=%d | instr=%h | x4=%h | x5=%h | x6=%h | x7=%h | x8=%h",
                 clk,
                 rst,
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
        // PRUEBA 1: ADDI
        // x4 = x3 + 10
        // Esperado: x4 = 3 + 10 = 13 (0x0000000D)
        // ------------------------------------------------
        instr = 32'h00a18213; // ADDI x4, x3, 10
        $display("========================================");
        $display("PRUEBA 1: ADDI x4, x3, 10");
        $display("Esperado: x4 = 13 (0x0000000D)");

        #12;


        // ------------------------------------------------
        // PRUEBA 2: ANDI
        // x6 = x10 & 12
        // Esperado: x6 = 10 & 12 = 8 (0x00000008)
        // ------------------------------------------------
        instr = 32'h00c57313; // ANDI x6, x10, 12
        $display("========================================");
        $display("PRUEBA 2: ANDI x6, x10, 12");
        $display("Esperado: x6 = 8 (0x00000008)");

        #12;


        // ------------------------------------------------
        // PRUEBA 3: ORI
        // x8 = x10 | 12
        // Esperado: x8 = 10 | 12 = 14 (0x0000000E)
        // ------------------------------------------------
        instr = 32'h00c56413; // ORI x8, x10, 12
        $display("========================================");
        $display("PRUEBA 3: ORI x8, x10, 12");
        $display("Esperado: x8 = 14 (0x0000000E)");

        #12;


        // ------------------------------------------------
        // PRUEBA 4: XORI
        // x7 = x10 ^ 12
        // Esperado: x7 = 10 ^ 12 = 6 (0x00000006)
        // ------------------------------------------------
        instr = 32'h00c54393; // XORI x7, x10, 12
        $display("========================================");
        $display("PRUEBA 4: XORI x7, x10, 12");
        $display("Esperado: x7 = 6 (0x00000006)");

        #16;


        // Resumen final
        $display("========================================");
        $display("SIMULACION FINALIZADA");
        $display("x4 = %d (Esperado: 13)", uut.rf.RF[4]);
        $display("x6 = %d (Esperado: 8)",  uut.rf.RF[6]);
        $display("x7 = %d (Esperado: 6)",  uut.rf.RF[7]);
        $display("x8 = %d (Esperado: 14)", uut.rf.RF[8]);
        $display("========================================");

        $finish;

    end

    // Generador de reloj
    always begin
        #2 clk = ~clk;
    end

endmodule