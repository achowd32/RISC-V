sim:
	verilator --binary --Wno-fatal --top-module cpu_tb cpu_tb.v cpu.v ram.v alu.v alu_control.v control.v immgen.v rf.v
