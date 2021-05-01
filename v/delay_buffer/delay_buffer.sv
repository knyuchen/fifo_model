module delay_buffer #(parameter MAX_DELAY = 128, DATA_WIDTH = 32) (
   input            clk,
   input            rst_n,
   input          [DATA_WIDTH - 1 : 0]  data_in,
   input                                valid_in,
   output  logic                        valid_out,
   output  logic  [DATA_WIDTH - 1 : 0]  data_out,
   input          [$clog2(MAX_DELAY) - 1 : 0]  delay
);
   logic  [$clog2(MAX_DELAY) - 2 : 0] actual_delay;

   assign actual_delay = delay[$clog2(MAX_DELAY) - 1 : 1];
   
   // assigning IO for buffer

   logic [$clog2(MAX_DELAY) - 2 : 0]        addr_0, addr_1;
   logic [$clog2(MAX_DELAY) - 2 : 0]        write_ptr, write_ptr_w;  
   logic [$clog2(MAX_DELAY) - 2 : 0]        read_ptr,  read_ptr_w;  

   logic              even, even_w;

   logic [DATA_WIDTH - 1 : 0]     data_in_0,  data_in_1;
   logic [DATA_WIDTH - 1 : 0]     data_out_0,  data_out_1;

   logic           rd_0, rd_1, wr_0, wr_1;
   logic           rd, wr;
/*
   ram #(.DATA_WIDTH(DATA_WIDTH), .MEM_SIZE(MAX_DELAY/2)) ob0 (
      .clk(clk),
      .enable_write(wr_0),
      .enable_read (rd_0),
      .ctrl_write(wr_0),
      .addr(addr_0),
      .data_write(data_in_0),
      .data_read(data_out_0)
    );
   ram #(.DATA_WIDTH(DATA_WIDTH), .MEM_SIZE(MAX_DELAY/2)) ob1 (
      .clk(clk),
      .enable_write(wr_1),
      .enable_read (rd_1),
      .ctrl_write(wr_1),
      .addr(addr_1),
      .data_write(data_in_1),
      .data_read(data_out_1)
    );
*/
   mem #(.DATA_WIDTH(DATA_WIDTH), .MEM_SIZE(MAX_DELAY/2)) ob0 (
      .clk(clk),
      .wen(wr_0),
      .ren (rd_0),
      .addr(addr_0),
      .data_in(data_in_0),
      .data_out(data_out_0)
    );
   mem #(.DATA_WIDTH(DATA_WIDTH), .MEM_SIZE(MAX_DELAY/2)) ob1 (
      .clk(clk),
      .wen(wr_1),
      .ren (rd_1),
      .addr(addr_1),
      .data_in(data_in_1),
      .data_out(data_out_1)
    );
   
   logic  flag, flag_w;
   always_ff @ (posedge clk or negedge rst_n) begin
      if (rst_n == 0) begin
         flag <= 0;
         even <= 0;
         write_ptr <= 0;
         read_ptr <= 0;
      end
      else begin
         flag <= flag_w;
         even <= even_w;
         write_ptr <= write_ptr_w;
         read_ptr <= read_ptr_w;
      end
   end


   always_comb begin
      flag_w = flag;
      even_w = even;
      write_ptr_w = write_ptr;
      read_ptr_w = read_ptr;
      wr_1 = 0;
      wr_0 = 0;
      rd_1 = 0;
      rd_0 = 0;
/*
      if (cont_to_in.flush == 1) begin
         flag_w = 0;
         even_w = 0;
         write_ptr_w = 0;
         read_ptr_w = 0;
      end
      else begin
         if (cont_to_in.is_auto == 1) begin
*/
            if (in_valid == 1) begin
               if (flag == 1) begin // starting to write and read at the same time
                  if (even == 1) begin
                     wr_1 = 1;
                     rd_0 = 1;
                     even_w = 0;
                     write_ptr_w = write_ptr + 1;
                  end
                  else begin
                     wr_0 = 1;
                     rd_1 = 1;
                     even_w = 1;
                     read_ptr_w = read_ptr + 1;
                  end
               end
               else begin
                  if (even == 1) begin
                     wr_1 = 1;
                     even_w = 0;
                     write_ptr_w = write_ptr + 1;
                  end
                  else begin
                     wr_0 = 1;
                     even_w = 1;
                     if (write_ptr == actual_delay) begin
                        flag_w = 1;
                     end
                  end
               end
            end
/*
         end
      end
*/
   end

   always_comb begin
      addr_0 = 0;
      data_in_0 = 0;
      if (wr_0 == 1) begin
         addr_0 = write_ptr;
         data_in_0 = data_in.data;
      end
      else if (rd_0 == 1) begin
         addr_0 = read_ptr;
      end
   end  

   always_comb begin
      addr_1 = 0;
      data_in_1 = 0;
      if (wr_1 == 1) begin
         addr_1 = write_ptr;
         data_in_1 = data_in.data;
      end
      else if (rd_1 == 1) begin
         addr_1 = read_ptr;
      end
   end 
   
   logic [1:0]  read_pattern, read_pattern_w;
   assign read_pattern_w = {rd_1, rd_0};
   logic [DATA_WIDTH - 1 : 0]  mem_data_out_w, mem_data_out, mem_data_d;
   logic out_pipe0, out_pipe1, out_pipe2; 

   assign out_pipe0 = (read_pattern != 0);

   always_comb begin
      if (read_pattern == 2) mem_data_out_w = data_out_1; 
      else if (read_pattern == 1) mem_data_out_w = data_out_0;
      else mem_data_out_w = 0;
   end 

   always_ff @ (posedge clk or negedge rst_n) begin
      if (rst_n == 0) begin
         out_pipe1    <= 0;
         out_pipe2    <= 0;
         read_pattern <= 0;
         mem_data_out     <= 0;
         mem_data_d       <= 0;
      end
      else begin
         out_pipe1    <= out_pipe0;
         out_pipe2    <= out_pipe1;
         read_pattern <= read_pattern_w;
         mem_data_out     <= mem_data_out_w;
         mem_data_d   <= mem_data_out;
      end
   end
   
   assign data_out = (delay[0] == 1) ? mem_data_d : mem_data_out;
   assign valid_out = (delay[0] == 1) ? out_pipe2 : out_pipe1;

endmodule
