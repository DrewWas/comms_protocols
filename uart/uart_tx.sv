
 `timescale 1ns/10ps

module tx #(
    parameter CLK_FRQ=50000000, // Clk frequency = 50MHz
    parameter BAUD_RATE=115200, //115,200 bits/sec
    parameter REG_WIDTH=10
) (
    input logic clk,
    input logic areset,
    input logic data_loaded,
    input logic [7:0] data_in,
    output logic data_out,
    output logic tx_done,
    output logic tx_busy

);

    // ENSURE data_loaded is only enabled once per clk
    logic prev_data_loaded;
    logic data_loaded_pos_edge;
    always_ff @(posedge clk) begin
        prev_data_loaded <= data_loaded;
        data_loaded_pos_edge <= (data_loaded && !prev_data_loaded);
    end

    // Baud rate ticker 
    localparam int BAUD_DIV = CLK_FRQ / BAUD_RATE;
    logic baud_high; 
    logic [31:0] clk_counter; 
    always_ff @(posedge clk or posedge areset) begin
        if (areset) begin
            clk_counter <= '0;
            baud_high <= 0;
        end else if (32'(clk_counter) == 32'(BAUD_DIV - 1)) begin
            baud_high <= 1'b1;
            clk_counter <= '0;
        end else begin
            clk_counter <= clk_counter + 1;
            baud_high <= 1'b0;
        end
    end
    

    
    // Initialization stuff
    logic state;
    localparam START=1'd0, TRANSMIT=1'd1;
    localparam START_BIT=1'b0, STOP_BIT=1'b1;

    // Shift register 
    // 10 bytes -> 1 start bit, 8 data bits, 1 stop bit
    logic [REG_WIDTH-1:0] shift_reg;

    // Bit counter 
    logic [$clog2(REG_WIDTH + 1) - 1:0] counter; 

    // Control FSM
    always_ff @(posedge clk or posedge areset) begin
        if (areset) begin
            state <= START;
            tx_done <= 0;
            tx_busy <= 0;
            counter <= 0;
            data_out <= 1;
            shift_reg <= {REG_WIDTH{1'b0}};
        end else if (baud_high) begin
            case (state)

            START : begin
                tx_busy <= 0;
                if (data_loaded_pos_edge) begin
                    tx_done <= 0;
                    shift_reg <= {STOP_BIT, data_in, START_BIT};
                    state <= TRANSMIT;
                end
            end

            TRANSMIT : begin
                if (counter == REG_WIDTH) begin
                    counter <= 0;
                    tx_done <= 1;
                    tx_busy <= 0;
                    state <= START;
                    data_out <= 1;
                end else begin
                    tx_busy <= 1;
                    data_out <= shift_reg[0];
                    shift_reg <= shift_reg >> 1;
                    counter <= counter + 1;
                end
            end
            default : begin
                tx_done <= 0;
                data_out <= 1;
                state <= START;
                tx_busy <= 0;
            end
            endcase
        end
    end


endmodule



