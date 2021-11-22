/*
   modeling SRAM
   write delay is 1
   read  delay is 1
   Revisions:
      10/11/21: First Documentation, added FPGA mode, replace ram with generic spram
      10/12/21: Usually rams shouldn't have reset, added for better APR
*/
module d1spram
#(
   parameter  SRAM = 0,
   parameter  WIDTH = 16,
   parameter  SIZE  = 32
)
(
   input                          clk,
   input                          rst_n,
   input                          wen,
   input                          ren,
   input  [$clog2(SIZE) - 1 : 0]  waddr,
   input  [$clog2(SIZE) - 1 : 0]  raddr,
   input  [WIDTH - 1 : 0]         wdata,
   output logic [WIDTH - 1 : 0]   rdata
);

   logic real_wen, real_ren;
   logic [$clog2(SIZE) - 1 : 0] addr;
   assign addr = (real_wen == 1) ? waddr : raddr;
   assign real_wen = wen;
   assign real_ren = (real_wen == 0) ? ren : 0;
`ifdef FPGA
   ram #(.DATA_WIDTH(WIDTH), .MEM_SIZE(SIZE)) r1 
   (
     .*,
     .enable_write(wen),
     .enable_read(ren),
     .ctrl_write(wen),
     .data_write(wdata),
     .data_read(rdata)
    );
`else
   generate 
      if (SRAM == 0) begin
         spram #(.WIDTH(WIDTH), .SIZE(SIZE))s1 (.*);
      end else begin
         spsram #(.WIDTH(WIDTH), .SIZE(SIZE))s1 (.*);
   end endgenerate 
`endif
endmodule
