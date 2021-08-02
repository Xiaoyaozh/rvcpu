

`include "defines.v"


module if_stage(
  input wire clk,
  input wire rst,
  input wire[2 : 0] jump,
  input wire zero,
  input wire [63 : 0]imm,
  input wire [`REG_BUS] r_data1,
  output wire [63 : 0]pc_o
);

reg [`REG_BUS]pc;

// fetch an instruction
always@( posedge clk ) begin
  if( rst == 1'b1 )
    pc <= `PC_START;
  else if(jump == 3'b001 || ((jump == 3'b010 || jump == 3'b101) && zero) || ((jump == 3'b011) && ~zero))
    pc <= pc + imm;  
  else if(jump == 3'b100)
    pc <= r_data1 + imm;
  else
    pc <= pc + 4;
end

assign pc_o = pc;

endmodule
