class timer_scoreboard extends uvm_scoreboard;
  
  int trans_count = 0;
  
  //1. Component
  `uvm_component_utils(timer_scoreboard)

  //2. Port
  uvm_analysis_imp #(timer_sequence_item, timer_scoreboard) scoreboard_port;

  //3. Reference Model
  timer_reference_model ref_model;

  //4. Transactions
  timer_sequence_item transactions[$];
  
  //5. Statistics
  int passed_tests = 0;
  int failed_tests = 0;

  //6. Constructor
  function new(string name = "timer_scoreboard", uvm_component parent);
    super.new(name, parent);
  endfunction : new

  //7. Build Phase
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    scoreboard_port = new("scoreboard_port", this);
    ref_model = new();
  endfunction : build_phase

  //8. Connect Phase
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction : connect_phase

  //9. Write 
  function void write(timer_sequence_item item);
    transactions.push_back(item);
    `uvm_info(get_type_name(), ("Scoreboard: Accept transaction item!"), UVM_MEDIUM)
    item.print();
  endfunction : write

  //10. Run Phase
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      timer_sequence_item trans;
      wait ((transactions.size() != 0));
      trans = transactions.pop_front();
      
      if(trans_count > 0)
      	compare(trans);
      trans_count++;
    end
  endtask : run_phase

  task compare(timer_sequence_item trans);
    bit expected_out0, expected_out1;
    bit actual_out0, actual_out1;
    
    // Update reference model with current transaction
    ref_model.write_register(trans.a, trans.d);
    ref_model.clock_edge(trans.g0, trans.g1);
    
    // Get expected outputs from reference model
    expected_out0 = ref_model.get_out0_expected();
    expected_out1 = ref_model.get_out1_expected();
    
    // Get actual outputs
    actual_out0 = trans.out0;
    actual_out1 = trans.out1;

    // Compare outputs
    if ((actual_out0 !== expected_out0) || (actual_out1 !== expected_out1)) begin
        failed_tests++;
        `uvm_error(get_type_name(), "✘ TEST FAILED ✘")
        `uvm_info("Scoreboard", 
            $sformatf("Address: %2b, Data: %4b, G0: %b, G1: %b\nActual: out0=%b out1=%b\nExpected: out0=%b out1=%b", 
                     trans.a, trans.d, trans.g0, trans.g1,
                     actual_out0, actual_out1, expected_out0, expected_out1), 
            UVM_NONE)
        `uvm_info(get_type_name(), 
            "┌─────────────────────────────────────────────┐", 
            UVM_NONE)
        `uvm_info(get_type_name(), 
            "│           ✘ Mismatch Detected ✘            │", 
            UVM_NONE)
        `uvm_info(get_type_name(), 
            "└─────────────────────────────────────────────┘", 
            UVM_NONE)
        
        // Print reference model state for debugging
        ref_model.print_state();
    end else begin
        passed_tests++;
        `uvm_info(get_type_name(), "✓ TEST PASSED ✓", UVM_LOW)
        `uvm_info("Scoreboard", 
            $sformatf("Address: %2b, Data: %4b, G0: %b, G1: %b\nOutputs: out0=%b out1=%b (Match!)", 
                     trans.a, trans.d, trans.g0, trans.g1,
                     actual_out0, actual_out1), 
            UVM_LOW)
    end
  endtask : compare

  //11. Report Phase
  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(), 
        $sformatf("Timer Verification Complete: %0d Passed, %0d Failed", 
                 passed_tests, failed_tests), UVM_NONE)
    
    if (failed_tests == 0) begin
        `uvm_info(get_type_name(), 
            "┌─────────────────────────────────────────────┐", UVM_NONE)
        `uvm_info(get_type_name(), 
            "│        ✓ ALL TESTS PASSED ✓               │", UVM_NONE)
        `uvm_info(get_type_name(), 
            "└─────────────────────────────────────────────┘", UVM_NONE)
    end else begin
        `uvm_info(get_type_name(), 
            "┌─────────────────────────────────────────────┐", UVM_NONE)
        `uvm_info(get_type_name(), 
            "│         ✘ SOME TESTS FAILED ✘             │", UVM_NONE)
        `uvm_info(get_type_name(), 
            "└─────────────────────────────────────────────┘", UVM_NONE)
    end
  endfunction : report_phase

endclass : timer_scoreboard