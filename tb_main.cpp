#include <verilated.h>
#include "Vtb.h"

int main(int argc, char** argv) {

    Verilated::commandArgs(argc, argv);
    Vtb* tb = new Vtb;

    while (!Verilated::gotFinish()) {
        tb->eval();
        Verilated::timeInc(1);
    }

    delete tb;
    return 0;
}


