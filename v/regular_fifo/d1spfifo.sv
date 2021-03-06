/*
  SRAM delays 1 cycle, but fifo read is two cycle
  expects SIZE to be multiple of 2
  Needs to Ping-Pong between 2

  Collision handling
     favors read over write, must ensure timing correctness
     write is done in the same cycle, the next read must be to another bank
   Revisions:
      10/08/21: First Documentation, change some logic to make sure it handles SIZE != 2**N
*/
module d1spfifo 
#(
   parameter WIDTH = 16,
   parameter SIZE  = 32,
   parameter SRAM  = 0,
   parameter FULL  = 1,
   parameter EMPTY = 1,
   parameter AL_FULL = 2,
   parameter AL_EMPTY = 2,
   parameter ACK   = 1,
   parameter VALID = 1,
   parameter FLUSH = 1
)
(
   input                          clk,
   input                          rst_n,
   input                          push,
   input                          pop,
   input                          flush,
   input         [WIDTH - 1 : 0]  wdata,
   output  logic [WIDTH - 1 : 0]  rdata,
   output  logic                  full,
   output  logic                  empty,
   output  logic                  al_full,
   output  logic                  al_empty,
   output  logic                  ack,
   output  logic                  valid
);
   logic [$clog2(SIZE) : 0]             rd_ptr, rd_ptr_w;
   logic [$clog2(SIZE) : 0]             wr_ptr, wr_ptr_w;
   logic [$clog2(SIZE) : 0]             rd_ptr_cal, wr_ptr_cal;
   logic [$clog2(SIZE) : 0]             diff;

   logic real_flush;
   assign real_flush = (FLUSH == 1) ? flush : 0;

/*
  Readjustment to make sure that wr_ptr > rd_ptr
  Not an elegant implementation but seems to be the only way to accomadate for depth not 2**N
*/
   always_comb begin
      if (rd_ptr > wr_ptr) begin
         rd_ptr_cal = rd_ptr - SIZE;
         wr_ptr_cal = wr_ptr + SIZE;
      end
      else begin
       wr_ptr_cal = wr_ptr;
       rd_ptr_cal = rd_ptr;
      end
   end
   
   assign diff        = wr_ptr_cal - rd_ptr_cal;
   assign empty       = (EMPTY == 1)    ? (diff == 0)           : 0;
   assign full        = (FULL  == 1)    ? (diff == SIZE)        : 0;
   assign al_empty    = (AL_EMPTY != 0) ? ((diff == AL_EMPTY) || (diff < AL_EMPTY))    : 0;
   assign al_full     = (AL_FULL  != SIZE) ? ((diff == AL_FULL) || (diff > AL_FULL))     : 0;

   logic  wen, ren, corner;
   logic [$clog2(SIZE) - 1 : 0]  waddr, raddr; 

/*
   full replace & no empty feedthrough
*/
   assign wen         = push == 1 && (full  != 1 || (full == 1 && pop == 1)) && real_flush == 0 && corner == 0;
   assign ren         = pop  == 1 && empty != 1 && real_flush == 0;
   assign corner      = push == 1 && pop == 1 && empty == 1 && real_flush == 0;
   assign waddr       = (wen == 0) ? 0 : ((wr_ptr > SIZE - 1) ? wr_ptr - SIZE : wr_ptr);
   assign raddr       = (ren == 0) ? 0 : ((rd_ptr > SIZE - 1) ? rd_ptr - SIZE : rd_ptr);

   always_comb begin
      rd_ptr_w = rd_ptr;
      wr_ptr_w = wr_ptr;
      if (real_flush == 1) begin
         wr_ptr_w = 0;
         rd_ptr_w = 0;
      end
      else begin
/*
  More restrictions than just ren because of PEEK
*/
      if (ren == 1) begin
         if (rd_ptr == 2*SIZE - 1) rd_ptr_w = 0;
         else rd_ptr_w = rd_ptr + 1;
      end
      if (wen == 1) begin
         if (wr_ptr == 2*SIZE - 1) wr_ptr_w = 0;
         else wr_ptr_w = wr_ptr + 1;
      end
      end
   end
   
   assign ack   = (ACK   == 1) ? (((wen == 1) || (corner == 1)) && real_flush == 1)  : 0;
  
   logic  wen0, wen1, ren0, ren1;
/*
   addr to each bank is halved to support ping-pong
*/
   logic  [$clog2(SIZE) - 2 : 0] waddr0, waddr1, raddr0, raddr1;
   logic  [WIDTH - 1 : 0] wdata0, wdata1, rdata0, rdata1, rdata_pre;

   logic  valid_pre;

   assign ren0 = (raddr[0] == 0) ? ren : 0;
   assign ren1 = (raddr[0] == 1) ? ren : 0;
   assign raddr0 = (ren0 == 1) ? raddr[$clog2(SIZE) - 1 : 1] : 0;
   assign raddr1 = (ren1 == 1) ? raddr[$clog2(SIZE) - 1 : 1] : 0;
/*
   indicating which bank to read from
   [2] : bypass corner case
   [1] : bank 1
   [0] : bank 0
*/
   logic  [2:0] ren_d;
/*
   pipelining wdata in case of empty feedthrough
*/
   logic  [WIDTH - 1 : 0] wdata_d, wdata_dw;
   assign wdata_dw  = (corner == 1) ?  wdata : 0;
   assign valid_pre = (VALID == 1) ? (ren_d != 0 && real_flush == 0) : 0;

   assign rdata_pre = (real_flush == 1) ? 0 : ((ren_d[2] == 1)? wdata_d : ((ren_d[1] == 1) ? rdata1 : ((ren_d[0] == 1) ? rdata0 : 0)));
/*
   solving collision
*/  
   logic [$clog2(SIZE) - 2 : 0] addr_buf, addr_buf_w;
   logic [WIDTH - 1 : 0] data_buf, data_buf_w;
   logic [1:0]  indi_buf, indi_buf_w;
   logic buf_0, buf_1, clean_0, clean_1;  


   always_comb begin
      wen0 = 0;
      waddr0 = 0;
      wdata0 = 0;
      buf_0 = 0;
      clean_0 = 0;
      if (wen == 1 && waddr[0] == 0) begin
/*
  favors read when there is collision
*/
         if (ren0 == 1) begin
            buf_0 = 1;
         end
         else begin
            wen0 = 1;
            waddr0 = waddr[$clog2(SIZE) - 1 : 1];
            wdata0 = wdata;
         end
      end
/*
  write in buffered value
*/
      else if (indi_buf[0] == 1 && real_flush == 0) begin
         clean_0 = 1;
         wen0 = 1;
         wdata0 = data_buf;
         waddr0 = addr_buf;
      end
   end
   
   always_comb begin
      wen1 = 0;
      waddr1 = 0;
      wdata1 = 0;
      buf_1 = 0;
      clean_1 = 0;
      if (wen == 1 && waddr[0] == 1) begin
         if (ren1 == 1) begin
            buf_1 = 1;
         end
         else begin
            wen1 = 1;
            waddr1 = waddr[$clog2(SIZE) - 1 : 1];
            wdata1 = wdata;
         end
      end
      else if (indi_buf[1] == 1 && real_flush == 0) begin
         clean_1 = 1;
         wen1 = 1;
         wdata1 = data_buf;
         waddr1 = addr_buf;
      end
   end
/*
   Cleaning of buffer
*/   
   always_comb begin
      data_buf_w = data_buf;
      addr_buf_w = addr_buf;
      indi_buf_w = indi_buf;
      if ((buf_0 == 1 || buf_1 == 1) && real_flush == 0) begin
         data_buf_w = wdata;
         addr_buf_w = waddr[$clog2(SIZE) - 1 : 1];
      end
      case ({buf_1, buf_0, clean_1, clean_0})
         4'b0001: indi_buf_w = 2'b00;
         4'b0010: indi_buf_w = 2'b00;
         4'b0100: indi_buf_w = 2'b01;
         4'b0110: indi_buf_w = 2'b01;
         4'b1001: indi_buf_w = 2'b10;
         4'b1000: indi_buf_w = 2'b10;
         default: begin
         end
      endcase 
   end


 
   d1spram 
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
         addr_buf <= 0;
         data_buf <= 0;
         indi_buf <= 0;
         ren_d <= 0;
         valid <= 0;
         rdata <= 0;
         wdata_d <= 0;
      end
      else begin
         rd_ptr <= rd_ptr_w;
         wr_ptr <= wr_ptr_w;
         addr_buf <= addr_buf_w;
         data_buf <= data_buf_w;
         indi_buf <= indi_buf_w;
         ren_d <= {corner, ren1, ren0};
         rdata <= rdata_pre;
         valid <= valid_pre;
         wdata_d <= wdata_dw;
      end
   end
endmodule
