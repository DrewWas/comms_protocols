
module tx #(
    parameter CLK_FRQ=50000000, // Clk frequency = 50MHz
    parameter BAUD_RATE=115200, //115,200 bits/sec
    parameter REG_WIDTH=10
) (
    input logic clk,
    input logic areset,
    input logic data_loaded,
    input logic [7:0] data_in,
    output logic data_out

);

    // ENSURE data_loaded is only enabled once per clk
    logic prev_data_loaded;
    logic data_loaded_pos_edge;
    always_ff @(posedge clk) begin
        prev_data_loaded <= data_loaded;
        data_loaded_pos_edge <= (data_loaded && !prev_data_loaded);
    end

    // Baud rate ticker (drive on 433 bc clk_freq / baud_rate = 433)
    logic baud_high;
    logic [8:0] clk_counter; // 9 bits wide bc log2(433) < 9;
    always_ff @(posedge clk) begin
        if (clk_counter >= 433) begin
            baud_high <= 1'b1;
            clk_counter <= '0;
        end else begin
            clk_counter <= clk_counter + 1;
            baud_high <= 1'b0;
        end
    end
    

    
    // Initialization stuff
    logic [1:0] state;
    localparam IDLE=2'd0, START=2'd1, TRANSMIT=2'd2, DONE=3'd3;
    localparam START_BIT=1'b0, STOP_BIT=1'b1;

    // Shift register 
    // 10 bytes -> 1 start bit, 8 data bits, 1 stop bit
    logic [REG_WIDTH-1:0] shift_reg;

    // Bit counter 
    int counter;

    // Control FSM
    always_ff @(posedge clk or posedge areset) begin
        if (areset) begin
            state <= START;
            counter <= 0;
            shift_reg <= {REG_WIDTH{1'b0}};
        end else if (baud_high) begin
            case (state)

            START : begin
                if (data_loaded_pos_edge) begin
                    shift_reg <= {START_BIT, data_in, STOP_BIT};
                    state <= TRANSMIT;
                end else begin
                    shift_reg <= {REG_WIDTH{1'b0}};
                    state <= START;
                end
            end

            TRANSMIT : begin
                if (counter == REG_WIDTH) begin
                    counter <= 0;
                    state <= DONE;
                end else begin
                    data_out <= shift_reg[0];
                    shift_reg <= shift_reg >> 1;
                    counter <= counter + 1;
                    state <= TRANSMIT;
                end
            end

            DONE : begin

            end

            endcase
        end
    end



endmodule



