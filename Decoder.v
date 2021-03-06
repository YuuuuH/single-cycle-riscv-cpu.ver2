
module Decoder(
    input      [6:0] opcode,
    input      [2:0] Func3,
    input      [1:0] counter02,
    input      [31:0]data_addr,
    output reg [2:0] ImmType,
    output reg       RegWrite,
    output reg [2:0] ALUop,
    output reg       PCtoRegSrc,
    output reg       ALUSrc,
    output reg       RDSrc,
    output reg       MemRead,
    output reg [3:0]      MemWrite,
    output reg       MemtoReg,
    output reg [1:0] IsBJ,
    output reg       isLW
        );

//parameter for opcode
parameter [6:0] RTYPE         = 7'b0110011,
                LW            = 7'b0000011,
                ITYPE         = 7'b0010011,
                JALR          = 7'b1100111,
                SW            = 7'b0100011,
                BTYPE         = 7'b1100011,
                AUIPC         = 7'b0010111,
                LUI           = 7'b0110111,
                JAL           = 7'b1101111;

//perameter for ImmType
parameter [2:0] IMM_R         = 3'b000,
                IMM_I         = 3'b001,
                IMM_S         = 3'b010,
                IMM_B         = 3'b011,
                IMM_U         = 3'b100,
                IMM_J         = 3'b101;

//parameter for ALUSrc
parameter       RS2           = 1'b1,
                IMM           = 1'b0;

//parameter for PCtoRegSrc
parameter       PC_IMM        = 1'b1,
                PC_4          = 1'b0;

//parameter for RDSrc
parameter       PC_TO_REG     = 1'b1,
                ALU_OUT       = 1'b0;

//parameter for MemToReg
parameter       PC_OR_ALU_OUT = 1'b1,
                MEM_OUT       = 1'b0;


//parameter for ALUop
parameter [1:0] ALUOP_ADD     = 2'b00,
                ALUOP_SUB     = 2'b01,
                ALUOP_FUNC    = 2'b10,  
                ALUOP_LUI     = 2'b11;
//parameter for ISBJ
parameter [1:0] ISB           = 2'b00,
                ISJ           = 2'b01,
                ISJR          = 2'b10,
                NOBJ          = 2'b11;


always @(*) begin
    isLW = 1'b0;
    case(opcode)
        7'b0000000 : begin
            RegWrite   = 1'b0;
            ImmType    = 3'b000;
            ALUop      = 2'b0;
            PCtoRegSrc = 1'b0;
            ALUSrc     = 1'b0;
            RDSrc      = 1'b0;
            MemRead    = 1'b0;
            MemWrite   = 1'b0;
            MemtoReg   = 2'b0;
            IsBJ       = 2'b0;
            isLW       = 1'b0;
        end
        RTYPE : begin
            RegWrite   = 1'b1; 
            ImmType    = IMM_R;
            ALUop      = ALUOP_FUNC;
            PCtoRegSrc = 1'b0; //don't care
            ALUSrc     = RS2;
            RDSrc      = ALU_OUT;
            MemRead    = 1'b0;
            MemWrite   = 4'b0;
            MemtoReg   = PC_OR_ALU_OUT;
            IsBJ       = NOBJ;
            isLW       = 1'b0;
        end
        LW    : begin
            if(counter02==2'b1)begin
                RegWrite = 1'b1;
            end
            else begin
                RegWrite  = 1'b0;
            end
            ImmType    = IMM_I;
            ALUop      = ALUOP_ADD;
            PCtoRegSrc = 1'b0; //don't care
            ALUSrc     = IMM;
            RDSrc      = ALU_OUT;
            MemRead    = 1'b1;
            MemWrite   = 4'b0;
            MemtoReg   = MEM_OUT;
            IsBJ       = NOBJ;
            isLW       = 1'b1;
        end
        ITYPE : begin
            RegWrite   = 1'b1;
            ImmType    = IMM_I;
            ALUop      = ALUOP_FUNC;
            PCtoRegSrc = 1'b0; //don't care
            ALUSrc     = IMM;
            RDSrc      = ALU_OUT;
            MemRead    = 1'b0;
            MemWrite   = 4'b0;
            MemtoReg   = PC_OR_ALU_OUT;
            IsBJ       = NOBJ;
            isLW       = 1'b0;
        end
        JALR  : begin
            RegWrite   = 1'b1;
            ImmType    = IMM_I;
            ALUop      = ALUOP_ADD;
            PCtoRegSrc = 1'b0; //from pc_out + 4 to register rd
            ALUSrc     = IMM;
            RDSrc      = PC_TO_REG;
            MemRead    = 1'b0;
            MemWrite   = 4'b0;
            MemtoReg   = PC_OR_ALU_OUT;
            IsBJ       = ISJR;
            isLW       = 1'b0;
        end
        SW    : begin
            RegWrite   = 1'b0;
            ImmType    = IMM_S;
            ALUop      = ALUOP_ADD;
            PCtoRegSrc = 1'b0; //don't care
            ALUSrc     = IMM;
            RDSrc      = ALU_OUT; //don't care
            MemRead    = 1'b0;
            MemtoReg   = PC_OR_ALU_OUT;//don't care
            IsBJ       = NOBJ;
            isLW       = 1'b0;
            case(data_addr[1:0])
                2'b00:begin
                    case(Func3)
                        3'b010 :MemWrite = 4'b1111;
                        3'b000:begin
                            if(data_addr==32'b0)begin
                                MemWrite = 4'b0000;
                            end
                            else begin
                                MemWrite = 4'b0001;
                            end
                        end
                        3'b001 :MemWrite = 4'b0011;
                        default:MemWrite = 4'b0000;
                    endcase
                end
                2'b01:begin
                    case(Func3)
                        3'b000:MemWrite = 4'b0010;
                        3'b001:MemWrite = 4'b0110;
                        default:MemWrite = 4'b0000;
                    endcase
                end
                2'b10:begin
                    case(Func3)
                        3'b000:MemWrite = 4'b0100;
                        3'b001:MemWrite = 4'b1100;
                        default:MemWrite = 4'b0000;
                    endcase
                end
                2'b11:begin
                    case(Func3)
                        3'b000:MemWrite = 4'b1000;
                        default:MemWrite = 4'b0000;
                    endcase
                end
            endcase
        end
        BTYPE : begin
            RegWrite   = 1'b0;
            ImmType    = IMM_B;
            ALUop      = ALUOP_SUB;
            PCtoRegSrc = 1'b1; //from pc_out + imm to pc_in's mux
            ALUSrc     = RS2;
            RDSrc      = ALU_OUT; //don't care
            MemRead    = 1'b0;
            MemWrite   = 4'b0;
            MemtoReg   = PC_OR_ALU_OUT; //don't care
            IsBJ       = ISB;
            isLW       = 1'b0;
        end
        AUIPC : begin
            RegWrite   = 1'b1;
            ImmType    = IMM_U;
            ALUop      = ALUOP_ADD;
            PCtoRegSrc = 1'b1; //from pc_out + imm 
            ALUSrc     = IMM; // don't care
            RDSrc      = PC_TO_REG;
            MemRead    = 1'b0;
            MemWrite   = 4'b0;
            MemtoReg   = PC_OR_ALU_OUT;
            IsBJ       = 1'b0;
            isLW       = 1'b0;
        end
        LUI   : begin
            RegWrite   = 1'b1;
            ImmType    = IMM_U;
            ALUop      = ALUOP_LUI;
            PCtoRegSrc = 1'b1; //notice here !!!!!! we have to add another mux in front of the pc_out imm adder , to choose imm only for LUI instr!!!!!!!!!! 
            ALUSrc     = IMM; //don't care
            RDSrc      = ALU_OUT;
            MemRead    = 1'b0;
            MemWrite   = 4'b0;
            MemtoReg   = PC_OR_ALU_OUT;
            IsBJ       = NOBJ;
            isLW       = 1'b0;
        end
        JAL   : begin // in this instruction , the pc = pc + imm will feedback without mux(pctoregsrc)
            RegWrite   = 1'b1;
            ImmType    = IMM_J;
            ALUop      = ALUOP_ADD;
            PCtoRegSrc = 1'b0; //it's from pc_out + 4
            ALUSrc     = IMM;//don't care
            RDSrc      = PC_TO_REG;
            MemRead    = 1'b0;
            MemWrite   = 4'b0;
            MemtoReg   = PC_OR_ALU_OUT;
            IsBJ       = ISJ;
            isLW       = 1'b0;
        end
    endcase
end

endmodule
