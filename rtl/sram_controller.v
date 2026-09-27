// Code your design here
module sram_controller (
    input        clk,
    input        rst_n,

    input        cs,          // Chip Select
    input        we,          // Write Enable
    input        oe,          // Output Enable / Read request

    input  [7:0] addr,
    inout  [7:0] data,

    output reg   ready
);

   
    // State encoding
    
    parameter IDLE       = 3'b000;
    parameter READ       = 3'b001;
    parameter WRITE      = 3'b010;
    parameter READ_DONE  = 3'b011;
    parameter WRITE_DONE = 3'b100;

    reg [2:0] state;
    reg [2:0] next_state;

  
    // SRAM memory
    // 256 locations × 8 bits

    reg [7:0] mem [0:255];

    
    // Read data register
    
    reg [7:0] data_out;

    
    // Controls the bidirectional data bus
    
    reg output_en;
   
  
    //      SRAM releases DATA

    assign data = output_en ? data_out : 8'hZZ;


  
    // State register
   
    always @(posedge clk or negedge rst_n) begin

        if (!rst_n)
            state <= IDLE;

        else
            state <= next_state;

    end


  
    // Next-state logic
  
    always @(*) begin

        next_state = IDLE;

        case (state)

           
            // IDLE
           
            IDLE: begin

                if (cs && we)
                    next_state = WRITE;

                else if (cs && !we && oe)
                    next_state = READ;

                else
                    next_state = IDLE;

            end


            
            // READ
          
            READ: begin

                next_state = READ_DONE;

            end


           
            // WRITE
           
            WRITE: begin

                next_state = WRITE_DONE;

            end


            
            // READ DONE
          
            READ_DONE: begin

                next_state = IDLE;

            end


            
            // WRITE DONE
          
            WRITE_DONE: begin

                next_state = IDLE;

            end


           
            // DEFAULT
            
            default: begin

                next_state = IDLE;

            end

        endcase

    end


    
    // Output and memory operation logic
   
    always @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            data_out  <= 8'h00;
            output_en <= 1'b0;
            ready     <= 1'b0;

        end

        else begin

            case (state)

              
                // IDLE
                
                IDLE: begin

                    output_en <= 1'b0;
                    ready     <= 1'b0;

                end


               
                // WRITE
               
                WRITE: begin

                    mem[addr] <= data;

                    output_en <= 1'b0;
                    ready     <= 1'b0;

                end


               
                // READ
               
                READ: begin

                    data_out  <= mem[addr];
                    output_en <= 1'b1;
                    ready     <= 1'b0;

                end


               
                // READ DONE
                
                READ_DONE: begin

                    // Keep read data on the bus
                    output_en <= 1'b1;

                    // Tell master that read is complete
                    ready     <= 1'b1;

                end


               
                // WRITE DONE
                
                WRITE_DONE: begin

                    // Do not drive the data bus after a write
                    output_en <= 1'b0;

                    // Tell master that write is complete
                    ready     <= 1'b1;

                end


               
                // DEFAULT
               
                default: begin

                    output_en <= 1'b0;
                    ready     <= 1'b0;

                end

            endcase

        end

    end

endmodule
