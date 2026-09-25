`timescale 1ns / 1ps

// Definición del microcontrolador (Plantilla exactas líneas 2-37 del laboratorio)
module mcu (
    input clk, // Reloj del microcontrolador
    input rst  // Reset del microcontrolador
);

    // Buses con la memoria de programa (IMEM)
    wire [31:0] instr; // Instrucción de entrada
    wire [31:0] iaddr; // Dirección en la IMEM

    // Buses con la memoria de datos (DMEM)
    wire [31:0] daddr;    // Dirección en la DMEM
    wire [31:0] ddata_in; // Bus de datos DMEM (entrada)
    wire [31:0] ddata_out;// Bus de datos DMEM (salida)
    wire dwr_en;          // Señales del bus de control DMEM
    wire drd_en;

    // Instancia del microprocesador RISCV
    riscv cpu (
        .rst(rst),
        .clk(clk),
        .instr(instr),
        .iaddr(iaddr),
        .daddr(daddr),
        .ddata_in(ddata_in),
        .ddata_out(ddata_out),
        .dwr_en(dwr_en),
        .drd_en(drd_en)
    );

    // Instancia de la memoria de programa
    rom4096x32 IMEM (
        .data(instr),
        .addr(iaddr[13:2])
    );

endmodule


// Declaración de la memoria ROM de programa (Plantilla líneas 41-45 + Programa do..while)
module rom4096x32 (
    input wire [11:0] addr,  // Dirección de 12 bits (4096 palabras de 32 bits)
    output reg [31:0] data   // Datos/Instrucción de 32 bits
);

    always @(*) begin
        case (addr)
            12'd0: data = 32'h000001B3; // add x3, x0, x0
            12'd1: data = 32'h000002B3; // add x5, x0, x0
            12'd2: data = 32'h00500313; // addi x6, x0, 5
            12'd3: data = 32'h005281B3; // do1: add x3, x3, x5
            12'd4: data = 32'h00128293; // addi x5, x5, 1
            12'd5: data = 32'hFE62CCE3; // blt x5, x6, do1 (salto relativo hacia atrás)
            12'd6: data = 32'h00018613; // finwhile: add x12, x3, x0
            default: data = 32'h00000013; // NOP (addi x0, x0, 0)
        endcase
    end

endmodule