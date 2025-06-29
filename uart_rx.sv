
module rx #(
    parameter CLK_FRQ=250000000, // Clk frequency = 250MHz
    parameter BAUD_RATE=115200,  // 115,200 bits/sec
    parameter BYTE=8
) (
    input logic clk,
    input logic areset,
    input logic data_in,

    output logic rx_open,
    output logic [BYTE-1:0] rx_saved
    
);
    

    // Baud rate ticker 
    localparam int BAUD_DIV = CLK_FRQ / BAUD_RATE;
    logic baud_high; 
    logic [$clog2(BAUD_DIV)-1:0] clk_counter;
    always_ff @(posedge clk or posedge areset) begin
        if (areset) begin
            clk_counter <= '0;
            baud_high <= 0;
        end else if (clk_counter == BAUD_DIV - 1) begin
            baud_high <= 1'b1;
            clk_counter <= '0;
        end else begin
            clk_counter <= clk_counter + 1;
            baud_high <= 1'b0;
        end
    end

    // Initialization stuff
    logic [1:0] state;
    localparam IDLE=2'd0, RECIEVING=2'd1, DONE=2'd2;
    localparam START_BIT=1'b0, STOP_BIT=1'b1;

    logic [BYTE-1:0] buffer;

    always_ff @(posedge clk or posedge areset) begin
        if (areset) begin
            counter <= 0;
            state <= IDLE;
            buffer <= '0;
            rx_open <= 1;

        end else if (baud_high) begin
            case (state)
            IDLE : begin
                rx_open <= 1;
                if (START_BIT) begin
                    state <= RECIEVING;
                    counter <= 0;
                end
            end

            RECIEVING : begin
                rx_open <= 0;
                if (counter == 8 && STOP_BIT) begin
                    counter <= 0;
                    state <= DONE;
                end else if (counter >= 8 && !STOP_BIT) begin
                    // If buffer is full but no stop bit ignore and stay in state
                    pass;
                end else begin
                    buffer[counter] <= data_in;
                    counter <= counter + 1;
                end

            end

            DONE : begin
                rx_saved <= buffer;
                rx_open <= 1;
                state <= IDLE;
            end

            default : begin
                state <= IDLE;
                counter <= '0;
                rx_open <= 1;
                buffer <= '0;
                rx_saved <= {BYTE{1'b1}};
            end

            endcase
        end
    end



endmodule



