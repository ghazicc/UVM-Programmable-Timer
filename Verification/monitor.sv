class timer_monitor extends uvm_monitor;

//1. Component
`uvm_component_utils(timer_monitor)

//2. Initializations
virtual timer_interface vif;
timer_sequence_item item ;

//3. Port
uvm_analysis_port #(timer_sequence_item) monitor_port;

//4. Constructor 
function new(string name = "timer_monitor", uvm_component parent);
    super.new(name, parent);
endfunction : new

//5. Build Phase
function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    monitor_port = new("monitor_port", this);
    if(!(uvm_config_db#(virtual timer_interface)::get(this,"*","vif",vif)))
    begin
            `uvm_error("timer_monitor", "Failed to get VIF from config DB!")
    end

endfunction : build_phase

//6. Connect Phase
function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
endfunction : connect_phase

//7. Run Phase
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
        item = timer_sequence_item::type_id::create("item");
      @(posedge vif.clk);

        // Capture inputs
        item.d = vif.d;
        item.a = vif.a;
        item.g0 = vif.g0;
        item.g1 = vif.g1;
        
        // Capture outputs
        item.out0 = vif.out0;
        item.out1 = vif.out1;

        `uvm_info(get_type_name(), ("Monitor: Sending data to Scoreboard"), UVM_MEDIUM)
        monitor_port.write(item);
    end
  endtask : run_phase

endclass: timer_monitor