/*

   Delay 1 single port RAM
   read takes 1 cycle
   write takes 1 cycle
   Revisions:
      10/08/21: First created
      10/12/21: 
         usually SRAMS are not reset
         for APR purposes, reset's existence is better
*/

module spram 
#( parameter  WIDTH = 16,
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
   logic [WIDTH - 1 : 0] rdata_pre;
   logic [SIZE - 1 : 0][WIDTH - 1 : 0] entry, entry_w;
   assign rdata_pre = (ren == 1) ? entry[raddr] : 0;
   
   always_comb begin
      entry_w = entry;
      if (wen == 1) entry_w [waddr] = wdata;
   end
  
   always_ff @ (posedge clk or negedge rst_n) begin
      if (rst_n == 0) begin
         entry <= 0;
         rdata <= 0;
      end
      else begin
         entry <= entry_w;
         rdata <= rdata_pre;
      end
   end


endmodule 
