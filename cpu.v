`timescale 1 ps / 1 ps

module cpu (
	input clk
);

reg [31:0] pc, pc_f, pc_ff;

// ----------- CLOCKS -----------  
wire outclock_0, outclock_1;
assign outclock_0 = clk;
assign outclock_1 = ~outclock_0;

integer i;
reg [31:0] rom [23:0];
initial begin
	regwrite_f = 0;
	regwrite_ff = 0;
	rout_1f = 0;
	rout_2f = 0;
	
	// factorial
	rom[0] = 32'h00600513; // addi x10, x0, 6
	rom[1] = 32'h00c000ef; // jal x1, 12 (to rom[4])
	rom[2] = 32'h00a02023; // sw x10, 0(x0)
	rom[3] = 32'h0000007f; // HALT
	rom[4] = 32'hff810113; // addi x2, x2, -8
	rom[5] = 32'h00112223; // sw x1, 4(x2)
	rom[6] = 32'h00a12023; // sw x10, 0(x2)
	rom[7] = 32'h00100293; // addi x5, x0, 1
	rom[8] = 32'h00551863; // bne x10, x5, 16 (to rom[12])
	rom[9] = 32'h00100513; // addi x10, x0, 1
	rom[10] = 32'h00810113; // addi x2, x2, 8
	rom[11] = 32'h00008067; // jalr x0, 0(x1)
	rom[12] = 32'hfff50513; // addi x10, x10, -1
	rom[13] = 32'hfddff0ef; // jal x1, -36 (to rom[4])
	rom[14] = 32'h00012303; // lw x6, 0(x2)
	rom[15] = 32'h00412083; // lw x1, 4(x2)
	rom[16] = 32'h00810113; // addi x2, x2, 8
	rom[17] = 32'h02650533; // mul x10, x10, x6
	rom[18] = 32'h00008067; // jalr x0, 0(x1)
	
end

reg [31:0] wdata;
// ---------------------- STAGE 1: FETCH AND DECODE ----------------------  
// ----------- FETCH INSTRUCTION -----------  
wire [31:0] addr = pc >> 2; // pc / 4
wire [31:0] instr = rom[addr];

// ----------- REGISTERS & RF -----------  
wire regwrite;
wire [31:0] rout_1, rout_2;

// decode instruction into register relevant components
wire [4:0] wreg = instr[11:7]; // register to write to
wire [4:0] rreg_1 = instr[19:15]; // first register to read from
wire [4:0] rreg_2 = instr[24:20]; // second register to read from

RF rf (
	.clk(outclock_0),       // clk
	.rreg_1(rreg_1),	    // read reg 1 
	.rreg_2(rreg_2),		// read reg 2
	.wreg(wreg_ff),			// write reg (ff)
	.wdata(wdata),			// write data
	.wenable(regwrite_ff),  // enable reg write
	.rout_1(rout_1),		// read out 1
	.rout_2(rout_2)			// read out 2
);

// ----------- IMMEDIATE GENERATOR -----------  
wire [31:0] imm;
IMMGEN immgen(.instr(instr), .immediate(imm));

// ----------- CONTROL UNIT -----------  
wire alusrc, memtoreg, memwrite, beq, bne, jal, jalr, halt;
wire [1:0] aluop;
CONTROL control(.instr(instr),
				.memtoreg(memtoreg),
				.regwrite(regwrite),
				.memwrite(memwrite), 
				.aluop(aluop));

assign alusrc = (~instr[6] & (~instr[5] | (instr[5] & ~instr[4]))) | jalr;
assign beq = ~instr[12] & instr[6] & ~instr[2];
assign bne = instr[12] & instr[6] & ~instr[2];
assign jal = ~instr[4] & instr[3];
assign jalr = ~instr[3] & instr[2];
assign halt = instr[4] & instr[3];

// ---------------------- TRANSITION 1 ----------------------  
reg [31:0] imm_f, instr_f;
reg [4:0] wreg_f, rreg_1f, rreg_2f;
reg regwrite_f;
reg [31:0] rout_1f, rout_2f;
reg alusrc_f, memtoreg_f, memwrite_f, beq_f, bne_f, jal_f, jalr_f, halt_f;
reg [1:0] aluop_f; 
wire flush;

always @(posedge outclock_0) begin
	// forward immediate through the pipeline stages
	imm_f <= imm;
	
	// forward the read register addresses
	rreg_1f <= rreg_1;
	rreg_2f <= rreg_2;

	// forward the read register ouputs
	rout_1f <= rout_1;
	rout_2f <= rout_2;

	// forward the write register address
	wreg_f <= wreg;
	
	// forward control signals
	alusrc_f <= alusrc;
	memtoreg_f <= memtoreg;
	aluop_f <= aluop;
	
	// forward control signals that may need to be flushed
	regwrite_f <= ~flush & regwrite;
	memwrite_f <= ~flush & memwrite;
	beq_f <= ~flush & beq;
	bne_f <= ~flush & bne;
	jal_f <= ~flush & jal;
	jalr_f <= ~flush & jalr;
	halt_f <= ~flush & halt;

	instr_f <= instr;
end

// ---------------------- STAGE 2: EXECUTE ----------------------  
reg regwrite_ff;
reg [4:0] wreg_ff;
wire is_write_ff = regwrite_ff && (wreg_ff != 5'b00000);

wire [2:0] opcode;
ALU_CONTROL alu_control(.instr(instr_f), .aluop(aluop_f), .opcode(opcode));

// alu
reg signed [31:0] alu_1f, alu_2f;
always @* begin
	if (alusrc_f) begin
		alu_2f = imm_f;
	end else begin
		alu_2f = (rreg_2f == wreg_ff && is_write_ff) ? wdata : rout_2f;
	end

	alu_1f = (rreg_1f == wreg_ff && is_write_ff) ? wdata : rout_1f;
end

wire signed [31:0] alu_out;
ALU alu(.in1(alu_1f), .in2(alu_2f), .opcode(opcode), .out(alu_out));

// ---------------------- TRANSITION 2 ----------------------  
reg memtoreg_ff, memwrite_ff, beq_ff, bne_ff, jal_ff, jalr_ff, halt_ff;
reg [31:0] imm_ff, mem_addr, rout_2ff;
reg signed [31:0] alu_out_f;

always @(posedge outclock_0)
begin
	// general signals
	memtoreg_ff <= memtoreg_f;
	imm_ff <= imm_f;
	wreg_ff <= wreg_f;

	// control signals
	regwrite_ff <= ~flush & regwrite_f;
	memwrite_ff <= ~flush & memwrite_f;
	beq_ff <= ~flush & beq_f;
	bne_ff <= ~flush & bne_f;
	jal_ff <= ~flush & jal_f;
	jalr_ff <= ~flush & jalr_f;
	halt_ff <= ~flush & halt_f;

	// memory stuff
	mem_addr <= alu_out >> 2;
	alu_out_f <= alu_out;

	// forward from stage 3 to stage 2 if necessary
	// used in case of a SW instruction
	rout_2ff <= (rreg_2f == wreg_ff && is_write_ff) ? wdata : rout_2f;
	
end

// ---------------------- STAGE 3: MEMORY AND WRITEBACK ----------------------  

wire [31:0] mem_out;
wire not_zero_flag = |alu_out_f;
ram ram(.address(mem_addr), .clock(outclock_1), .data(rout_2ff), .wren(memwrite_ff), .q(mem_out));

always @*
begin
	if (jal_ff | jalr_ff) wdata = pc_ff + 4;
	else if (memtoreg_ff) wdata = mem_out;
	else wdata = alu_out_f;
end

// pc and branching
wire branch = (beq_ff & ~not_zero_flag) | (bne_ff & not_zero_flag) | jal_ff;
assign flush = branch | jalr_ff;
always @(posedge outclock_0)
begin
	if(jalr_ff) pc <= alu_out_f;
	else if(branch) pc <= pc_ff + (imm_ff << 1);
	else if(halt_ff) pc <= pc_ff;
	else if(halt) pc <= pc;
	else pc <= pc + 4;
	
	pc_f <= pc;
	pc_ff <= pc_f;
end

endmodule