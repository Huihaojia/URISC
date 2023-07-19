module Mem #(
    parameter WIDTH = 'd16, DEPTH = 'd512
)(
    input clk,
    input reset,
    input CS,
    input Read,
    input Write,
    input [$clog2(DEPTH)-1:0] Addr,
    input [WIDTH-1:0] Data_in,
    output reg [WIDTH-1:0] Data_out
);

reg [WIDTH-1:0] Data [DEPTH-1:0];

initial begin
    $readmemh("dmem.txt", Data);
end

always@(*) begin
    if(!reset) begin
        Data_out <= 0;
    end else begin
        if(CS & Read) begin
            Data_out <= Data[Addr];
        end else begin
            Data_out <= 0;
        end
    end
end

always@(negedge clk) begin
    if(CS & Write) begin
        Data[Addr] <= Data_in;
    end
end

endmodule

module ROM #(
    parameter WIDTH = 'd16, DEPTH = 'd512
)(
    input clk,
    input reset,
    input CS,
    input Read,
    input [$clog2(DEPTH)-1:0] Addr,
    output reg [$clog2(DEPTH)-1:0] Data_out
);

    reg [$clog2(DEPTH)-1:0] Data [DEPTH-1:0];

    initial begin
        $readmemh("imem.txt", Data);
    end

    always@(*) begin
        if(!reset) begin
            Data_out <= 0;
        end else begin
            if(CS & Read) begin
                Data_out <= Data[Addr];
            end else begin
                Data_out <= 0;
            end
        end
    end

endmodule