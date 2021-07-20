module bitrev_fifo #
(  parameter DATA_WIDTH = 32,
   parameter MAX_POINT  = 64,
   parameter FULL       = 1,
   parameter EMPTY      = 1,
   parameter SRAM       = 0
)
(
   input   [$clog2($clog2(MAX_POINT)) - 1 : 0]  point,
   input   [DATA_WIDTH - 1 : 0] data_in,
   input                        push,
   output logic [DATA_WIDTH - 1 : 0]  data_out,
   output logic                 valid,
   input                        pop,
   output logic                 full,
   output logic                 empty
);

   logic [$clog2(MAX_POINT) - 1 : 0] mem_counter, mem_counter_w;
   logic [$clog2(MAX_POINT) - 1 : 0] read_counter, read_counter_w;
   logic [$clog2(MAX_POINT) - 1 : 0] step, step_pre;
   logic [$clog2(MAX_POINT) - 1 : 0] addr_out;  // address to output buffer

   genvar i;

   generate
      for (i = 0; i < $clog2(MAX_POINT); i = i + 1) begin
         assign step_pre[i] = mem_counter[$clog2(MAX_POINT) - i];
      end
   endgenerate

   assign step = step_pre >> ($clog2(MAX_POINT) - point);
   
   logic [$clog2(MAX_POINT) - 1 : 0]        addr_0, addr_1;
  
   logic [DATA_WIDTH - 1 : 0]     data_in_0,  data_in_1;
   logic [DATA_WIDTH - 1 : 0]     data_out_0, data_out_1;

   logic           rd_0, rd_1, wr_0, wr_1;
   logic           rd, wr;
// flag related
   logic      wr_flag_0_w, wr_flag_0;
   logic      rd_flag_0_w, rd_flag_0;
   logic      wr_flag_1_w, wr_flag_1;
   logic      rd_flag_1_w, rd_flag_1;
   
   logic           finish_write_0, finish_write_1;
   logic           finish_read_0,  finish_read_1;

   assign full  = (FULL == 1)  ? (wr_flag_0 == 0 && wr_flag_1 == 0) : 0;
   assign empty = (EMPTY == 1) ? (rd_flag_0 == 0 && rd_flag_1 == 0) : 0;

   d1spram 
   #(.WIDTH(DATA_WIDTH), .SIZE(MAX_POINT), .SRAM(1)) d1 
   (.*,
    .wen(wr_0),
    .ren(rd_0),
    .waddr(addr_0),
    .raddr(addr_0),
    .wdata(data_in_0),
    .rdata(data_out_0)
   ); 

   d1spram 
   #(.WIDTH(DATA_WIDTH), .SIZE(MAX_POINT), .SRAM(1)) d1
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
         data_in_0 = real_data_in.data;
      end
      else if (rd_0 == 1) begin
         addr_0 = read_counter;
      end
      if (wr_1 == 1) begin
         addr_1 = step;
         data_in_1 = real_data_in.data;
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
         if (wr_flag_0 == 1) begin
            wr_0 = 1;
            if (mem_counter == thre) begin
               mem_counter_w = 0;
               finish_write_0 = 1;
            end 
            else begin
               mem_counter_w = mem_counter + 1;
            end
         end
         else if (wr_flag_1 == 1) begin
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
         if (rd_flag_0 == 1) begin
            rd_0 = 1;
            if (read_counter == thre) begin
               read_counter_w = 0;
               finish_read_0 = 1;
            end
            else begin
               read_counter_w = read_counter + 1;
            end
         end
         else if (rd_flag_1 == 1) begin
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
      else data_out_w.data = 0;
   end 

   assign valid = read_pattern != 0;

   always_ff @ (posedge clk or negedge rst_n) begin
      if (rst_n == 0) begin
         read_pattern <= 0;
         data_out     <= 0;
      end
      else begin
         read_pattern <= read_pattern_w;
         data_out     <= data_out_w;
      end
   end
endmodule
