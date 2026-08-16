module RF(clk, rreg_1, rreg_2, wreg, wdata, wenable, rout_1, rout_2);
input [31:0] wdata;
input [4:0] rreg_1, rreg_2, wreg;
input clk, wenable;
output reg [31:0] rout_1, rout_2;

reg [31:0] reg_file [31:0];

integer i;
initial begin
	reg_file[0] = 0;
	reg_file[1] = 0;
	reg_file[2] = 1024;
	
	for(i = 3; i < 32; i = i + 1) begin
		reg_file[i] = 0;
	end
end

always @*
begin
	rout_1 = reg_file[rreg_1];
	rout_2 = reg_file[rreg_2];
end

always @(posedge clk)
begin
	if(wenable && wreg != 5'b00000) reg_file[wreg] <= wdata; // no writing into x0
end

endmodule
