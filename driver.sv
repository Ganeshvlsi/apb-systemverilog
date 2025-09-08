class driver extends uvm_driver#(seq_item);

`uvm_component_utils(driver)
function new(string name,uvm_component parent);
super.new(name,parent);
endfunction

function void build_phase(uvm_phase phase);
super.build_phase(phase);
if(!uvm_config_db#())
endfunction

task run_phase (uvm_phase phase);
super.run_phase(phase);

endtask
endclass
