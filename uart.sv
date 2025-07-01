

module uart #(
    parameter BYTE=8
) (
    input logic clk,
    input logic areset,
    input logic data_in_rx,

    output logic tx_done,
    output logic tx_busy, 
    output logic rx_open,
    output logic rx_valid,
    output logic [BYTE-1:0] rx_saved,
    output logic data_out

);


    // This currently implements a loopback (straight from rx into tx)
    // Typically there would be some intermediary computation

    tx uart_tx(
        .clk(clk),
        .areset(areset),
        .data_loaded(rx_valid),
        .data_in(rx_saved),
        .data_out(data_out),
        .tx_done(tx_done),
        .tx_busy(tx_busy)
    );

    rx uart_rx (
        .clk(clk),
        .areset(areset),
        .data_in(data_in_rx),
        .rx_open(rx_open),
        .rx_valid(rx_valid),
        .rx_saved(rx_saved)
    );


    
endmodule


