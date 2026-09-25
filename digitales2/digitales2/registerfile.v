module registerfile(
    input  wire        clk,
    input  wire        wr_en,
    input  wire [4:0]  wr_index,
    input  wire [31:0] wr_data,

    input  wire [4:0]  rd_index1,
    input  wire [4:0]  rd_index2,

    output wire [31:0] rd_data1,
    output wire [31:0] rd_data2
);

    // Banco de 32 registros de 32 bits
    reg [31:0] RF [0:31];

    integer i;

    // Inicialización para simulación
    initial begin
        for (i = 0; i < 32; i = i + 1)
            RF[i] = 32'd0;
    end

    // Escritura síncrona
    always @(posedge clk) begin
        if (wr_en && (wr_index != 5'd0))
            RF[wr_index] <= wr_data;

        // x0 siempre permanece en cero
        RF[0] <= 32'd0;
    end

    // Lectura combinacional
    assign rd_data1 = (rd_index1 == 5'd0) ? 32'd0 : RF[rd_index1];
    assign rd_data2 = (rd_index2 == 5'd0) ? 32'd0 : RF[rd_index2];

endmodule