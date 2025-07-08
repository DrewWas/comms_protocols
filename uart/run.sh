
verilator --cc --exe --build --timing uart_rx.sv uart_tx.sv uart.sv tb.sv tb_main.cpp --top-module tb
./obj_dir/Vtb
rm -rf obj_dir


