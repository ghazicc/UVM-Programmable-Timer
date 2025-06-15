class timer_driver extends uvm_driver #(timer_sequence_item);

//1.UVM component
`uvm_component_utils(timer_driver)

//2. Initialization (vif & seq_item)
virtual timer_interface vif;
timer_sequence_item item; 

//3. Constructor
  function new(string name = "timer_driver", uvm_component parent);
    super.new(name, parent);
  endfunction : new

//4. Build Phase
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!(uvm_config_db#(virtual timer_interface)::get(this, "*", "vif", vif))) 
            begin
            `uvm_error("timer_driver", "Failed to get VIF from config DB!")
            end
  endfunction : build_phase


//5. Connect Phase
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction : connect_phase

//6. Run Phase
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    
    // Initialize signals
    vif.d <= 4'b0;
    vif.a <= 2'b0;
    vif.g0 <= 1'b0;
    vif.g1 <= 1'b0;
    
    forever begin
        item = timer_sequence_item::type_id::create("item");
        seq_item_port.get_next_item(item);
        drive(item);
        seq_item_port.item_done();
    end
  endtask : run_phase

//7. Drive
  task drive(timer_sequence_item item);
  
    `uvm_info(get_type_name(), $sformatf("Driver: Sending data to DUT\n %s", item.sprint()),UVM_NONE)
    
    @(negedge vif.clk);
    vif.d <= item.d;
    vif.a <= item.a;
    vif.g0 <= item.g0;
    vif.g1 <= item.g1;

  

  endtask : drive

endclass : timer_driver