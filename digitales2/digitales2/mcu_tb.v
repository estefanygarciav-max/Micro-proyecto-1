`timescale 1ns/1ps

// Test bench para el microcontrolador
module mcu_tb;

    // Señales de prueba
    reg clk;
    reg rst;

    // Instancia del microcontrolador
    mcu mcuuq (
        .rst(rst),
        .clk(clk)
    );

    integer i;

    // Bloque inicial: aplica estímulos
    initial begin
        // Configurar la generación de archivos de volcado para GTKWave
        $dumpfile("tb_mcu.vcd");
        $dumpvars(0, mcu_tb);

        // Guarda el valor de los 32 registros del Register File para verlos en la onda
        for (i = 0; i < 32; i = i + 1) 
            $dumpvars(0, mcuuq.cpu.rf.RF[i]);

        #0; 
        clk = 0;
        rst = 1;

        #93; 
        rst = 0; // Libera el reset para empezar a ejecutar el programa

        #400; // Termina después de aproximadamente 60 ciclos de reloj

        #16;
        // Fin de la simulación
        $finish;
    end

    // Generación de la señal de reloj (Periodo = 4ns)
    always begin
        #2 clk = !clk;
    end

endmodule