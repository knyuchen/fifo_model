/*
   modeling SRAM
   write delay is 1
   read  delay is 1
*/
module d1spram
#(
   parameter  SRAM = 0,
   parameter  WIDTH = 16,
   parameter  SIZE  = 32
)
(
   input                          clk,
   input                          wen,
   input                          ren,
   input  [$clog2(SIZE) - 1 : 0]  waddr,
   input  [$clog2(SIZE) - 1 : 0]  raddr,
   input  [WIDTH - 1 : 0]         wdata,
   output logic [WIDTH - 1 : 0]   rdata
);
   logic [SIZE - 1 : 0][WIDTH - 1 : 0] entry, entry_w;
   logic real_ren, real_wen;
   logic [WIDTH - 1 : 0]rdata_w;


   generate 
      if (SRAM == 0) begin
         assign real_wen = wen;
         assign real_ren = (real_wen == 0) ? ren : 0;
         assign rdata_w  = (real_ren == 1) ? entry[raddr] : 0;
         always_comb begin
            entry_w = entry;
            if (real_wen == 1) entry_w [waddr] = wdata;
         end
 
         always_ff @ (posedge clk or negedge rst_n) begin
            entry <= entry_w;
            rdata <= rdata_w;
         end

      end else begin
         spsram s1 #(.WIDTH(WIDTH), .SIZE(SIZE)) (.*);
   end endgenerate 
endmodule
