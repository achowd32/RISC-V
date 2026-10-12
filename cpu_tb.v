`timescale 1 ps / 1 ps

module cpu_tb;
reg clk;
cpu cpu_inst(.clk(clk));

integer i;

initial begin
    clk = 0;
    #300;
	 $display("mem[0]=%0d", cpu_inst.ram.mem[0]);
    $finish;
end

always @*
	#1 clk <= ~clk;

endmodule