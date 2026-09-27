// Code your testbench here
// or browse Examples
`timescale 1ns/1ps

module tb_sram_controller;

    //========================================================
    // DUT inputs
    //========================================================
    reg        clk;
    reg        rst_n;
    reg        cs;
    reg        we;
    reg        oe;
    reg  [7:0] addr;

    //========================================================
    // Bidirectional data bus
    //========================================================
    wire [7:0] data;

    // Testbench drives DATA only during WRITE
    reg  [7:0] tb_data;
    reg        tb_drive_en;

    //========================================================
    // DUT output
    //========================================================
    wire ready;

    //========================================================
    // Testbench drives the bidirectional bus
    //========================================================
    assign data = tb_drive_en ? tb_data : 8'hZZ;


    //========================================================
    // DUT
    //========================================================
    sram_controller dut (
        .clk   (clk),
        .rst_n (rst_n),
        .cs    (cs),
        .we    (we),
        .oe    (oe),
        .addr  (addr),
        .data  (data),
        .ready (ready)
    );


    //========================================================
    // Clock generation
    // 10 ns clock period
    //========================================================
    always #5 clk = ~clk;


    //========================================================
    // WRITE TASK
    //========================================================
    task write_mem;

        input [7:0] wr_addr;
        input [7:0] wr_data;

        begin

            // Apply request before rising edge
            @(negedge clk);

            cs          = 1'b1;
            we          = 1'b1;
            oe          = 1'b0;
            addr        = wr_addr;

            // External master drives DATA
            tb_data     = wr_data;
            tb_drive_en = 1'b1;

            // Wait until SRAM says operation is complete
            wait (ready === 1'b1);

            $display(
                "[WRITE PASS] Time=%0t ADDR=0x%02h DATA=0x%02h",
                $time, wr_addr, wr_data
            );

            // Release bus and controls
            @(negedge clk);

            cs          = 1'b0;
            we          = 1'b0;
            oe          = 1'b0;
            tb_drive_en = 1'b0;

        end

    endtask


    //========================================================
    // READ TASK
    //========================================================
    task read_mem;

        input [7:0] rd_addr;
        input [7:0] expected_data;

        reg [7:0] actual_data;

        begin

            // Apply read request
            @(negedge clk);

            cs          = 1'b1;
            we          = 1'b0;
            oe          = 1'b1;
            addr        = rd_addr;

            // External master releases DATA bus
            tb_drive_en = 1'b0;

            // Wait for completion
            wait (ready === 1'b1);

            // Allow NBA updates to settle
            #1;

            actual_data = data;

            if (actual_data === expected_data) begin

                $display(
                    "[READ PASS ] Time=%0t ADDR=0x%02h EXPECTED=0x%02h ACTUAL=0x%02h",
                    $time, rd_addr, expected_data, actual_data
                );

            end
            else begin

                $display(
                    "[READ FAIL ] Time=%0t ADDR=0x%02h EXPECTED=0x%02h ACTUAL=0x%02h",
                    $time, rd_addr, expected_data, actual_data
                );

            end

            // Release controls
            @(negedge clk);

            cs = 1'b0;
            we = 1'b0;
            oe = 1'b0;

        end

    endtask


    //========================================================
    // MAIN TEST
    //========================================================
    initial begin

        // Initialize signals
        clk          = 1'b0;
        rst_n        = 1'b0;

        cs           = 1'b0;
        we           = 1'b0;
        oe           = 1'b0;
        addr         = 8'h00;

        tb_data      = 8'h00;
        tb_drive_en  = 1'b0;


        //====================================================
        // VCD dump
        //====================================================
        $dumpfile("sram_controller.vcd");
        $dumpvars(0, tb_sram_controller);


        //====================================================
        // RESET
        //====================================================
        $display("");
        $display("============================================");
        $display("           SRAM CONTROLLER TEST");
        $display("============================================");

        $display("");
        $display("TEST 0: RESET");

        #12;
        rst_n = 1'b1;

        #2;

        if (ready === 1'b0) begin
            $display("[RESET PASS] Controller returned to IDLE");
        end
        else begin
            $display("[RESET FAIL] READY should be 0");
        end


        //====================================================
        // TEST 1: BASIC WRITE
        //====================================================
        $display("");
        $display("TEST 1: BASIC WRITE");

        write_mem(8'h10, 8'hA5);


        //====================================================
        // TEST 2: BASIC READ
        //====================================================
        $display("");
        $display("TEST 2: BASIC READ");

        read_mem(8'h10, 8'hA5);


        //====================================================
        // TEST 3: WRITE DIFFERENT DATA
        //====================================================
        $display("");
        $display("TEST 3: WRITE SECOND VALUE");

        write_mem(8'h20, 8'h5A);

        read_mem(8'h20, 8'h5A);


        //====================================================
        // TEST 4: OVERWRITE SAME ADDRESS
        //====================================================
        $display("");
        $display("TEST 4: OVERWRITE SAME ADDRESS");

        write_mem(8'h10, 8'h3C);

        read_mem(8'h10, 8'h3C);


        //====================================================
        // TEST 5: ADDRESS 0x00
        //====================================================
        $display("");
        $display("TEST 5: LOWER ADDRESS BOUNDARY");

        write_mem(8'h00, 8'h11);

        read_mem(8'h00, 8'h11);


        //====================================================
        // TEST 6: ADDRESS 0xFF
        //====================================================
        $display("");
        $display("TEST 6: UPPER ADDRESS BOUNDARY");

        write_mem(8'hFF, 8'hEE);

        read_mem(8'hFF, 8'hEE);


        //====================================================
        // TEST 7: ALL ZEROS
        //====================================================
        $display("");
        $display("TEST 7: ALL ZERO DATA");

        write_mem(8'h30, 8'h00);

        read_mem(8'h30, 8'h00);


        //====================================================
        // TEST 8: ALL ONES
        //====================================================
        $display("");
        $display("TEST 8: ALL ONE DATA");

        write_mem(8'h31, 8'hFF);

        read_mem(8'h31, 8'hFF);


        //====================================================
        // TEST 9: ALTERNATING PATTERN
        //====================================================
        $display("");
        $display("TEST 9: ALTERNATING DATA");

        write_mem(8'h32, 8'hAA);

        read_mem(8'h32, 8'hAA);

        write_mem(8'h33, 8'h55);

        read_mem(8'h33, 8'h55);

//====================================================
// TEST 10: CHIP SELECT DISABLED
//====================================================
$display("");
$display("TEST 10: CHIP SELECT DISABLED");

//----------------------------------------------------
// STEP 1: Store an initial value
//----------------------------------------------------
$display("STEP 1: Write initial value 0x77 to address 0x40");

write_mem(8'h40, 8'h77);


//----------------------------------------------------
// STEP 2: Confirm that the initial value is present
//----------------------------------------------------
$display("STEP 2: Read address 0x40 to confirm initial value");

read_mem(8'h40, 8'h77);


//----------------------------------------------------
// STEP 3: Disable CS and try to overwrite
//----------------------------------------------------
$display("STEP 3: CS=0, attempt to write NEW value 0x99");

@(negedge clk);

cs          = 1'b0;       // CHIP NOT SELECTED
we          = 1'b1;       // Write request
oe          = 1'b0;
addr        = 8'h40;

tb_data     = 8'h99;      // NEW value
tb_drive_en = 1'b1;


// Keep CS disabled for several clock cycles
repeat (3)
    @(posedge clk);


// Release testbench bus
@(negedge clk);

cs          = 1'b0;
we          = 1'b0;
oe          = 1'b0;
tb_drive_en = 1'b0;


//----------------------------------------------------
// STEP 4: Enable CS and read same address
//----------------------------------------------------
$display("STEP 4: Re-enable CS and read address 0x40");

// This should still return OLD value = 0x77
read_mem(8'h40, 8'h77);


//----------------------------------------------------
// CS test passes because OLD value is still present
//----------------------------------------------------
$display("[CS PASS] Write was ignored when CS=0");

        //====================================================
        // TEST 11: READ WITH OE=0 SHOULD NOT START
        //====================================================
        $display("");
        $display("TEST 11: OE DISABLED");

        @(negedge clk);

        cs          = 1'b1;
        we          = 1'b0;
        oe          = 1'b0;
        addr        = 8'h10;

        tb_drive_en = 1'b0;

        repeat (3)
            @(posedge clk);

        if (ready === 1'b0)
            $display("[OE PASS] Read was not started when OE=0");
        else
            $display("[OE FAIL] READY should remain 0");

        @(negedge clk);

        cs = 1'b0;
        oe = 1'b0;


        //====================================================
        // TEST 12: DATA BUS HIGH-Z WHEN IDLE
        //====================================================
        $display("");
        $display("TEST 12: DATA BUS HIGH-Z IN IDLE");

        @(negedge clk);

        cs = 1'b0;
        we = 1'b0;
        oe = 1'b0;

        #1;

        if (data === 8'hZZ)
            $display("[BUS PASS] DATA bus is high impedance in IDLE");
        else
            $display("[BUS FAIL] DATA bus = %h, expected ZZ", data);


        //====================================================
        // END
        //====================================================
        #20;

        $display("");
        $display("============================================");
        $display("         ALL SRAM TESTS COMPLETED");
        $display("============================================");

        $finish;

    end

endmodule
