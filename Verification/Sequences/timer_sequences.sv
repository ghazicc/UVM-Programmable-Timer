// Timer Basic Sequence - Tests basic functionality with 3-cycle write protocol
class timer_basic_sequence extends timer_base_sequence;
  
  `uvm_object_utils(timer_basic_sequence)
  
  function new(string name = "timer_basic_sequence");
    super.new(name);
  endfunction
  
  task body();
    timer_sequence_item req;
    
    `uvm_info(get_type_name(), "Starting Timer Basic Sequence", UVM_LOW)
    
    // Test basic 3-cycle write protocol for counter0
    write_timer_counter(1'b0, 3'b000, 8'd10); // Counter0, Mode 0, Count 10
    
    // Run for several cycles to observe output
    repeat(20) begin
      req = timer_sequence_item::type_id::create("req");
      start_item(req);
      req.a = 2'b11;  // Don't care address
      req.d = 4'b0;
      req.g0 = 1'b1;
      req.g1 = 1'b0;
      finish_item(req);
    end
    
    `uvm_info(get_type_name(), "Timer Basic Sequence Complete", UVM_LOW)
  endtask
  
  // Helper task for 3-cycle timer write
  task write_timer_counter(bit counter_sel, bit [2:0] mode, bit [7:0] count_val);
    timer_sequence_item req;
    
    // Cycle 1: Write control register
    req = timer_sequence_item::type_id::create("req");
    start_item(req);
    req.a = 2'b10;  // Control register address
    req.d = {counter_sel, mode};  // Counter select + mode
    req.g0 = 1'b1;
    req.g1 = 1'b1;
    finish_item(req);
    
    // Cycle 2: Write MSN to appropriate counter address
    req = timer_sequence_item::type_id::create("req");
    start_item(req);
    req.a = {counter_sel, 1'b0};  // Counter address (00 for counter0, 10 for counter1)
    req.d = count_val[7:4];  // Most significant nibble
    req.g0 = 1'b1;
    req.g1 = 1'b1;
    finish_item(req);
    
    // Cycle 3: Write LSN to complete the count value
    req = timer_sequence_item::type_id::create("req");
    start_item(req);
    req.a = {counter_sel, 1'b0};  // Same counter address
    req.d = count_val[3:0];  // Least significant nibble
    req.g0 = 1'b1;
    req.g1 = 1'b1;
    finish_item(req);
  endtask
  
endclass

// Timer Mode Sequence - Tests all operating modes with proper protocol
class timer_mode_sequence extends timer_base_sequence;
  
  `uvm_object_utils(timer_mode_sequence)
  
  function new(string name = "timer_mode_sequence");
    super.new(name);
  endfunction
  
  task body();
    timer_sequence_item req;
    
    `uvm_info(get_type_name(), "Starting Timer Mode Sequence", UVM_LOW)
    
    // Test each mode (0-4) for counter0
    for(int mode = 0; mode < 5; mode++) begin
      bit [7:0] test_count;
      
      // Choose appropriate count value based on mode constraints
      case (mode)
        2: test_count = 8'd10;   // Mode 2: even number
        3, 4: test_count = 8'd9; // Mode 3,4: odd number
        default: test_count = 8'd8; // General case
      endcase
      
      `uvm_info(get_type_name(), $sformatf("Testing Mode %0d with count %0d", mode, test_count), UVM_LOW)
      
      // Write timer configuration using 3-cycle protocol
      write_timer_counter(1'b0, mode[2:0], test_count); // Counter0
      
      // Let timer run for several cycles to observe behavior
      repeat(test_count * 2 + 5) begin
        req = timer_sequence_item::type_id::create("req");
        start_item(req);
        req.a = 2'b11;  // Don't care address
        req.d = 4'b0;
        req.g0 = 1'b1;  // Enable counter0
        req.g1 = 1'b0;
        finish_item(req);
      end
    end
    
    // Test counter1 with one mode
    `uvm_info(get_type_name(), "Testing Counter1", UVM_LOW)
    write_timer_counter(1'b1, 3'b000, 8'd60); // Counter1, Mode 0, Count 60
    
    repeat(30) begin
      req = timer_sequence_item::type_id::create("req");
      start_item(req);
      req.a = 2'b11;
      req.d = 4'b0;
      req.g0 = 1'b0;
      req.g1 = 1'b1;  // Enable counter1
      finish_item(req);
    end
    
    `uvm_info(get_type_name(), "Timer Mode Sequence Complete", UVM_LOW)
  endtask
  
  // Helper task for 3-cycle timer write
  task write_timer_counter(bit counter_sel, bit [2:0] mode, bit [7:0] count_val);
    timer_sequence_item req;
    
    // Cycle 1: Write control register
    req = timer_sequence_item::type_id::create("req");
    start_item(req);
    req.a = 2'b10;  // Control register address
    req.d = {counter_sel, mode};  // Counter select + mode
    req.g0 = 1'b1;
    req.g1 = 1'b1;
    finish_item(req);
    
    // Cycle 2: Write MSN to appropriate counter address
    req = timer_sequence_item::type_id::create("req");
    start_item(req);
    req.a = {counter_sel, 1'b0};  // Counter address
    req.d = count_val[7:4];  // Most significant nibble
    req.g0 = 1'b1;
    req.g1 = 1'b1;
    finish_item(req);
    
    // Cycle 3: Write LSN to complete the count value
    req = timer_sequence_item::type_id::create("req");
    start_item(req);
    req.a = {counter_sel, 1'b0};  // Same counter address
    req.d = count_val[3:0];  // Least significant nibble
    req.g0 = 1'b1;
    req.g1 = 1'b1;
    finish_item(req);
  endtask
  
endclass

// Timer Counter Sequence - Tests counter range boundaries
class timer_counter_sequence extends timer_base_sequence;
  
  `uvm_object_utils(timer_counter_sequence)
  
  function new(string name = "timer_counter_sequence");
    super.new(name);
  endfunction
  
  task body();
    timer_sequence_item req;
    
    `uvm_info(get_type_name(), "Starting Timer Counter Sequence", UVM_LOW)
    
    // Test Counter0 boundaries (2-150)
    logic [7:0] counter0_values[5] = '{8'd2, 8'd5, 8'd50, 8'd100, 8'd150};
    
    foreach(counter0_values[i]) begin
      `uvm_info(get_type_name(), $sformatf("Testing Counter0 with value %0d", counter0_values[i]), UVM_LOW)
      
      // Write counter0 using 3-cycle protocol
      write_timer_counter(1'b0, 3'b000, counter0_values[i]);
      
      // Run timer for several cycles
      repeat(20) begin
        req = timer_sequence_item::type_id::create("req");
        start_item(req);
        req.a = 2'b11;
        req.d = 4'b0;
        req.g0 = 1'b1;
        req.g1 = 1'b0;
        finish_item(req);
      end
    end
    
    // Test Counter1 boundaries (50-200)
    logic [7:0] counter1_values[5] = '{8'd50, 8'd75, 8'd100, 8'd150, 8'd200};
    
    foreach(counter1_values[i]) begin
      `uvm_info(get_type_name(), $sformatf("Testing Counter1 with value %0d", counter1_values[i]), UVM_LOW)
      
      // Write counter1 using 3-cycle protocol
      write_timer_counter(1'b1, 3'b000, counter1_values[i]);
      
      // Run timer for several cycles
      repeat(15) begin
        req = timer_sequence_item::type_id::create("req");
        start_item(req);
        req.a = 2'b11;
        req.d = 4'b0;
        req.g0 = 1'b0;
        req.g1 = 1'b1;
        finish_item(req);
      end
    end
    
    `uvm_info(get_type_name(), "Timer Counter Sequence Complete", UVM_LOW)
  endtask
  
  // Helper task for 3-cycle timer write
  task write_timer_counter(bit counter_sel, bit [2:0] mode, bit [7:0] count_val);
    timer_sequence_item req;
    
    // Cycle 1: Write control register
    req = timer_sequence_item::type_id::create("req");
    start_item(req);
    req.a = 2'b10;
    req.d = {counter_sel, mode};
    req.g0 = 1'b1;
    req.g1 = 1'b1;
    finish_item(req);
    
    // Cycle 2: Write MSN
    req = timer_sequence_item::type_id::create("req");
    start_item(req);
    req.a = {counter_sel, 1'b0};
    req.d = count_val[7:4];
    req.g0 = 1'b1;
    req.g1 = 1'b1;
    finish_item(req);
    
    // Cycle 3: Write LSN
    req = timer_sequence_item::type_id::create("req");
    start_item(req);
    req.a = {counter_sel, 1'b0};
    req.d = count_val[3:0];
    req.g0 = 1'b1;
    req.g1 = 1'b1;
    finish_item(req);
  endtask
  
endclass

// Timer Gate Sequence - Tests gate control functionality
class timer_gate_sequence extends timer_base_sequence;
  
  `uvm_object_utils(timer_gate_sequence)
  
  function new(string name = "timer_gate_sequence");
    super.new(name);
  endfunction
  
  task body();
    timer_sequence_item req;
    
    `uvm_info(get_type_name(), "Starting Timer Gate Sequence", UVM_LOW)
    
    // Setup counter0 with a known configuration
    write_timer_counter(1'b0, 3'b000, 8'd8);
    
    // Test gate control patterns
    bit gate_patterns[16] = '{1,1,1,0,0,0,1,1,0,1,0,1,1,0,0,1};
    
    foreach(gate_patterns[i]) begin
      req = timer_sequence_item::type_id::create("req");
      start_item(req);
      req.a = 2'b11;  // Don't care address
      req.d = 4'b0;
      req.g0 = gate_patterns[i];
      req.g1 = gate_patterns[i];
      finish_item(req);
    end
    
    `uvm_info(get_type_name(), "Timer Gate Sequence Complete", UVM_LOW)
  endtask
  
  // Helper task for 3-cycle timer write
  task write_timer_counter(bit counter_sel, bit [2:0] mode, bit [7:0] count_val);
    timer_sequence_item req;
    
    // Cycle 1: Write control register
    req = timer_sequence_item::type_id::create("req");
    start_item(req);
    req.a = 2'b10;
    req.d = {counter_sel, mode};
    req.g0 = 1'b1;
    req.g1 = 1'b1;
    finish_item(req);
    
    // Cycle 2: Write MSN
    req = timer_sequence_item::type_id::create("req");
    start_item(req);
    req.a = {counter_sel, 1'b0};
    req.d = count_val[7:4];
    req.g0 = 1'b1;
    req.g1 = 1'b1;
    finish_item(req);
    
    // Cycle 3: Write LSN
    req = timer_sequence_item::type_id::create("req");
    start_item(req);
    req.a = {counter_sel, 1'b0};
    req.d = count_val[3:0];
    req.g0 = 1'b1;
    req.g1 = 1'b1;
    finish_item(req);  endtask

endclass
