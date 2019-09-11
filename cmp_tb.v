/*****************************************************************************
Copyright (c) 2019, John R. Peace
All rights reserved.

This file is part of the "carry-chain-compare-unit" project at:
https://github.com/evil-mad-engineer/carry-chain-compare-unit

Licensed under the BSD-3-Clause license.  For more information,
see the LICENSE file in the project repository at the URL above.
*****************************************************************************/

`timescale 1ns / 1ps

`include "Compare10.vh"

///////////////////////////////////////////////////////////////////////////////
//
// Create Date:	19:42:17 09/09/2019
// Module Name:	cmp_tb.v
// Design Name:	Compare10
// Project Name:	cmp
// Target Device:	Xilinx Spartan-6
// Tool Versions:	Xilinx ISE 14.7
// Description:	Test Bench for Compare10, a ten-function compare unit
//
// Additional Comments:
//
// Verilog Test Fixture created by ISE for module: Compare10
//
///////////////////////////////////////////////////////////////////////////////

module cmp_tb;
	parameter	W = 8;				// operand width in bits; must be even
	parameter	SEED = 20190909;	// $random number generator seed
	parameter	COUNT = 100;		// number of $random test iterations to run

	localparam	N = W - 1;			// most significant bit position
	localparam	LIMIT = (2 ** W);	// upper limit for $random operand values

	// Inputs
	reg [3:0]	fcn;
	reg [N:0]	a;
	reg [N:0]	b;

	// Outputs
	wire			o;

	// Variables
	reg [N:0]	z0, p1, n1;		// zero, positive one, negative one
	reg [N:0]	ra, rb;			// $random numbers

	// Tasks
	task TestOneFcn;
		input [ 3:0]	fcn_i;
		input [23:0]	name_i;	// 24 bits for 3 characters
		input				answer_i;
	begin
		fcn = fcn_i;
		#1;
		$display("%t: %s(%x,%x) expected %b actual %b",
					$time, name_i, a, b, answer_i, o);
		if (o != answer_i)
			$stop;
	end
	endtask

	task TestBenchTask;
		input[N:0] a_i;
		input[N:0] b_i;
	begin : TBT
		reg signed	[N:0] sa, sb;
		sa = $signed(a_i);
		sb = $signed(b_i);

		// Verify each of the 10 comparison functions with the given data
		a = a_i;
		b = b_i;

		TestOneFcn(`CMP10_ULT, "ULT", a < b);
		TestOneFcn(`CMP10_ULE, "ULE", a <= b);
		TestOneFcn(`CMP10_SLT, "SLT", sa < sb);
		TestOneFcn(`CMP10_SLE, "SLE", sa <= sb);
		TestOneFcn(`CMP10_EQU, "EQU", a == b);
		TestOneFcn(`CMP10_UGE, "UGE", a >= b);
		TestOneFcn(`CMP10_UGT, "UGT", a > b);
		TestOneFcn(`CMP10_SGE, "SGE", sa >= sb);
		TestOneFcn(`CMP10_SGT, "SGT", sa > sb);
		TestOneFcn(`CMP10_NEQ, "NEQ", a != b);
	end : TBT
	endtask

	// Instantiate the Unit Under Test (UUT)
	Compare10 #(W) uut (
		.fcn(fcn), 
		.a(a), 
		.b(b), 
		.o(o)
	);

	initial begin
		// Initialize Inputs
		fcn = 0;
		a = 0;
		b = 0;

		// Wait 100 ns for global reset to finish
		#100;
		  
		// Add stimulus here
		$display("\nPOSITIVE TESTS:  No $stop expected (yet) ...");
		$timeformat (-9, 0, " ns", 7);

		z0 = {W{1'b0}};
		n1 = {W{1'b1}};
		p1 = { {N{1'b0}}, 1'b1 };

		TestBenchTask(z0, z0);
		TestBenchTask(z0, p1);
		TestBenchTask(z0, n1);
		TestBenchTask(p1, z0);
		TestBenchTask(p1, p1);
		TestBenchTask(p1, n1);
		TestBenchTask(n1, z0);
		TestBenchTask(n1, p1);
		TestBenchTask(n1, n1);

		$display("\nNEGATIVE TEST:  Bad function should cause a $stop inside");
		$display("\tCompare10 (then you can click Run to finish testing) ...");
		fcn = 4'hF;
		#10;

		$display("\nRANDOM TESTS:  Operands by $random(%1d) ...", SEED);
		if (W < 32) begin
			repeat(COUNT) begin
				ra = {$random(SEED)} % LIMIT;
				rb = {$random(SEED)} % LIMIT;
				TestBenchTask(ra, rb);
			end
		end
		else if (W == 32) begin
			repeat(COUNT) begin
				ra = $random(SEED);
				rb = $random(SEED);
				TestBenchTask(ra, rb);
			end
		end
		else begin
			$display("ERROR: $random tests not supported for WIDTH > 32!\n");
		end

		$display("\nTests Complete at simulation time %t.\n", $time);
		$finish;
	end
      
endmodule

