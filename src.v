module URISC_Data_Path #(
    parameter WIDTH = 'd16, DEPTH = 'd512
)(
    input clk,
    input reset,
    input Run,
    input PC_out,
    input PC_in,
    input R_in,
    input Comp,
    input Z_in,
    input N_in,
    input C_in,
    input Read,
    input MDR_in,
    input MAR_in,
    input MDR_out,
    input [WIDTH-1:0] Data_in,
    output reg Zero,
    output reg Neg,
    output wire Nop,
    output wire [$clog2(DEPTH)-1:0] Addr,
    output wire [WIDTH-1:0] Data_out,
    output wire [WIDTH-1:0] MDR,
    output wire [$clog2(DEPTH)-1:0] MAR
);
    reg [$clog2(DEPTH)-1:0] PC_reg, MAR_reg;
    reg [WIDTH-1:0] R, MDR_reg, Bus_A, Bus_B;
    reg [WIDTH:0] Acc_out;

    assign Addr = MAR_reg;
    assign MAR = MAR_reg;
    assign Data_out = Bus_B;
    assign MDR = MDR_reg;
    assign Nop = PC_reg == 0;

    always@(posedge clk, negedge reset) begin
        if(!reset) begin
            PC_reg <= 0;
        end else begin
            if(Run) PC_reg <= 'd1;
            if(PC_in) PC_reg <= Bus_B;
        end
    end

    always@(posedge clk, negedge reset) begin
        if(!reset) begin
            R <= 0;
        end else begin
            if(R_in) R <= Bus_A;
        end
    end

    always@(posedge clk, negedge reset) begin
        if(!reset) begin
            MDR_reg <= 0;
        end else begin
            if(MDR_in) MDR_reg <= Bus_B;
            else if(Read) MDR_reg <= Data_in;
        end
    end

    always@(negedge clk, negedge reset) begin
        if(!reset) begin
            MAR_reg <= 0;
        end else begin
            if(MAR_in) MAR_reg <= Bus_B[$clog2(DEPTH)-1:0];
        end
    end

    always@(posedge clk, negedge reset) begin
        if(!reset) begin
            Zero <= 0;
        end else begin
            if(Z_in) Zero <= Acc_out == 0;
        end
    end

    always@(posedge clk, negedge reset) begin
        if(!reset) begin
            Neg <= 0;
        end else begin
            if(N_in) begin
                if(Acc_out[WIDTH-1:0]==0) Neg <= 0;
                else Neg <= Acc_out[WIDTH];
            end
        end
    end

    always@(*) begin
        Acc_out <= {Bus_A[WIDTH-1], Bus_A} + (Comp ? ~{R[WIDTH-1], R} : {(WIDTH+1){1'b0}}) + C_in;
    end

    always@(*) begin
        Bus_B <= Acc_out;
    end

    always@(*) begin
        case({PC_out, MDR_out})
        2'b01: Bus_A <= MDR_reg;
        2'b10: Bus_A <= PC_reg;
        default: Bus_A <= 0;
        endcase
    end

endmodule

module URISC_Control_Path #(
    parameter WIDTH = 'd16, DEPTH = 'd512
)(
    input clk,
    input reset,
    input Run,
    input Stop,
    input Neg,
    input Zero,
    output reg PC_out,
    output reg PC_in,
    output reg R_in,
    output reg Comp,
    output reg Z_in,
    output reg N_in,
    output reg C_in,
    output reg MDR_in,
    output reg MAR_in,
    output reg MDR_out,
    output reg Data_CS,
    output reg Inst_CS,
    output reg Read,
    output reg Write,
    output reg [3:0] Counter
);

    parameter C0 = 4'b0000;
    parameter C1 = 4'b0001;
    parameter C2 = 4'b0010;
    parameter C3 = 4'b0011;
    parameter C4 = 4'b0100;
    parameter C5 = 4'b0101;
    parameter C6 = 4'b0110;
    parameter C7 = 4'b0111;
    parameter C8 = 4'b1000;
    parameter IDLE = 4'b1111;

    reg [15:0] Collection;
    reg Run_flag;
    reg NNend, Zend;

    always@(*) begin
        {PC_out, PC_in, R_in, Comp, Z_in, N_in, C_in, MDR_in,
        MAR_in, MDR_out, Data_CS, Inst_CS, Read, Write, NNend, Zend} <= Collection;
    end

    always@(posedge clk, negedge reset) begin
        if(!reset) Run_flag <= 0;
        else if(Stop & Run_flag) Run_flag <= 0;
        else if(Run & ~Run_flag) Run_flag <= 1;
    end

    always@(posedge clk, negedge reset) begin
        if(!reset) begin
            Counter <= 0;
        end else begin
            if(Run_flag) begin
                if(Counter == C8) Counter <= C0;
                else if(Counter == C7 && (NNend & ~Neg)) Counter <= C0;
                else Counter <= Counter + 1;
            end
        end
    end

    always@(*) begin
        case(Counter)
        C0: Collection <= 16'b1000100010011001;
        C1: Collection <= 16'b0000000011101000;
        C2: Collection <= 16'b0010000001000000;
        C3: Collection <= 16'b1100001010011000;
        C4: Collection <= 16'b0000000011101000;
        C5: Collection <= 16'b0001011101100100;
        C6: Collection <= 16'b1100001010011000;
        C7: Collection <= 16'b1100001000000010;
        C8: Collection <= 16'b0100000001000000;
        default: Collection <= 16'b0;
        endcase
    end

endmodule

module URISC #(
    parameter WIDTH = 'd16, DEPTH = 'd512
)(
    input clk,
    input reset,
    input Run,
    input Stop,
    input [WIDTH-1:0] Data_in,
    input [$clog2(DEPTH)-1:0] Inst_in,
    output wire Data_CS, Inst_CS, Read, Write,
    output wire [$clog2(DEPTH)-1:0] MAR,
    output wire [WIDTH-1:0] Data_out,
    output wire [3:0] State
);

    wire PC_out;
    wire PC_in;
    wire R_in;
    wire Comp;
    wire Z_in;
    wire N_in;
    wire C_in;
    wire MDR_in;
    wire MAR_in;
    wire MDR_out;
    wire Neg, Zero, Nop;
    wire [WIDTH-1:0] MDR;
    wire [$clog2(DEPTH)-1:0] Addr;

    reg [WIDTH-1:0] MDR_data_in;

    always@(*) begin
        if(Inst_CS) MDR_data_in <= Inst_in;
        else if(Data_CS) MDR_data_in <= Data_in;
        else MDR_data_in <= 0;
    end

    URISC_Data_Path #(
        .WIDTH(WIDTH), .DEPTH(DEPTH)
    ) D0 (
        .clk(clk),
        .reset(reset),
        .Run(Run),
        .PC_out(PC_out),
        .PC_in(PC_in),
        .R_in(R_in),
        .Comp(Comp),
        .Z_in(Z_in),
        .N_in(N_in),
        .C_in(C_in),
        .Read(Read),
        .MDR_in(MDR_in),
        .MAR_in(MAR_in),
        .MDR_out(MDR_out),
        .Data_in(MDR_data_in),
        .Neg(Neg),
        .Zero(Zero),
        .Nop(Nop),
        .Addr(Addr),
        .Data_out(Data_out),
        .MDR(MDR),
        .MAR(MAR)
    );

    URISC_Control_Path#(
        .WIDTH(WIDTH), .DEPTH(DEPTH)
    ) C0 (
        .clk(clk),
        .reset(reset),
        .Run(Run),
        .Stop(Stop | Nop),
        .Neg(Neg),
        .Zero(Zero),
        .PC_out(PC_out),
        .PC_in(PC_in),
        .R_in(R_in),
        .Comp(Comp),
        .Z_in(Z_in),
        .N_in(N_in),
        .C_in(C_in),
        .MDR_in(MDR_in),
        .MAR_in(MAR_in),
        .MDR_out(MDR_out),
        .Data_CS(Data_CS),
        .Inst_CS(Inst_CS),
        .Read(Read),
        .Write(Write),
        .Counter(State)
    );

endmodule