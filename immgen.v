module IMMGEN(instr, immediate);
input [31:0] instr;
output signed [31:0] immediate;

reg [11:0] temp_imm;

// get opcode
assign opcode = instr[6:0];

// get immediate based on opcode
always @*
begin // remember to account for JAL and JALR
	if (instr[6] & ~instr[2]) temp_imm = {instr[31], instr[7], instr[30:25], instr[11:8]}; // BNE and BEQ
	else if (~instr[4] & instr[3]) temp_imm = {instr[31], instr[19:12], instr[20], instr[30:21]}; // JAL
	else if (~instr[6] & instr[5] & ~instr[4]) temp_imm = {instr[31:25], instr[11:7]}; // SW
	else temp_imm = instr[31:20]; // R-type and I-type
end

// sign extend to get final immediate
assign immediate = $signed(temp_imm);
endmodule