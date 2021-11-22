/*
   Needs to use SRAM-based RAM, read / write latency is 1 cycle
   Revisions:
      10/09/21: First Documentation
*/
module bitrev_fifo #
(  parameter DATA_WIDTH = 64,
   parameter MAX_POINT  = 8192,
   parameter FULL       = 1,
   parameter EMPTY      = 1,
   parameter SRAM       = `FFT_SRAM
)
(
   input                                        clk,
   input                                        rst_n,
   input   [$clog2($clog2(MAX_POINT)) - 1 : 0]  point,
   input   [DATA_WIDTH - 1 : 0] data_in,
   input                        push,
/*
   pop / valid takes 2 cycles, the next stage should be a fifo with empty / al_full as ready
*/
   output logic [DATA_WIDTH - 1 : 0]  data_out,
   output logic                 valid,
   input                        pop,
// Not exactly full but more like not able to take in more data (prty bank is being read / is full)
   output logic                 full,
// Not exactly empty but more like able to take in more input (pop) (prty bank is completely empty / being written to)
   output logic                 empty
);
/*
   mem_counter for writing in data, read_counter for read out
   mem_counter needs to be bit reversed, read_counter doesn't
*/
   logic [$clog2(MAX_POINT) - 1 : 0] mem_counter, mem_counter_w, thre, thre_seed;
   logic [$clog2(MAX_POINT) - 1 : 0] read_counter, read_counter_w;
   logic [$clog2(MAX_POINT) - 1 : 0] step, step_pre;

   assign thre_seed = '1;
/*
   Threshold for different points
*/
   assign thre = thre_seed >> ($clog2(MAX_POINT) - point);

   genvar i;
/*
   Bit reversing of mem_counter
*/

   generate
      for (i = 0; i < $clog2(MAX_POINT); i = i + 1) begin
         assign step_pre[i] = mem_counter[$clog2(MAX_POINT) -1 - i];
      end
   endgenerate

   

   assign step = step_pre >> ($clog2(MAX_POINT) - point);
   
   logic [$clog2(MAX_POINT) - 1 : 0]        addr_0, addr_1;
  
   logic [DATA_WIDTH - 1 : 0]     data_in_0,  data_in_1;
   logic [DATA_WIDTH - 1 : 0]     data_out_0, data_out_1;

   logic           rd_0, rd_1, wr_0, wr_1;
   logic           rd, wr;
// flag related, if = 1, means can do ~
   logic      wr_flag_0_w, wr_flag_0;
   logic      rd_flag_0_w, rd_flag_0;
   logic      wr_flag_1_w, wr_flag_1;
   logic      rd_flag_1_w, rd_flag_1;
   
   logic           finish_write_0, finish_write_1;
   logic           finish_read_0,  finish_read_1;
/*
   Indicating which bank to read / write now
   priority and flag has to match
*/

   logic  wr_prty, wr_prty_w;
   logic  rd_prty, rd_prty_w;

   assign full  = (FULL == 1)  ? ((wr_flag_0 == 0 && wr_prty == 0) || (wr_flag_1 == 0 && wr_prty == 1)) : 0;
   assign empty = (EMPTY == 1) ? ((rd_flag_0 == 0 && rd_prty == 0) || (rd_flag_1 == 0 && rd_prty == 1)) : 0;

   d1spram 
   #(.WIDTH(DATA_WIDTH), .SIZE(MAX_POINT), .SRAM(SRAM)) d0 
   (.*,
    .wen(wr_0),
    .ren(rd_0),
    .waddr(addr_0),
    .raddr(addr_0),
    .wdata(data_in_0),
    .rdata(data_out_0)
   ); 

   d1spram 
   #(.WIDTH(DATA_WIDTH), .SIZE(MAX_POINT), .SRAM(SRAM)) d1
   (.*,
    .wen(wr_1),
    .ren(rd_1),
    .waddr(addr_1),
    .raddr(addr_1),
    .wdata(data_in_1),
    .rdata(data_out_1)
   ); 
   

   always_comb begin
      wr_flag_0_w = wr_flag_0;
      wr_flag_1_w = wr_flag_1;
      rd_flag_0_w = rd_flag_0;
      rd_flag_1_w = rd_flag_1;
      wr_prty_w = wr_prty;
      rd_prty_w = rd_prty;
/*
  rd / wr prty can be the same value
*/
      if (finish_write_0 == 1) wr_prty_w = 1;
      else if (finish_write_1 == 1) wr_prty_w = 0;

      if (finish_read_0 == 1) rd_prty_w = 1;
      else if (finish_read_1 == 1) rd_prty_w = 0;
/*
  for the same bank, rd , wr flags should never be the same value
  same flag, different bank can be the same value, that's why we need prty
*/
      if (finish_write_0 == 1) begin
         wr_flag_0_w = 0;
      end
      else if (finish_read_0) begin
         wr_flag_0_w = 1;
      end 
      if (finish_write_1 == 1) begin
         wr_flag_1_w = 0;
      end
      else if (finish_read_1) begin
         wr_flag_1_w = 1;
      end 
      if (finish_write_0 == 1) begin
         rd_flag_0_w = 1;
      end
      else if (finish_read_0) begin
         rd_flag_0_w = 0;
      end 
      if (finish_write_1 == 1) begin
         rd_flag_1_w = 1;
      end
      else if (finish_read_1) begin
         rd_flag_1_w = 0;
      end 
   end


   always_ff @ (posedge clk or negedge rst_n) begin
      if (rst_n == 0) begin
         wr_flag_0 <= 1;
         wr_flag_1 <= 1;
         rd_flag_0 <= 0;
         rd_flag_1 <= 0;
      end
      else begin
         wr_flag_0 <= wr_flag_0_w;
         wr_flag_1 <= wr_flag_1_w;
         rd_flag_0 <= rd_flag_0_w;
         rd_flag_1 <= rd_flag_1_w;
      end
   end
   // ping-pong, giving write priority

   always_comb begin
      addr_0 = 0;
      addr_1 = 0;
      data_in_0 = 0;
      data_in_1 = 0;
      if (wr_0 == 1) begin
         addr_0 = step;
         data_in_0 = data_in;
      end
      else if (rd_0 == 1) begin
         addr_0 = read_counter;
      end
      if (wr_1 == 1) begin
         addr_1 = step;
         data_in_1 = data_in;
      end
      else if (rd_1 == 1) begin
         addr_1 = read_counter;
      end
   end 

   // writing into output buffer according to wr_flag, doesn't control flag
 
   always_comb begin
      wr_0 = 0;
      wr_1 = 0;
      mem_counter_w = mem_counter;
      finish_write_0 = 0;
      finish_write_1 = 0;
      if (push == 1) begin
/*
  always make sure bank ~ can be written and the prty is correct
*/
         if (wr_flag_0 == 1 && wr_prty == 0) begin
            wr_0 = 1;
            if (mem_counter == thre) begin
               mem_counter_w = 0;
               finish_write_0 = 1;
            end 
            else begin
               mem_counter_w = mem_counter + 1;
            end
         end
         else if (wr_flag_1 == 1 && wr_prty == 1) begin
            wr_1 = 1;
            if (mem_counter == thre) begin
               mem_counter_w = 0;
               finish_write_1 = 1;
            end 
            else begin
               mem_counter_w = mem_counter + 1;
            end
         end
      end
   end
   // reading from the output buffer
   always_comb begin
      rd_0 = 0;
      rd_1 = 0;
      finish_read_0 = 0; 
      finish_read_1 = 0;
      read_counter_w = read_counter; 
      if (pop == 1) begin
         if (rd_flag_0 == 1 && rd_prty == 0) begin
            rd_0 = 1;
            if (read_counter == thre) begin
               read_counter_w = 0;
               finish_read_0 = 1;
            end
            else begin
               read_counter_w = read_counter + 1;
            end
         end
         else if (rd_flag_1 == 1 && rd_prty == 1) begin
            rd_1 = 1;
            if (read_counter == thre) begin
               read_counter_w = 0;
               finish_read_1 = 1;
            end
            else begin
               read_counter_w = read_counter + 1;
            end
         end
      end
   end

   always_ff @ (posedge clk or negedge rst_n) begin
      if (rst_n == 0) begin
         mem_counter <= 0;
         read_counter <= 0;
      end
      else begin
         mem_counter <= mem_counter_w;
         read_counter <= read_counter_w;
      end
   end
   // output data

   logic [1:0]  read_pattern, read_pattern_w;
   assign read_pattern_w = {rd_1, rd_0};
   
   logic [DATA_WIDTH - 1 : 0]  data_out_w;

   always_comb begin
      if (read_pattern == 2) data_out_w = data_out_1;
      else if (read_pattern == 1) data_out_w = data_out_0;
      else data_out_w = 0;
   end 

   logic valid_w;

   assign valid_w = read_pattern != 0;

   always_ff @ (posedge clk or negedge rst_n) begin
      if (rst_n == 0) begin
         read_pattern <= 0;
         data_out     <= 0;
         valid <= 0;
         wr_prty <= 0;
         rd_prty <= 0;
      end
      else begin
         read_pattern <= read_pattern_w;
         data_out     <= data_out_w;
         valid <= valid_w;
         wr_prty <= wr_prty_w;
         rd_prty <= rd_prty_w;
      end
   end
endmodule
