import uvm_pkg::*;
`include "uvm_macros.svh"

interface apb_if(input bit pclk,prst);
		logic pwrite,psel,pen;
		logic [7:0]pwdata;
		logic [7:0]paddr;
		logic pready;
		logic [7:0]prdata;
		
				modport dut(input pclk,prst,pwrite,psel,pen,pwdata,paddr,output prdata,pready);
				modport tb(input pclk,prst,pready,prdata,output pwrite,psel,pen,pwdata,paddr);
endinterface

module apb_design_n(pclk,prst,psel,pen,paddr,pwrite,pwdata,pready,prdata);
		input pclk,prst,psel,pen,pwrite;
		input [7:0]paddr,pwdata;
		output pready;
		output reg [7:0]prdata;
		reg [7:0]mem[0:255];
		parameter IDLE=2'b00;
		parameter SETUP=2'b01;
		parameter ACCESS=2'b10;
		reg [1:0] state,next_state;
		assign pready=(psel && pen);
		always@(posedge pclk)
		begin
				if(prst)
				begin
						prdata<=0;
						state<=IDLE;
				end
				else
						state<=next_state;
		end
		always@(*)
		begin
				case(state)
						IDLE:if(psel==1'b1 && pen==1'b0)
								next_state=SETUP;
							 else
								next_state=IDLE;

						SETUP:if(psel==1'b1 && pen==1'b1)
									next_state=ACCESS;
							  else if(psel==1'b1 && pen==1'b0)
									next_state=SETUP;
							  else
									next_state=IDLE;
						ACCESS:if(psel==1'b1 && pen==1'b1) begin
								if(pwrite==1'b1) begin
										mem[paddr]<=pwdata;
								end
								else
										prdata<=mem[paddr];
								end
								else if(psel==1'b1 && pen==1'b0)
									next_state=SETUP;
								else
									next_state=IDLE;
				endcase
		end
endmodule

class apb_seq_item extends uvm_sequence_item;
		
		randc bit [7:0]pwdata;
		randc bit [7:0]paddr;
		rand bit psel,pen;
		rand bit pwrite;
		bit pready;
		bit [7:0]prdata;
		`uvm_object_utils_begin(apb_seq_item)
			`uvm_field_int(pwdata,UVM_ALL_ON|UVM_BIN);
			`uvm_field_int(paddr,UVM_ALL_ON|UVM_BIN);
			`uvm_field_int(psel,UVM_ALL_ON|UVM_BIN);
			`uvm_field_int(pen,UVM_ALL_ON|UVM_BIN);
			`uvm_field_int(pwrite,UVM_ALL_ON|UVM_BIN);
			`uvm_field_int(pready,UVM_ALL_ON|UVM_BIN);
			`uvm_field_int(prdata,UVM_ALL_ON|UVM_BIN);
		`uvm_object_utils_end
		function new(string name="apb_seq_item");
				super.new(name);
		endfunction
endclass

class sequence1 extends uvm_sequence#(apb_seq_item);
`uvm_object_utils(sequence1)
apb_seq_item pkt;
	function new(string name="sequence1");
				super.new(name);             
		endfunction
virtual task body();
repeat(10) begin
	pkt=apb_seq_item::type_id::create("pkt");
						begin
								start_item(pkt);
								pkt.pwdata=$random;
								pkt.paddr=$random;
								pkt.pwrite=1;
								pkt.psel=1;
								pkt.pen=0;
								finish_item(pkt);
								#10
								start_item(pkt);
								pkt.psel=1;
								pkt.pen=1;
								finish_item(pkt);
								#10
								start_item(pkt);
								pkt.pwrite=0;
								finish_item(pkt);
						end
                        end
endtask
endclass

class apb_seqr extends uvm_sequencer#(apb_seq_item);
		`uvm_component_utils(apb_seqr)
		function new(string name="apb_seqr",uvm_component parent);
				super.new(name,parent);
		endfunction
endclass


class apb_drv extends uvm_driver #(apb_seq_item);
		`uvm_component_utils(apb_drv)
		virtual apb_if intf;
		apb_seq_item pkt;
		function new(string name="apb_drv",uvm_component parent);
				super.new(name,parent);
		endfunction
		virtual function void build_phase(uvm_phase phase);
				super.build_phase(phase);
				uvm_config_db#(virtual apb_if)::get(this,"*","intf",intf);
		endfunction
		task run_phase(uvm_phase phase);
				pkt=apb_seq_item::type_id::create("pkt");
				forever
						#10
				begin
						seq_item_port.get_next_item(pkt);
						intf.pwdata=pkt.pwdata;
						intf.paddr=pkt.paddr;
						intf.pwrite=pkt.pwrite;
						intf.psel=pkt.psel;
						intf.pen=pkt.pen;
						seq_item_port.item_done();
				end
		endtask
endclass

class apb_mon1 extends uvm_monitor;
		`uvm_component_utils(apb_mon1)
		apb_seq_item pkt;
		virtual apb_if intf;
		bit[7:0] q[$];
		uvm_analysis_port #(apb_seq_item) item_collected_port;
		function new(string name="apb_mon1",uvm_component parent);
				super.new(name,parent);
				item_collected_port=new("item_collected_port",this);
                pkt=new();
		endfunction 
		virtual function void build_phase(uvm_phase phase);
				super.build_phase(phase);
				uvm_config_db#(virtual apb_if)::get(this,"","intf",intf);
		endfunction
		task run_phase(uvm_phase phase);
			//	pkt=apb_seq_item::type_id::create("pkt");
				forever
				begin
						@(posedge intf.pclk)
						pkt.pwdata<=intf.pwdata;
						pkt.paddr<=intf.paddr;
						pkt.pwrite<=intf.pwrite;
						pkt.psel<=intf.psel;
						pkt.pen<=intf.pen;

						begin
								#10
								q.push_front(pkt.pwdata);
								#20
								if(pkt.pwrite==0)
								begin
										pkt.prdata=q.pop_front();
								end
						end
		`uvm_info("MON1",$sformatf("pwdata=%p,paddr=%p,pwrite=%p",pkt.pwdata,pkt.paddr,pkt.pwrite),UVM_NONE);
						item_collected_port.write(pkt);
				end
		endtask
endclass

class apb_mon2 extends uvm_monitor;
		`uvm_component_utils(apb_mon2)
		apb_seq_item pkt;
		virtual apb_if intf;
		uvm_analysis_port #(apb_seq_item) item_collected_port1;
		function new(string name="apb_mon2",uvm_component parent);
				super.new(name,parent);
				item_collected_port1=new("item_collected_port1",this);
                pkt=new();
		endfunction
		virtual function void build_phase(uvm_phase phase);
				super.build_phase(phase);
				uvm_config_db#(virtual apb_if)::get(this," ","intf",intf);
		endfunction
		task run_phase(uvm_phase phase);
				//pkt=apb_seq_item::type_id::create("pkt");
				forever
				begin
						@(posedge intf.pclk)
						pkt.pready<=intf.pready;
						pkt.prdata<=intf.prdata;
						`uvm_info("MON2",$sformatf("pready=%d,prdata=%d",pkt.pready,pkt.prdata),UVM_NONE);
						item_collected_port1.write(pkt);
				end
		endtask
endclass

class apb_agent2 extends uvm_agent;
		`uvm_component_utils(apb_agent2)
		apb_mon2 mon2;
		function new(string name="apb_agent2",uvm_component parent);
				super.new(name,parent);
		endfunction
		virtual function void build_phase(uvm_phase phase);
				super.build_phase(phase);
				mon2=apb_mon2::type_id::create("mon2",this);
		endfunction
endclass

class apb_agent1 extends uvm_agent;
		`uvm_component_utils(apb_agent1)
		apb_seqr seqr;
		apb_drv drv;
		apb_mon1 mon1;
		virtual apb_if intf;
		function new(string name="apb_agent1",uvm_component parent);
				super.new(name,parent);
		endfunction
		virtual function void build_phase(uvm_phase phase);
				super.build_phase(phase);
				seqr=apb_seqr::type_id::create("seqr",this);
				drv=apb_drv::type_id::create("drv",this);
				mon1=apb_mon1::type_id::create("mon1",this);
		endfunction
		virtual function void connect_phase(uvm_phase phase);
				super.connect_phase(phase);
				drv.seq_item_port.connect(seqr.seq_item_export);
		endfunction
endclass

class apb_sb extends uvm_scoreboard;
		`uvm_component_utils(apb_sb)
		apb_seq_item pkt1,pkt2;
	//	coverage covg;
		uvm_tlm_analysis_fifo #(apb_seq_item)ip_fifo;
		uvm_tlm_analysis_fifo #(apb_seq_item)op_fifo;
		function new(string name="apb_sb",uvm_component parent);
				super.new(name,parent);
				ip_fifo=new("ip_fifo",this);
				op_fifo=new("op_fifo",this);
		endfunction
		virtual function void build_phase(uvm_phase phase);
				super.build_phase(phase);
				pkt1=apb_seq_item::type_id::create("pkt1",this);
				pkt2=apb_seq_item::type_id::create("pkt2",this);
			//	covg=coverage::type_id::create("covg",this);
		endfunction
		task run_phase(uvm_phase phase);
				forever
				begin
						fork
								ip_fifo.get(pkt1);
								op_fifo.get(pkt2);
						join
						if(pkt2.prdata==pkt1.prdata)
						begin
			`uvm_info("SB MATCHED",$sformatf("pkt1.prdata=%p,pkt2.prdata=%p",pkt1.prdata,pkt2.prdata),UVM_NONE);
						end
						else
						begin
			`uvm_info("SB MISMATCHED",$sformatf("pkt1.prdata=%p,pkt2.prdata=%p",pkt1.prdata,pkt2.prdata),UVM_NONE);
						end
					//	covg.p1=pkt1;
					//	covg.cvg.sample();
				end
		endtask
endclass

class apb_env extends uvm_env;
		`uvm_component_utils(apb_env)
		apb_agent1 a1;
		apb_agent2 a2;
		apb_sb sb;
		function new(string name="apb_env",uvm_component parent);
				super.new(name,parent);
		endfunction
		virtual function void build_phase(uvm_phase phase);
				super.build_phase(phase);
				a1=apb_agent1::type_id::create("a1",this);
				a2=apb_agent2::type_id::create("a2",this);
				sb=apb_sb::type_id::create("sb",this);
		endfunction
		virtual function void connect_phase(uvm_phase phase);
				super.connect_phase(phase);
        a1.mon1.item_collected_port.connect(sb.ip_fifo.analysis_export);
		a2.mon2.item_collected_port1.connect(sb.op_fifo.analysis_export);
		endfunction
endclass

class apb_test extends uvm_test;
		`uvm_component_utils(apb_test)
		apb_env env;
		sequence1 seq1;
		function new(string name="apb_test",uvm_component parent);
				super.new(name,parent);
		endfunction
		virtual function void build_phase(uvm_phase phase);
				super.build_phase(phase);
				env=apb_env::type_id::create("env",this);
				seq1=sequence1::type_id::create("seq1");
		endfunction
		task run_phase(uvm_phase phase);
				begin
						phase.raise_objection(this,"start of test");
						seq1.start(env.a1.seqr);
						phase.drop_objection(this,"end of test");
				end
		endtask\
        ]
endclass

module tb;
		bit pclk,prst;
		apb_if inf(pclk,prst);		
		apb_design_n uut(.pclk(inf.pclk),
						 .prst(inf.prst),
						 .pen(inf.pen),
						 .psel(inf.psel),
						 .pready(inf.pready),
				         .pwrite(inf.pwrite),
						 .pwdata(inf.pwdata),
						 .paddr(inf.paddr),
						 .prdata(inf.prdata)
		);
				initial begin
						prst=1;
						#10;
						prst=0;
				end
				initial begin
						pclk=1'b1;
						forever #5 pclk=~pclk;
				end
				initial begin
	uvm_config_db#(virtual apb_if)::set(uvm_root::get(),"*","intf",inf);
						run_test("apb_test");
				end
endmodule
