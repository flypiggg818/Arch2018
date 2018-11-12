/* ACM Class System (I) 2018 Fall Assignment 1 
 *
 * Part I: Write an adder in Verilog
 *
 * Implement your naive adder here
 * 
 * GUIDE:
 *   1. Create a RTL project in Vivado
 *   2. Put this file into `Sources'
 *   3. Put `test_adder.v' into `Simulation Sources'
 *   4. Run Behavioral Simulation
 *   5. Make sure to run at least 100 steps during the simulation (usually 100ns)
 *   6. You can see the results in `Tcl console'
 *
 */

module adder(
	// TODO: Write the ports of this module here
	//
	// Hint: 
	//   The module needs 4 ports, 

	//     the first 2 ports are 16-bit unsigned numbers as the inputs of the adder
	//     the third port is a 16-bit unsigned number as the output
	//	   the forth port is a one bit port as the carry flag
	//
	input wire [15:0] A, B,
	output wire [15:0] rslt,
	output wire cout
);
    wire [15:0] c_rpl;
    reg cin; 
    
    assign cout = c_rpl[15]; 
    
    initial begin 
    	cin = 1'b0; 
    end 
    
    full_adder FA0(.in1(A[0]), .in2(B[0]), .cin(cin), .rslt(rslt[0]), .cout(c_rpl[0])); 
    full_adder FA1(.in1(A[1]), .in2(B[1]), .cin(c_rpl[0]), .rslt(rslt[1]), .cout(c_rpl[1]));
    full_adder FA2(.in1(A[2]), .in2(B[2]), .cin(c_rpl[1]), .rslt(rslt[2]), .cout(c_rpl[2]));
    full_adder FA3(.in1(A[3]), .in2(B[3]), .cin(c_rpl[2]), .rslt(rslt[3]), .cout(c_rpl[3]));
    full_adder FA4(.in1(A[4]), .in2(B[4]), .cin(c_rpl[3]), .rslt(rslt[4]), .cout(c_rpl[4]));
    full_adder FA5(.in1(A[5]), .in2(B[5]), .cin(c_rpl[4]), .rslt(rslt[5]), .cout(c_rpl[5]));
    full_adder FA6(.in1(A[6]), .in2(B[6]), .cin(c_rpl[5]), .rslt(rslt[6]), .cout(c_rpl[6]));
    full_adder FA7(.in1(A[7]), .in2(B[7]), .cin(c_rpl[6]), .rslt(rslt[7]), .cout(c_rpl[7]));
    full_adder FA8(.in1(A[8]), .in2(B[8]), .cin(c_rpl[7]), .rslt(rslt[8]), .cout(c_rpl[8]));
    full_adder FA9(.in1(A[9]), .in2(B[9]), .cin(c_rpl[8]), .rslt(rslt[9]), .cout(c_rpl[9]));
    full_adder FA10(.in1(A[10]), .in2(B[10]), .cin(c_rpl[9]), .rslt(rslt[10]), .cout(c_rpl[10]));
    full_adder FA11(.in1(A[11]), .in2(B[11]), .cin(c_rpl[10]), .rslt(rslt[11]), .cout(c_rpl[11]));
    full_adder FA12(.in1(A[12]), .in2(B[12]), .cin(c_rpl[11]), .rslt(rslt[12]), .cout(c_rpl[12]));
    full_adder FA13(.in1(A[13]), .in2(B[13]), .cin(c_rpl[12]), .rslt(rslt[13]), .cout(c_rpl[13]));
    full_adder FA14(.in1(A[14]), .in2(B[14]), .cin(c_rpl[13]), .rslt(rslt[14]), .cout(c_rpl[14]));
    full_adder FA15(.in1(A[15]), .in2(B[15]), .cin(c_rpl[14]), .rslt(rslt[15]), .cout(c_rpl[15])); 

endmodule

/**
sub-module used by module adder, which adds two bits and a carry together and gives 
the corresponding result and carry. 
*/
module full_adder(
    input wire in1, 
    input wire in2, 
    input wire cin,  
    output reg rslt, 
    output reg cout
);
    // This 'always' block will be synthesized to be logic gates. 
    always @ (in1, in2, cin)
    begin 
    {cout, rslt} = in1 + in2 + cin; 
    end
endmodule


