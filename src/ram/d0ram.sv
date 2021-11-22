/*

   Delay 0 RAM
   read directly pops out in the same cycle
   write takes 1 cycle
   Revisions:
      10/11/21: First Documentation

*/

module d0ram 
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

   logic [SIZE - 1 : 0][WIDTH - 1 : 0] entry, entry_w;
   assign rdata = (ren == 1) ? entry[raddr] : 0;
// assign rdata = entry[raddr];
   
   always_comb begin
      entry_w = entry;
      if (wen == 1) entry_w [waddr] = wdata;
   end
  
   always_ff @ (posedge clk or negedge rst_n) begin
      if (rst_n == 0) begin
         entry <= 0;
      end
      else begin
         entry <= entry_w;
      end
   end


endmodule 
