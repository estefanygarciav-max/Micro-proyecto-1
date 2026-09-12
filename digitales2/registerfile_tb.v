`timescale 1ns / 1ps

module registerfile_tb;

    // Entradas
    reg clk;
    reg wr_en;
    reg [4:0] wr_index;
    reg [31:0] wr_data;
    reg [4:0] rd_index1;
    reg [4:0] rd_index2;

    // Salidas
    wire [31:0] rd_data1;
    wire [31:0] rd_data2;

    // Instancia del Register File
    RegisterFile DUT (
        .clk(clk),
        .wr_en(wr_en),
        .wr_index(wr_index),
        .wr_data(wr_data),
        .rd_index1(rd_index1),
        .rd_index2(rd_index2),
        .rd_data1(rd_data1),
        .rd_data2(rd_data2)
    );

    // Generación del reloj (Periodo = 10 ns)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Estímulos
    initial begin

        // Inicialización
        wr_en = 0;
        wr_index = 0;
        wr_data = 0;
        rd_index1 = 0;
        rd_index2 = 0;

        #10;

        //----------------------------------------------------
        // Escribir 100 en x5
        //----------------------------------------------------
        wr_en = 1;
        wr_index = 5;
        wr_data = 32'd100;

        #10;

        wr_en = 0;
        rd_index1 = 5;

        #10;

        //----------------------------------------------------
        // Escribir 250 en x10
        //----------------------------------------------------
        wr_en = 1;
        wr_index = 10;
        wr_data = 32'd250;

        #10;

        wr_en = 0;
        rd_index2 = 10;

        #10;

        //----------------------------------------------------
        // Leer dos registros al mismo tiempo
        //----------------------------------------------------
        rd_index1 = 5;
        rd_index2 = 10;

        #10;

        //----------------------------------------------------
        // Intentar escribir en x0
        //----------------------------------------------------
        wr_en = 1;
        wr_index = 0;
        wr_data = 32'hFFFFFFFF;

        #10;

        wr_en = 0;
        rd_index1 = 0;

        #10;

        //----------------------------------------------------
        // Escribir en x20
        //----------------------------------------------------
        wr_en = 1;
        wr_index = 20;
        wr_data = 32'h12345678;

        #10;

        wr_en = 0;
        rd_index1 = 20;

        #10;

        //----------------------------------------------------
        // Finalizar simulación
        //----------------------------------------------------
        $finish;

    end

    // Monitoreo de señales
    initial begin
        $display("Tiempo\twr_en\twr_index\twr_data\t\trd_index1\trd_data1\t\trd_index2\trd_data2");
        $monitor("%0t\t%b\t%d\t\t%h\t%d\t\t%h\t%d\t\t%h",
                  $time, wr_en, wr_index, wr_data,
                  rd_index1, rd_data1,
                  rd_index2, rd_data2);
    end

endmodule