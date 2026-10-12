module CONTROL(instr, memtoreg, regwrite, memwrite, aluop);
input [31:0] instr;
output memtoreg, regwrite, memwrite;
output [1:0] aluop;

// R-format = 0110011
// I-format = 0010011
// LW       = 0000011
// SW       = 0100011
// BEQ      = 1100011
// BNE      = 1100011
// JAL      = 1101111
// JALR     = 1100111

assign memtoreg = ~instr[5] & ~instr[4]; // 0000011
assign regwrite = (~instr[6] & (~instr[5] | (instr[5] & instr[4]))) | instr[2]; // 0110011; 0010011; 0000011; 1101111; 1100111
assign memwrite = ~instr[6] & instr[5] & ~instr[4];
assign aluop = {instr[4], (~instr[6] & ~instr[4]) | (~instr[3] & instr[2])};

endmodule