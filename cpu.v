`timescale 1 ps / 1 ps

module cpu (
	input clk
);

reg [31:0] pc, pc_f, pc_ff;
reg [31:0] rom [23:0];

wire rst, outclock_0, outclock_1;
assign rst = 0;
assign outclock_0 = clk;
assign outclock_1 = ~outclock_0;

integer i;
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
// fetch
wire [31:0] addr = pc >> 2; // pc / 4
wire [31:0] instr = rom[addr];

// registers
wire regwrite;
wire [31:0] rout_1, rout_2;
reg [4:0] wreg_f, wreg_ff;
reg regwrite_f, regwrite_ff;
wire [4:0] rreg_1, rreg_2;
reg [4:0] rreg_1f, rreg_2f;
assign rreg_1 = instr[19:15];
assign rreg_2 = instr[24:20];
assign is_write_ff = regwrite_ff && (wreg_ff != 5'b00000);

always @(posedge outclock_0) begin
	rreg_1f <= rreg_1;
	rreg_2f <= rreg_2;
end

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

wire [4:0] wreg = instr[11:7];
reg [31:0] rout_1f, rout_2f, rout_2ff;
always @(posedge outclock_0)
begin
	rout_1f <= rout_1;
	rout_2f <= rout_2;
	rout_2ff <= (rreg_2f == wreg_ff && is_write_ff) ? wdata : rout_2f;
	wreg_f <= wreg;
	wreg_ff <= wreg_f;
end

// immediate generator
wire [31:0] imm;
IMMGEN immgen(.instr(instr), .immediate(imm));

reg [31:0] imm_f, imm_ff;
always @(posedge outclock_0)
begin
	imm_f <= imm;
	imm_ff <= imm_f;
end

// control unit
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

reg alusrc_f, memtoreg_f, memwrite_f, beq_f, bne_f, jal_f, jalr_f, halt_f;
reg memwrite_ff, memtoreg_ff, beq_ff, bne_ff, jal_ff, jalr_ff, halt_ff;
reg [1:0] aluop_f; 
wire flush;

always @(posedge outclock_0)
begin
	alusrc_f <= alusrc;
	memtoreg_f <= memtoreg; memtoreg_ff <= memtoreg_f;
	aluop_f <= aluop;
	
	if(flush) begin
		regwrite_f <= 0; regwrite_ff <= 0;
		memwrite_f <= 0; memwrite_ff <= 0;
		beq_f <= 0; beq_ff <= 0;
		bne_f <= 0; bne_ff <= 0;
		jal_f <= 0; jal_ff <= 0;
		jalr_f <= 0; jalr_ff <= 0;
		halt_f <= 0; halt_ff <= 0;
	end else begin
		regwrite_f <= regwrite; regwrite_ff <= regwrite_f;
		memwrite_f <= memwrite; memwrite_ff <= memwrite_f;
		beq_f <= beq; beq_ff <= beq_f;
		bne_f <= bne; bne_ff <= bne_f;
		jal_f <= jal; jal_ff <= jal_f;
		jalr_f <= jalr; jalr_ff <= jalr_f;
		halt_f <= halt; halt_ff <= halt_f;
	end
end
					 
// alu control unit
reg [31:0] instr_f;
always @(posedge outclock_0)
begin
	instr_f <= instr;
end

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
// ram
wire [31:0] mem_out;
reg [31:0] mem_addr;
reg signed [31:0] alu_out_f;
always @(posedge outclock_0) 
begin
	mem_addr <= alu_out >> 2;
	alu_out_f <= alu_out;
end
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