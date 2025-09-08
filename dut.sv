/*module apb_design_n(pclk,prst,psel,pen,paddr,pwrite,pwdata,pready,prdata);
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
endmodule*/

module apb_protocol (
    input  logic        pclk,
    input  logic        prst,
    input  logic        psel,
    input  logic        penable,
    input  logic        pwrite,
    input  logic [7:0]  paddr,
    input  logic [7:0]  pwdata,
    output logic [7:0]  prdata,
    output logic        pready
);

    logic [7:0] mem [0:255];
    assign pready = (psel && penable);

    typedef enum logic [1:0] {IDLE, SETUP, ACCESS} state_t;
    state_t state, next_state;

    always_ff @(posedge pclk ) begin
        if (prst) begin
            state  <= IDLE;
            prdata <= 8'd0;
        end
        else begin
            state <= next_state;
        end
    end

    always_comb begin
        next_state = state; 
        case (state)
            IDLE: begin
                if (psel && !penable)
                    next_state = SETUP;
            end

            SETUP: begin
                if (psel && penable)
                    next_state = ACCESS;
                else if (!psel)
                    next_state = IDLE;
            end

            ACCESS: begin
                if (psel && penable) begin
                    if (pwrite)
                        mem[paddr] = pwdata; 
                    else
                        prdata = mem[paddr];
                end

                if (psel && !penable)
                    next_state = SETUP;
                else if (!psel)
                    next_state = IDLE;
            end
        endcase
    end

endmodule


