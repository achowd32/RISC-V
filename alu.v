module ALU(in1, in2, opcode, out);
input [31:0] in1, in2;
input [2:0] opcode;
output reg [31:0] out;

always @*
begin
    // prioritize multiplication detection
	if(~opcode[2] & opcode[1] & ~opcode[0]) begin
		out = in1 * in2;
	end else begin
		case (opcode)
			3'b000: out = in1 + in2;
			3'b001: out = in1 - in2;
			3'b011: out = in1 & in2;
			3'b100: out = in1 | in2;
			default: out = in1 << in2;
		endcase
	end
end

endmodule
