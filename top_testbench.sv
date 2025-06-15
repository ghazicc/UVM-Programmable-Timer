`include "uvm_macros.svh"
import uvm_pkg::*;

// Include timer verification files
`include "Design/dut.sv"
`include "Verification/reference_mode.sv"
`include "Verification/interface.sv"
`include "Verification/sequence_item.sv"
`include "Verification/Sequences/base_sequence.sv"
`include "Verification/Sequences/timer_sequences.sv"
`include "Verification/sequencer.sv"
`include "Verification/driver.sv"
`include "Verification/monitor.sv"
`include "Verification/scoreboard.sv"
`include "Verification/agent.sv"
`include "Verification/environment.sv"
`include "Verification/base_test.sv"
`include "Verification/operation_test.sv"

module top;

  // Clock generation
  bit clk;
  initial begin
    clk = 0;
    forever #5ns clk = ~clk;  // 100MHz clock
  end

  // Interface instantiation
  timer_interface vif(clk);

  // DUT instantiation
  timer dut (
    .d(vif.d),
    .a(vif.a),
    .clk(vif.clk),
    .g0(vif.g0),
    .g1(vif.g1),
    .out0(vif.out0),
    .out1(vif.out1)
  );

  initial begin
    // Set the virtual interface in config DB
    uvm_config_db#(virtual timer_interface)::set(uvm_root::get(),"*","vif",vif);
    
    // Set verbosity level
    uvm_config_db#(int)::set(uvm_root::get(),"*","recording_detail",UVM_FULL);
    
    // Start the test
    run_test("timer_test");
  end

  // Maximum simulation time
  initial begin
    #100;  // Maximum simulation time
    `uvm_fatal("TB_TOP", "Simulation timeout!")
  end

  // Generate waveforms
  initial begin
    $dumpfile("timer_tb.vcd");
    $dumpvars(0, top);
  end

endmodule : top
