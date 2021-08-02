/* id_stage */

`include "defines.v"

module id_stage(
  input wire rst,
  input wire [31 : 0]inst,
  input wire [`REG_BUS]rs1_data,
  input wire [`REG_BUS]rs2_data,
  input wire [63 : 0]  inst_addr,
  input wire [`REG_BUS]exe_data,
  
  output wire rs1_r_ena,
  output wire [4 : 0]rs1_r_addr,
  output wire rs2_r_ena,
  output wire [4 : 0]rs2_r_addr,
  output wire rd_w_ena,
  output wire [4 : 0]rd_w_addr,
  
  output wire [4 : 0]inst_type,
  output reg [7 : 0]inst_opcode,
  output reg [`REG_BUS]op1,
  output reg [`REG_BUS]op2,
  output reg [63 : 0]imm,
  output reg [1  : 0]mpc,//flag--next PC
  output reg [2  : 0]jump_o,        //pc_jump, jal
  
  output reg [2:0] alumem_reg,//alu or mem to regfile
  
  output reg mem_wen,       // Mem write
  output reg[63 : 0] mem_wdata,
  output reg[63 : 0] wmask
);


// I-type
wire [6  : 0]opcode;
wire [4  : 0]rd;
wire [2  : 0]func3;
wire [4  : 0]rs1;
wire [11 : 0]immi;

// R_type
wire [6  : 0]func7;
wire [4  : 0]rs2;


reg [2  : 0]rs2_im;//flag--op2: rs2_data or immediate,001:rs2, 011:4, 100:imm
reg [1  : 0]rs1_pc;//flag--op1: rs1_data or pc,00:rs1,01:pc

reg [2  : 0]exop;//flag---Immediate number expansion


assign opcode = inst[6  :  0];
assign rd     = inst[11 :  7];
assign func3  = inst[14 : 12];
assign func7  = inst[31 : 25];
assign rs1    = inst[19 : 15];
assign rs2    = inst[24 : 20];
assign immi   = inst[31 : 20];


assign inst_type[3] = (~opcode[6] & opcode[5] & ~opcode[4] & ~opcode[3] & ~opcode[2] & opcode[1] & opcode[0]) || (opcode[6] & opcode[5] & ~opcode[4] & ~opcode[3] & ~opcode[2] & opcode[1] & opcode[0]);
assign inst_type[4] = ( rst == 1'b1 ) ? 0 : 1;
assign rs1_r_ena  = ( rst == 1'b1 ) ? 0 : inst_type[4];
assign rs1_r_addr = ( rst == 1'b1 ) ? 0 : ( inst_type[4] == 1'b1 ? rs1 : 0 );
assign rs2_r_ena  = ( rst == 1'b1 ) ? 0 : inst_type[4];
assign rs2_r_addr = ( rst == 1'b1 ) ? 0 : ( inst_type[4] == 1'b1 ? rs2 : 0 );
assign rd_w_ena   = ( rst == 1'b1 ) ? 0 : ~inst_type[3];
assign rd_w_addr  = ( rst == 1'b1 ) ? 0 : ( inst_type[4] == 1'b1 ? rd  : 0 );

always@(*) begin
  rs1_pc = 2'b00;
  mpc = 2'b00;
  mem_wen = 0;
  alumem_reg = 3'b000;
  jump_o = 3'b000;
  case(opcode)
    7'b0010011:begin		//I-type inst
      rs2_im = 3'b000; 
      case(func3)
        3'b000: begin inst_opcode = 8'h00; end   //addi        		  
        3'b111: begin inst_opcode = 8'h01; end   //andi		   
        3'b110: begin inst_opcode = 8'h02; end   //ori		 
        3'b001: begin inst_opcode = 8'h06; end   //slli
        3'b010: begin inst_opcode = 8'h07; end   //slti
        3'b011: begin inst_opcode = 8'h08; end   //sltiu
        3'b100: begin inst_opcode = 8'h04; end   //xori
        3'b101: begin
          imm = { {58{1'b0}}, inst[25 : 20] };
          inst_opcode = 8'h05;
          case(inst[30])
            1: begin rs2_im = 3'b100; end   //srai
            0: begin rs2_im = 3'b100; end   //srli 
            default   : begin inst_opcode = 8'hFF; end
          endcase				
        end
        default: begin inst_opcode = 8'hFF; end
      endcase
    end
    
    7'b0011011:begin		//I-type inst
      rs2_im = 3'b000; 
      case(func3)
        3'b000: begin  //addiw
          inst_opcode = 8'h00; 
          alumem_reg = 3'b010;
        end    
        3'b101: begin        
          case(func7)
            7'b0100000: begin //sraiw
              rs1_pc = 2'b10;
              rs2_im = 3'b100;
              alumem_reg = 3'b010;
              imm = { {58{inst[25]}}, inst[25 : 20] };
              inst_opcode = 8'h09; 
            end   
            7'b0000000: begin //srliw
              rs1_pc = 2'b11;
              rs2_im = 3'b100;
              alumem_reg = 3'b010;
              imm = { {58{inst[25]}}, inst[25 : 20] };
              inst_opcode = 8'h05; 
            end   
            default   : begin inst_opcode = 8'hFF; end
          endcase				
        end
        3'b001: begin  //slliw
          inst_opcode = 8'h06;
          alumem_reg = 3'b010;
        end      		  
        default: begin inst_opcode = 8'hFF; end
      endcase
    end
     
	 7'b0000011:begin   //I-type inst
	   rs1_pc = 2'b00;
	   rs2_im = 3'b100;
	   inst_opcode = 8'h00;
	   imm = {{52{inst[31]}} , inst[31:20]};	   
	   case(func3)
		  3'b000: begin alumem_reg = 3'b100; end   //lb        		  
		  3'b100: begin alumem_reg = 3'b101; end   //lbu		   
		  3'b011: begin alumem_reg = 3'b011; end   //ld		    
		  3'b001: begin alumem_reg = 3'b110; end   //lh        		  
		  3'b101: begin alumem_reg = 3'b111; end   //lhu
		  3'b010: begin alumem_reg = 3'b001; end   //lw  
		  3'b110: begin inst_opcode = 8'h00; end   //lwu
		  default: begin inst_opcode = 8'hFF; end
		endcase
	 end
	 
	 7'b0110011:begin   //R-type inst
	   rs2_im = 3'b001;
	   case(func7)
		  7'b0000000:begin
		    case(func3)
		      3'b000: begin inst_opcode = 8'h00; end   //add
		      3'b111: begin inst_opcode = 8'h01; end   //and					
		      3'b110: begin inst_opcode = 8'h02; end   //or                 
		      3'b100: begin inst_opcode = 8'h04; end   //xor 
		      3'b101: begin inst_opcode = 8'h05; end   //srl
		      3'b001: begin inst_opcode = 8'h06; end   //sll
		      3'b010: begin inst_opcode = 8'h07; end   //slt
		      3'b011: begin inst_opcode = 8'h08; end   //sltu
		      default: begin inst_opcode = 8'hFF; end
		    endcase
		  end		
		  7'b0100000:begin
		    case(func3)
			   3'b000: begin inst_opcode = 8'h03; end   //sub
				3'b101: begin inst_opcode = 8'h09; end   //sra
				default   : begin inst_opcode = 8'hFF; end
		    endcase
		  end	 
		  default   : begin inst_opcode = 8'hFF; end
	   endcase
	 end
	 
	 7'b0111011:begin   //R-type inst
	   rs1_pc = 2'b00;
	   rs2_im = 3'b001;
	   case(func7)
		  7'b0000000:begin
		    case(func3)
		      3'b000: begin //addw
		        inst_opcode = 8'h00;
		        alumem_reg = 3'b010;		        
		      end
		      3'b001: begin //sllw
		        inst_opcode = 8'h06;
		        alumem_reg = 3'b010;		        
		      end
		      3'b101: begin //srlw
		        rs1_pc = 2'b11;
		        inst_opcode = 8'h09;
		        alumem_reg = 3'b010;		        
		      end
		      default   : begin inst_opcode = 8'hFF; end 		      
		    endcase
		  end
		  7'b0100000:begin
		    case(func3)
		      3'b000: begin //subw
		        inst_opcode = 8'h03;
		        alumem_reg = 3'b010;		        
		      end
		      3'b101: begin //sraw
		        inst_opcode = 8'h09;
		        alumem_reg = 3'b010;		        
		      end
		      default   : begin inst_opcode = 8'hFF; end		      
		    endcase
		  end
		  default   : begin inst_opcode = 8'hFF; end 		  
	   endcase
	 end
	 
	 7'b1100011:begin   //B-type
	   rs1_pc = 2'b00;
	   rs2_im = 3'b001;
	   imm = {{52{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};	   
	   case(func3)
	     3'b000: begin //beq
	       inst_opcode = 8'h03;
	       jump_o = 3'b011;
	     end   
	     3'b101: begin //bge
	       inst_opcode = 8'h0a;
	       jump_o = 3'b101;
	     end   
	     3'b111: begin //bgeu
	       inst_opcode = 8'h0c;
	       jump_o = 3'b101;
	     end   
	     3'b100: begin 
	       inst_opcode = 8'h07;
	       jump_o = 3'b101;
	     end   //blt
	     3'b110: begin  //bltu
	       inst_opcode = 8'h08; 
	       jump_o = 3'b101;
	     end  
	     3'b001: begin //bne
	       inst_opcode = 8'h03;
	       jump_o = 3'b010;
	     end   
	     default   : begin inst_opcode = 8'hFF; end
	   endcase
	 end
	 
	 7'b0100011:begin   //S-type
	   mem_wen = 1;
	   rs1_pc = 2'b00;
	   rs2_im = 3'b100;
	   inst_opcode = 8'h00;
	   imm = {{52{inst[31]}}, inst[31:25], inst[11:7]};	   
	   case(func3)    
		  3'b000: begin           //sb		  
		    case(exe_data[2 : 0])
		      3'b000:begin
		        wmask = 64'h00000000_000000ff;
		        mem_wdata = rs2_data;
		      end
		      3'b001:begin
		        wmask = 64'h00000000_0000ff00;
		        mem_wdata = {48'h00000000_0000, rs2_data[7 : 0], 8'h00};
		      end
		      3'b010:begin
		        wmask = 64'h00000000_00ff0000;
		        mem_wdata = {40'h00000000_00, rs2_data[7 : 0], 16'h0000};
		      end
		      3'b011:begin
		        wmask = 64'h00000000_ff000000;
		        mem_wdata = {32'h00000000, rs2_data[7 : 0], 24'h000000};
		      end
		      3'b100:begin
		        wmask = 64'h000000ff_00000000;
		        mem_wdata = {24'h000000, rs2_data[7 : 0], 32'h00000000};
		      end
		      3'b101:begin
		        wmask = 64'h0000ff00_00000000;
		        mem_wdata = {16'h0000, rs2_data[7 : 0], 40'h00_00000000};
		      end
		      3'b110:begin
		        wmask = 64'h00ff0000_00000000;
		        mem_wdata = {8'h00, rs2_data[7 : 0], 48'h0000_00000000};
		      end
		      3'b111:begin
		        wmask = 64'hff000000_00000000;
		        mem_wdata = {rs2_data[7 : 0], 56'h000000_00000000};
		      end
		    endcase	
		  end   
		  3'b011: begin //sd
		    wmask = `ONE_WORD;	
		    mem_wdata = rs2_data;	    
		  end   
		  3'b001: begin  //sh
		    case(exe_data[2 : 1])
		      2'b00:begin
		        wmask = 64'h00000000_0000ffff;
		        mem_wdata = rs2_data;
		      end
		      2'b01:begin
		        wmask = 64'h00000000_ffff0000;
		        mem_wdata = {32'h00000000, rs2_data[15 : 0], 16'h0000};
		      end
		      2'b10:begin
		        wmask = 64'h0000ffff_00000000;
		        mem_wdata = {16'h0000, rs2_data[15 : 0], 32'h00000000};
		      end
		      2'b11:begin
		        wmask = 64'hffff0000_00000000;
		        mem_wdata = {rs2_data[15 : 0], 48'h0000_00000000};
		      end
		    endcase
		  end  
		  3'b010: begin  //sw
		    case(exe_data[2])
		      0:begin
		        wmask = 64'h00000000_ffffffff;
		        mem_wdata = rs2_data;
		      end
		      1:begin
		        wmask = 64'hffffffff_00000000;
		        mem_wdata = {rs2_data, 32'h00000000};
		      end
		    endcase		    
		  end  
		  default: begin inst_opcode = 8'hFF; end
		endcase
	 end
	 
	 7'b0010111:begin   //U-type  auipc	   
	   rs1_pc = 2'b01;
	   rs2_im = 3'b010;
	   inst_opcode = 8'h00;
	 end
	 
	 7'b0110111:begin   //U-type  lui
	   imm = {{32{inst[31]}}, inst[31:12], 12'b0};
	   rs2_im = 3'b100;
	   inst_opcode = 8'h0b;
	 end
	 
	 7'b1101111:begin   //J-type  jal
	   jump_o = 3'b001;
	   rs1_pc = 2'b01;
	   rs2_im = 3'b011;
	   imm = {{44{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};
	   inst_opcode = 8'h00;
	 end
	 
	 7'b1100111:begin   //I-type  jalr
	   case(func3)
	     3'b000:begin 
	       jump_o = 3'b100;
	       rs1_pc = 2'b01;
	       rs2_im = 3'b011;
	       imm = {{52{inst[31]}} , inst[31:20]};
	       inst_opcode = 8'h00;
	     end
	     default   : begin inst_opcode = 8'hFF; end
	   endcase
	 end
	
	 default   : begin inst_opcode = 8'hFF; end
  endcase
end
	



always@(*) begin
  if(rst == 1'b1) begin
    op2 = 0;
    op1 = 0; 
  end
  else begin
    case(rs2_im)
      3'b000:       begin op2 = { {52{immi[11]}}, immi }; end   	
      3'b001:       begin op2 = rs2_data;               end
      3'b010:       begin op2 = {{32{inst[31]}}, inst[31:12], 12'b0}; end
      3'b011:       begin op2 = 4; end
      3'b100:       begin op2 = imm; end
      default: begin op2 = `ZERO_WORD;             end	 	
    endcase
    case(rs1_pc)
      2'b00:       begin op1 = rs1_data;               end   	
      2'b01:       begin op1 = inst_addr;              end
      2'b10:       begin op1 = {{32{rs1_data[31]}}, rs1_data[31 : 0] };               end
      2'b11:       begin op1 = {{32{1'b0}}, rs1_data[31 : 0] };               end 
      default: begin op1 = `ZERO_WORD;             end
	 endcase	
  end
end

endmodule

