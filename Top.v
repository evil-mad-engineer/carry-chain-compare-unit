/*****************************************************************************
Copyright (c) 2019, John R. Peace
All rights reserved.

This file is part of the "carry-chain-compare-unit" project at:
https://github.com/evil-mad-engineer/carry-chain-compare-unit

Licensed under the BSD-3-Clause license.  For more information,
see the LICENSE file in the project repository at the URL above.
*****************************************************************************/

`timescale 1ns / 1ps

///////////////////////////////////////////////////////////////////////////////
//
// Create Date:	19:45:59 07/04/2019 
// Module Name:	Top.v
// Design Name:	Compare10
// Project Name:	cmp
// Target Device:	Xilinx Spartan-6
// Tool versions:	Xilinx ISE 14.7
// Description:	Sample module using Compare10, a ten-function compare unit
//
// Additional Comments:
//
// This top module was used to characterize the performance of the Compare10
// module.  It places registers both on the inputs and output of Compare10, so
// that the cycle time is determined only by the latency of that module's
// logic, which is purely combinational.  Of course, the cycle time may be
// limited further by the minimum period of the target device chosen.
//
// This module also places a (* KEEP_HIERARCHY = "soft" *) constraint on the
// instantiation of the Compare10 module.  The main motivation behind this
// constraint was simply to make it easy to isolate the resource usage of
// Compare10 in the detailed MAP report.  The value "soft" (instead of "yes")
// allows implementation to colocate the output register in the same slice as
// the logical element (i.e., look-up table or carry chain primitive),
// avoiding a fabric delay on the output.
//
///////////////////////////////////////////////////////////////////////////////

module Top(
	input			clk,
	input			rst,
	input	[3:0]	fcn,
	input	[N:0]	in1,
	input	[N:0]	in2,
	output		out
);
parameter	W = 32;	// bus width (word)

localparam	N = W-1;	// most significant bit (MSB) position of a word

reg	[N:0]	a_q, b_q;
reg	[3:0]	f_q;
reg			o_q;
wire			cmp_out;

always @(posedge clk) begin
	if (rst) begin
		a_q <= {W{1'b0}};
		b_q <= {W{1'b0}};
		f_q <= 4'b0;
		o_q <= 1'b0;
	end
	else begin
		a_q <= in1;
		b_q <= in2;
		f_q <= fcn;
		o_q <= cmp_out;
	end
end

assign out = o_q;

(* KEEP_HIERARCHY="soft" *)
Compare10 #(
	.W(W)
) cmp (
	.fcn(f_q),
	.a(a_q),
	.b(b_q),
	.o(cmp_out)
);

endmodule
