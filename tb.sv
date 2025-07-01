
// `timescale 1ns/10ps

module tb;

    // Inputs
    logic clk = 0;
    logic areset;
    logic data_in_rx;

    // Outputs 
    logic tx_busy;
    logic tx_done;
    logic rx_open;
    logic rx_valid;
    logic [7:0] rx_saved;
    logic data_out;

    uart uart_instantiation(
        .*
    );

    // UART Baud: 115200 = 8680 ns per bit
    int baud_period = 8680;

    // Tasks
    task send_uart_byte(input [7:0] send_byte);
        data_in_rx = 0; // Start bit
        #(baud_period);

        for (int i = 0; i < 8; i++) begin
            data_in_rx = send_byte[i];
            #(baud_period);
        end

        data_in_rx = 1; // Stop bit
        #(baud_period);
        
    endtask

    task read_uart_byte(output [7:0] out_byte);
        wait(data_out == 0); // Wait for start bit
        #(baud_period + (baud_period / 2));
        
        for (int i = 0; i < 8; i++) begin
            out_byte[i] = data_out;
            #(baud_period);
        end

    endtask




    always #5 clk = ~clk;

    initial begin
        areset = 1;
        data_in_rx = 1; // Idle
        #20;
        areset = 0;

        $display("Sending byte 0x5A to RX ...");
        send_uart_byte(8'h5A);

        wait(rx_valid) 
        $display("RX recieved: 0x%0h", rx_saved);


        $finish;
    end



endmodule



