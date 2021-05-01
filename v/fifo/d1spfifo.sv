module d1spfifo 
#(
   parameter WIDTH = 16,
   parameter SIZE  = 32,
   parameter SRAM  = 1,
   parameter FULL  = 1,
   parameter EMPTY = 1,
   parameter AL_FULL = 2,
   parameter AL_EMPTY = 2,
   parameter ACK   = 1,
   parameter VALID = 1
)
(
   input                          clk,
   input                          rst_n,
   input                          push,
   input                          pop,
   input         [WIDTH - 1 : 0]  wdata,
   output  logic [WIDTH - 1 : 0]  rdata,
   output  logic                  full,
   output  logic                  empty,
   output  logic                  al_full,
   output  logic                  al_empty,
   output  logic                  ack,
   output  logic                  valid
)
   logic [$clog2(SIZE) : 0]             rd_ptr, rd_ptr_w;
   logic [$clog2(SIZE) : 0]             wr_ptr, wr_ptr_w;
   logic [$clog2(SIZE) : 0]             rd_ptr_cal, wr_ptr_cal;
   logic [$clog2(SIZE) : 0]             diff;

   always_comb begin
      if (rd_ptr_cal[$clog2(SIZE)] ^ wr_ptr_cal[$clog2(SIZE)] == 1) begin
         rd_ptr_cal = {1'b0, rd_ptr[$clog2(SIZE) - 1 : 0]};
         wr_ptr_cal = {1'b1, wr_ptr[$clog2(SIZE) - 1 : 0]};
      end
      else begin
         rd_ptr_cal = rd_ptr;
         wr_ptr_cal = wr_ptr;
      end
   end
   
   assign diff        = wr_ptr_cal - rd_ptr_cal;
   assign empty       = (EMPTY == 1)    ? (diff == 0)           : 0;
   assign full        = (FULL  == 1)    ? (diff == SIZE)        : 0;
   assign al_empty    = (AL_EMPTY != 0) ? (diff == AL_EMPTY)    : 0;
   assign al_full     = (AL_FULL  != 0) ? (diff == AL_FULL)     : 0;

   logic  wen, ren;
   logic [$clog2(SIZE) - 1 : 0]  waddr, raddr; 

   assign wen         = push == 1 && full  != 1;
   assign ren         = pop  == 1 && empty != 1;
   assign waddr       = (wen == 1) ? wr_ptr[$clog2(SIZE) - 1 : 0];
   assign raddr       = (ren == 1) ? rd_ptr[$clog2(SIZE) - 1 : 0];

   assign wr_ptr_w = (wen == 1) ? wr_ptr + 1 : wr_ptr;
   assign rd_ptr_w = (ren == 1) ? rd_ptr + 1 : rd_ptr;
   
   assign ack   = (ACK   == 1) ? wen : 0;
   assign valid = (VALID == 1) ? ren : 0;
  
   logic  wen0, wen1, ren0, ren1;
   logic  [$clog2(SIZE) - 2 : 0] waddr0, waddr1, raddr0, raddr1;
   logic  [WIDTH - 1 : 0] wdata0, wdata1, rdata0, rdata1;

 
   d0spram 
   #(.WIDTH(WIDTH), .SIZE(SIZE/2), .SRAM(SRAM)) d0 
   (.*,
    .wen(wen0),
    .ren(ren0),
    .waddr(waddr0),
    .raddr(raddr0),
    .wdata(wdata0),
    .rdata(rdata0)
   ); 

   d1spram 
   #(.WIDTH(WIDTH), .SIZE(SIZE/2), .SRAM(SRAM)) d1 
   (.*,
    .wen(wen1),
    .ren(ren1),
    .waddr(waddr1),
    .raddr(raddr1),
    .wdata(wdata1),
    .rdata(rdata1)
   ); 

   always_ff @ (posedge clk or negedge rst_n) begin
      if (rst_n == 0) begin
         rd_ptr <= 0;
         wr_ptr <= 0;
      end
      else begin
         rd_ptr <= rd_ptr_w;
         wr_ptr <= wr_ptr_w;
      end
   end
endmodule
