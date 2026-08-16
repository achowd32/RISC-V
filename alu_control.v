module ALU_CONTROL(instr, aluop, opcode);
input [31:0] instr;
input [1:0] aluop;
output [2:0] opcode;

assign opcode[0] = ~aluop[0] & ((aluop[1] & ((instr[30] & instr[5]) | (instr[13] & instr[12]))) | ~aluop[1]);
assign opcode[1] = (aluop[1] & ~aluop[0]) & ((instr[25] & instr[5]) | instr[12]);
assign opcode[2] = (aluop[1] & ~aluop[0]) & ((instr[13] & ~instr[12]) | ~instr[13] & instr[12]);

endmodule