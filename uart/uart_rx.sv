
 `timescale 1ns/10ps

module rx #(
    parameter CLK_FRQ=250000000, // Clk frequency = 250MHz
    parameter BAUD_RATE=115200,  // 115,200 bits/sec
    parameter BYTE=8
) (
    input logic clk,
    input logic areset,
    input logic data_in,

    output logic rx_open,
    output logic rx_valid,
    output logic [BYTE-1:0] rx_saved
    
);
    // Ensure we only transition to recieving if we get a proper START_BIT
    logic prev_data_in;
    logic data_in_val;
    always_ff @(posedge clk) begin
        prev_data_in <= data_in;
        data_in_val <= (!data_in && prev_data_in);
    end

    // Baud rate ticker 
    localparam int BAUD_DIV = CLK_FRQ / BAUD_RATE;
    logic baud_high; 
    int clk_counter;
    int half_counter;
    always_ff @(posedge clk or posedge areset) begin
        if (areset) begin
            clk_counter <= '0;
            baud_high <= 0;
        end else if (32'(clk_counter) == BAUD_DIV - 1) begin
            baud_high <= 1'b1;
            clk_counter <= '0;
        end else begin
            clk_counter <= clk_counter + 1;
            baud_high <= 1'b0;
        end
    end

    // Initialization stuff
    logic [1:0] state;
    logic [3:0] counter;
    localparam IDLE=2'd0, RECIEVING=2'd1, WAIT_HALF=2'd2, DONE=2'd3;
    localparam START_BIT=1'b0, STOP_BIT=1'b1;

    logic [BYTE-1:0] buffer;

    always_ff @(posedge clk or posedge areset) begin
        if (areset) begin
            counter <= 0;
            state <= IDLE;
            buffer <= '0; 
            rx_saved <= '0;
            half_counter <= 0;
            rx_open <= 1;
            rx_valid <= 0;

        end else begin
            case (state)
            IDLE : begin
                rx_open <= 1;
                rx_valid <= 0;
                if (data_in_val) begin
                    state <= WAIT_HALF;
                    counter <= 0;
                    half_counter <= 0;
                    buffer <= '0;
                end
            end

            WAIT_HALF : begin
                half_counter <= half_counter + 1;
                rx_open <= 1;
                rx_valid <= 0;
                if (32'(half_counter) >= (BAUD_DIV >> 1)) begin
                    half_counter <= 0;
                    state <= RECIEVING;
                end
            end

            RECIEVING : begin
                if (baud_high) begin
                    rx_open <= 0;
                    rx_valid <= 0;
                    if (counter == 8 && (data_in == STOP_BIT)) begin
                        counter <= 0;
                        state <= DONE;
                    end else if (counter >= 8 && (data_in != STOP_BIT)) begin
                        // If buffer is full but no stop bit ignore and stay in state
                        counter <= '0;
                        state <= IDLE;
                    end else begin
                        buffer[counter[2:0]] <= data_in; // CHECK HERE FOR FUCKED UP INDEXING (might be dropping LSB instead of MSB)
                        counter <= counter + 1;
                    end
                end

            end

            DONE : begin
                if (baud_high) begin
                    rx_saved <= buffer;
                    rx_valid <= 1;
                    rx_open <= 1;
                    state <= IDLE;
                end
            end

            default : begin
                state <= IDLE;
                counter <= '0;
                rx_open <= 1;
                buffer <= '0;
                rx_valid <= 0;
            end

            endcase
        end
    end



endmodule



