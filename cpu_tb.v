`timescale 1 ps / 1 ps

module cpu_tb;
reg CLOCK_50;
cpu cpu_inst(.CLOCK_50(CLOCK_50));

integer i;

initial begin
	// initialize all registers in register file to 0
	cpu_inst.rf.reg_file[0] = 0;
	cpu_inst.rf.reg_file[1] = 0;
	cpu_inst.rf.reg_file[2] = 1024;
	for(i = 3; i < 32; i = i + 1) begin
		cpu_inst.rf.reg_file[i] = 0;
	end
	
   $monitor("t=%0d pc=%0d instr=%0h x2=%0d x6=%0d x10=%0d",
	$time,
	cpu_inst.pc,
	cpu_inst.instr,
	cpu_inst.rf.reg_file[2],
	cpu_inst.rf.reg_file[6],
	cpu_inst.rf.reg_file[10],
	);
	
	CLOCK_50 = 0;
	cpu_inst.pc = 0;
	
	cpu_inst.rom[0] = 32'h00600513;
	cpu_inst.rom[1] = 32'h01c000ef;
	cpu_inst.rom[2] = 32'h00000033; // NO-OP
	cpu_inst.rom[3] = 32'h00000033; // NO-OP
	cpu_inst.rom[4] = 32'h00a02023;
	cpu_inst.rom[5] = 32'h0000007f; // HALT
	cpu_inst.rom[6] = 32'h00000033; // NO-OP
	cpu_inst.rom[7] = 32'h00000033; // NO-OP
	cpu_inst.rom[8] = 32'hff810113;
	cpu_inst.rom[9] = 32'h00000033; // NO-OP
	cpu_inst.rom[10] = 32'h00000033; // NO-OP
	cpu_inst.rom[11] = 32'h00112223;
	cpu_inst.rom[12] = 32'h00a12023;
	cpu_inst.rom[13] = 32'h00100293;
	cpu_inst.rom[14] = 32'h00000033; // NO-OP
	cpu_inst.rom[15] = 32'h02551063;
	cpu_inst.rom[16] = 32'h00000033; // NO-OP
	cpu_inst.rom[17] = 32'h00000033; // NO-OP
	cpu_inst.rom[18] = 32'h00100513;
	cpu_inst.rom[19] = 32'h00810113;
	cpu_inst.rom[20] = 32'h00008067;
	cpu_inst.rom[21] = 32'h00000033; // NO-OP
	cpu_inst.rom[22] = 32'h00000033; // NO-OP
	cpu_inst.rom[23] = 32'hfff50513;
	cpu_inst.rom[24] = 32'hfc1ff0ef; 
	cpu_inst.rom[25] = 32'h00000033; // NO-OP
	cpu_inst.rom[26] = 32'h00000033; // NO-OP
	cpu_inst.rom[27] = 32'h00012303;
	cpu_inst.rom[28] = 32'h00412083;
	cpu_inst.rom[29] = 32'h00810113;
	cpu_inst.rom[30] = 32'h02650533;
	cpu_inst.rom[31] = 32'h00008067;
	cpu_inst.rom[32] = 32'h00000033; // NO-OP
	cpu_inst.rom[33] = 32'h00000033; // NO-OP

end

initial begin
    #300;
	 $display("t=%0d pc=%0d instr=%0h wenable=%0d wdata=%0d x5=%0d x6=%0d",
	   $time, cpu_inst.pc, cpu_inst.instr, cpu_inst.rf.wenable, cpu_inst.rf.wdata,
		cpu_inst.rf.reg_file[5], cpu_inst.rf.reg_file[6]);
    $finish;
end

always @*
	#1 CLOCK_50 <= ~CLOCK_50;

endmodule