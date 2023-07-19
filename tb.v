//`timescale 1ns/1ps

module testbench();
    reg clk, rst;
    reg Run, Stop;
    wire [15:0] Data_out, Data_in;
    wire [8:0] Inst_in, MAR;
    wire Data_CS, Inst_CS, Read, Write;
    wire [3:0] State;

    initial begin
        clk = 0;
        rst = 0;
        Run = 0;
        Stop = 0;
        #6
        rst = 1;
        @(posedge clk)
        Run = 1;
        @(posedge clk)
        Run = 0;
        #20000
        $finish;
    end

    always #5 clk = ~clk;

    URISC U0(
        .clk(clk),
        .reset(rst),
        .Run(Run),
        .Stop(Stop),
	.Data_in(Data_in),
	.Inst_in(Inst_in),
	.Data_CS(Data_CS),
	.Inst_CS(Inst_CS),
	.Read(Read),
	.Write(Write),
	.MAR(MAR),
        .Data_out(Data_out),
        .State(State)
    );

    Mem #(
        .WIDTH('d16), .DEPTH('d512)
    ) Data_Mem ( 
        .clk(clk),
        .reset(reset),
        .CS(Data_CS),
        .Read(Read),
        .Write(Write),
        .Addr(MAR),
        .Data_in(Data_out),
        .Data_out(Data_in)
    );

    ROM #(
        .WIDTH('d16), .DEPTH('d512)
    ) Inst_Mem (
        .clk(clk),
        .reset(reset),
        .CS(Inst_CS),
        .Read(Read),
        .Addr(MAR),
        .Data_out(Inst_in)
    );
    
    initial begin
        $fsdbDumpfile("testbench.fsdb");
        $fsdbDumpMDA(0, testbench);
        $fsdbDumpvars(0, testbench);
        
        $vcdpluson;
        $vcdplusmemon;
        $vcdplusfile("testbench.vpd");
        
        $dumpon;
        $dumpfile("testbench.vpd");
        $dumpvars(0, testbench);
        $dumpoff;
        $display("dump success");
    end

endmodule