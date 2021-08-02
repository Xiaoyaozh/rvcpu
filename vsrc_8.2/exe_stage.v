
//--xuezhen--

`include "defines.v"

module exe_stage(
  input wire rst,
  input wire [4 : 0]inst_type_i,
  input wire [7 : 0]inst_opcode,
  input wire [`REG_BUS]op1,
  input wire [`REG_BUS]op2,
  input wire [2:0] alumem_reg,
  input wire [`REG_BUS]memr_data,
  input wire [31 : 0]inst,
  
  output wire [4 : 0]inst_type_o,
  output reg  [`REG_BUS]exe_data,
  output reg  [`REG_BUS]rd_data,
  output reg  zero
);

reg [`REG_BUS] memr_data2;
reg sign;

assign inst_type_o = inst_type_i;

always@(*)begin
  if( rst == 1'b1 ) begin
    exe_data = `ZERO_WORD;
  end
  else begin
    case(inst_opcode)
      `INST_ADD:  begin exe_data = op1 + op2;   end
      `INST_AND:  begin exe_data = op1 & op2;   end
      `INST_OR :  begin exe_data = op1 | op2;   end
      `INST_SUB:  begin exe_data = op1 - op2;   end
      `INST_XOR:  begin exe_data = op1 ^ op2;   end
      `INST_SRL:  begin exe_data = op1 >> op2;  end
      `INST_SLL:  begin exe_data = op1 << op2;  end
      `INST_SLTU: begin exe_data = (op1 < op2); end
      8'h09    :  begin exe_data = op1 >> op2;  end
      8'h0b    :  begin exe_data = op2;  end
      8'h0c    :  begin exe_data = (op1 >= op2);  end
      default:    begin exe_data = `ZERO_WORD;  end
    endcase
  end
  if (inst_opcode == `INST_BGE)  begin 
    if(op1[63] == 0 && op2[63] == 1)
      exe_data = 1;
    else if(op1[63] == 1 && op2[63] == 0)
      exe_data = 0;
    else
      exe_data = (op1 >= op2);
  end
  
  if (inst_opcode == `INST_SLT)  begin 
    if(op1[63] == 0 && op2[63] == 1)
      exe_data = 0;
    else if(op1[63] == 1 && op2[63] == 0)
      exe_data = 1;
    else
      exe_data = (op1 < op2);
  end
  
  if(exe_data == 0)
    zero = 0; 
  else zero = 1;
end

assign memr_data2 = exe_data[2] ? memr_data[63 : 32] : memr_data[31 : 0];

always@(*) begin
    case(alumem_reg)
	   3'b000:  begin rd_data = exe_data;  end
	   3'b001:  begin rd_data = {{32{memr_data2[31]}}, memr_data2[31 : 0]}; end  	
	   3'b010:  begin rd_data = {{32{exe_data[31]}}, exe_data[31 : 0]};  end
	   3'b011:  begin rd_data = memr_data;  end
	   3'b100:  begin
	     case(exe_data[2 : 0])
	       3'b000: begin rd_data = {{56{memr_data[7]}}, memr_data[7 : 0]}; end
	       3'b001: begin rd_data = {{56{memr_data[15]}}, memr_data[15 : 8]}; end
	       3'b010: begin rd_data = {{56{memr_data[23]}}, memr_data[23 : 16]}; end
	       3'b011: begin rd_data = {{56{memr_data[31]}}, memr_data[31 : 24]}; end
	       3'b100: begin rd_data = {{56{memr_data[39]}}, memr_data[39 : 32]}; end
	       3'b101: begin rd_data = {{56{memr_data[47]}}, memr_data[47 : 40]}; end
	       3'b110: begin rd_data = {{56{memr_data[55]}}, memr_data[55 : 48]}; end
	       3'b111: begin rd_data = {{56{memr_data[63]}}, memr_data[63 : 56]}; end
	     endcase
	   end
	   3'b101:  begin
	     case(exe_data[2 : 0])
	       3'b000: begin rd_data = {{56{1'b0}}, memr_data[7 : 0]}; end
	       3'b001: begin rd_data = {{56{1'b0}}, memr_data[15 : 8]}; end
	       3'b010: begin rd_data = {{56{1'b0}}, memr_data[23 : 16]}; end
	       3'b011: begin rd_data = {{56{1'b0}}, memr_data[31 : 24]}; end
	       3'b100: begin rd_data = {{56{1'b0}}, memr_data[39 : 32]}; end
	       3'b101: begin rd_data = {{56{1'b0}}, memr_data[47 : 40]}; end
	       3'b110: begin rd_data = {{56{1'b0}}, memr_data[55 : 48]}; end
	       3'b111: begin rd_data = {{56{1'b0}}, memr_data[63 : 56]}; end
	     endcase
	   end
	   3'b110:  begin
	     case(exe_data[2 : 1])
	       2'b00: begin rd_data = {{48{memr_data[15]}}, memr_data[15 : 0]}; end
	       2'b01: begin rd_data = {{48{memr_data[31]}}, memr_data[31 : 16]}; end
	       2'b10: begin rd_data = {{48{memr_data[47]}}, memr_data[47 : 32]}; end
	       2'b11: begin rd_data = {{48{memr_data[63]}}, memr_data[63 : 48]}; end
	     endcase
	   end
	   3'b111:  begin
	     case(exe_data[2 : 1])
	       2'b00: begin rd_data = {{48{1'b0}}, memr_data[15 : 0]}; end
	       2'b01: begin rd_data = {{48{1'b0}}, memr_data[31 : 16]}; end
	       2'b10: begin rd_data = {{48{1'b0}}, memr_data[47 : 32]}; end
	       2'b11: begin rd_data = {{48{1'b0}}, memr_data[63 : 48]}; end
	     endcase
	   end
	   default: begin rd_data = exe_data;  end	 	
    endcase

end



endmodule
