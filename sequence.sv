class sequence1 extends uvm_sequence#(seq_item);

`uvm_object_utils(sequence1)
function new(string name="");
super.new(name);
endfunction

task body();
`uvm_do(req)
endtask

endclass
