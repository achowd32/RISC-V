// ram.v
// TEMPORARY RAM STANDIN
// AI GENERATED
`timescale 1 ps / 1 ps

module ram (
	input [7:0] address,
	input clock,
	input [31:0] data,
	input wren,
	output reg [31:0] q
);

reg [31:0] mem [255:0];

integer i;
initial begin
	for (i = 0; i < 256; i = i + 1) mem[i] = 0;
end

always @(posedge clock) begin
	if (wren) mem[address] <= data;
	q <= mem[address];
end

endmodule