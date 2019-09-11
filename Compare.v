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
// Create Date:	13:23:04 09/09/2019
// Module Name:	Compare10.v
// Design Name:	Compare10
// Project Name:	cmp
// Target Device:	Xilinx Spartan-6
// Tool Versions:	Xilinx ISE 14.7
// Description:	Source for Compare10, a ten-function muxless compare unit
//
// Additional Comments:
//
//		OVERVIEW
//
// This module assumes an FPGA device with six-input look up table (LUT6)
// primitives; for instance, the Xilinx Spartan-6 and its LUT6_2 primitive.
// We also assume the existence of dedicated carry-chain hardware separate
// from, but directly connected to, the LUT6 primitives (i.e., without fabric
// routing); for instance, the Xilinx Spartan-6 CARRY4 primitive.  We further
// assume that the carry-chain hardware implements carry-in and carry-out
// (propagate) signals, and may directly implement XOR (generate) signals.
// Finally, we assume that synthesis of the Verilog addition operator (+) with
// multi-bit operands infers a combination of LUT6 and carry-chain primitives
// that are "better" (i.e., faster and/or smaller) than other combinations of
// logical elements that could be connected to perform the same operation.
//
// A carry chain of LUT6 primitives can be used to perform up to 8 functions
// on 2 operand bits per LUT, producing a single-bit result on carry-out.  An
// additional logical element (not necessarily a LUT) at the end of the carry
// chain can then optionally invert the result via an XOR (generate) output,
// for a total of 16 possible functions.  This fits well with the 10 standard
// numeric comparison operations, where five are complements of the other
// five.  For instance, we will use the following functions and acronyms:
//
//	0. unsigned less than					(ULT)
//	1. unsigned less than or equal		(ULE)
//	2. signed less than						(SLT)
//	3. signed less than or equal			(SLE)
//	4. equals									(EQU)
//	5. unsigned greater than				(UGT = ~SLE)
//	6. unsigned greater than or equal	(UGE = ~UGT)
//	7. signed greater than					(SGT = ~SLE)
//	8. signed greater than or equal		(SGE = ~SLT)
//	9. not equal								(NEQ = ~EQU)
//
// Note that the numbers above are for illustration only.  The actual function
// names and numbers are `define'd in the separate header file "Compare10.vh"
// and are NOT identical to the acronyms and values above, although they are
// still intended to be self-explanatory (and self-documenting, for the most
// part).
//
//		BASIC COMPARISON ALGORITHMS: ULT, ULE, SLT, SLE, and EQU
//
// Magnitude (unsigned) comparisons (e.g., ULT, ULE) of multi-bit operands
// generally involve comparing each pair of bits from the most significant bit
// position (MSB) to the least significant bit position (LSB), stopping at the
// first bit-pair that isolates a True or False result.  Specifically, when a
// bit-pair at level X (MSB <= X < LSB) compares equal, level X will defer to
// the result from level X-1, the next one "down."  The LSB bit applies a more
// stringent comparison to disambiguate the result if that bit-pair is equal,
// too (e.g., the end result is False for ULT and True for ULE).
//
// Arithmetic (signed) comparisons (e.g., SLT, SLE) work exactly the same as
// magnitude comparisons, except for sign processing at the MSB bit (also
// known as the sign bit in software parlance).  In lieu of a full explanation
// of twos-complement representation and math, I will just assert that for the
// sign bit (and only that bit!), arithmetic comparisons are backwards from
// magnitude comparisons.  Specifically: (1 < 0), (0 > 1), (0 == 0), (1 == 1)
//
// Equality comparisons (i.e., EQU) also work much the same way as magnitude
// comparisons, except that there are only two possible outcomes at each bit
// position.  For all levels, if a bit-pair compares as not equal, the final
// result is guaranteed to be False.  Otherwise, for the "bottom" (LSB) level,
// the final result is True.  Otherwise, for the "top" level or any "middle"
// level X (MSB <= X < LSB), the result is ambiguous at that level; level X
// must defer to the result from the next level down, level X-1.
//
//		DERIVED COMPARISON OPERATIONS: UGT, UGE, SGT, SGE, and NEQ
//
// Given the previous five comparison functions, the remaining five can be
// obtained by complementing the result of each of the first five functions,
// as shown in the Overview section.  In general, this requires one more logic
// element in addition to the logic elements for the first five comparisons.
// However, depending on the device architecture, this logic element may or
// may not be the same kind of primitive used elsewhere in the implementation
// (e.g., it may be a dedicated part of the carry-chain primitive instead of a
// general look-up table primitive).
//
//		THEORY OF OPERATION
//
// Note that the following discussion is specific to six-input look-up tables.
// FPGA devices that support a different number of inputs per logical element
// should be able to synthesize the Compare10 unit, but the resulting
// implementation may be suboptimal by a substantial amount.  The effects will
// probably be especially pronounced on FPGA devices with fewer inputs per LUT
// (e.g., Xilinx Spartan-3 devices, which use a four-input LUT architecture).
//
// To implement the above logic with a carry chain, each level X of the chain
// (MSB <= X <= LSB) must be given a control signal specifying the function
// required of it, and some small number of bit-pairs to compare; it must then
// place its result on carry-out.  All levels Y (MSB <= Y < LSB) also accept a
// result from level Y-1 on carry-in; in contrast, the LSB position does not
// depend on carry-in.  The number of control signals determines the number of
// bit-pairs that can be supported at each level: If the control signal is
// only a single bit wide, two bit-pairs can be supported; control signals of
// width 2 or 3 bits will only allow a single bit-pair to be compared at that
// level.  (And any control signal larger than 3 bits will not work properly.)
//
// One additional logic element (not necessarily a LUT) is required to perform
// the complement operation when necessary.  Note that bitwise complementation
// is simply not possible using carry-out (propagate) logic; in the context of
// a carry-chain adder, the complement operation requires an XOR (generate)
// output instead.  As a result, this additional bit position "breaks the
// chain" so to say, and must therefore be prepended to the original carry
// chain (i.e., a new bit position MSB+1).  Fortunately, that's the natural
// position for the final operation of a carry chain adder, so no problem.
//
//		HIGH-LEVEL DESIGN
//
// Less-than (ULT) and less-than-or-equal (ULE) require the same logic in the
// "middle" bit positions M (MSB < M < LSB).  And as asserted in the Overview,
// there is no distinction between signed and unsigned comparisons at these
// positions.  Therefore, the LUTs implementing these middle levels need only
// distinguish between equality comparison (EQU) and the other four basic
// comparisons (ULT/ULE/SLT/SLE).  Hence these LUTs require just one control
// signal, making 4 inputs available to support two bit-pairs of operand data.
//
// In contrast, the LSB position does need to distinguish between ULT and ULE
// (and equivalently between SLT and SLE), as well as EQU.  This requires at
// least two control signals, making only 2 inputs available for other data.
// Therefore, the "lowest" LUT can process only the LSB bit-pair of the
// operands (e.g., a[0] and b[0]).
//
// Analogously, the MSB position needs to distinguish between ULT and SLT
// (and equivalently between ULE and SLE), in addition to EQU.  Therefore,
// the "uppermost" LUT can process only the MSB bit-pair of the operands
// (e.g., a[N] and b[N]).
//
// Putting it all together, five comparison functions (ULT, ULE, SLT, SLE, and
// EQU) can be implemented in a carry chain adder of (1 + (W-2)/2 + 1) Xilinx
// LUT6_2 primitives.  Add one more logical element of some kind for the other
// five functions (UGE, UGT, SGE, SGT, and NEQ).  Therefore, the total number
// of LUT primitives simplifies to (W/2 + 1) or (W/2 + 2), depending on
// whether or not the top element is a LUT.  For example, two 32-bit operands
// require either 17 or 18 LUTs.  This all assumes the operands have an even
// number of bits, though; the Compare10 module was not designed to support
// operand widths that are odd.
//
//		IMPLEMENTATION NOTES
//
// Synthesis and implementation by Xilinx ISE tools (version 14.7) for their
// Spartan-6 FPGA (LX9) produce the lower of the two LUT counts predicted.
// Specifically, MAP implements 17 LUT6_2's (in 5 slices) for two 32-bit
// comparison operands.  Examination of the output of the Compare10 module
// (specifically, the signal "Madd_sum_xor<17>") in the technology schematic
// shows that the final XOR operation uses a dedicated "generate" element of
// the carry chain (i.e., XORCY in a CARRY4 primitive), but no LUT.
//
// Timing was characterized by use of a Top module that registers the inputs
// and outputs of the Compare10 module, with a (* KEEP_HIERARCHY = "soft" *)
// constraint on the module's instantiation.  When Place & Route (PAR) was
// performed with a timing constraint of a 3.0ns period on the clock signal,
// for the mid-range speed grade of a Spartan-6 device (i.e., -2 speed), the
// performance of the resulting implementation was reported as follows:
//
//   Minimum period:   2.666ns{1}   (Maximum frequency: 375.094MHz)
//
// In other words, this design reached the minimum period (MINPERIOD) of the
// device.  In the absence of MINPERIOD, the period would have been 2.604ns.
//
///////////////////////////////////////////////////////////////////////////////

module Compare10(
	input	[3:0]	fcn,
	input	[N:0]	a,
	input	[N:0]	b,
	output		o
);
	parameter		W = 32;	// operand bus width (i.e., word size)
	localparam		N = W-1;	// most significant bit (MSB) position of a word

	////////////////////////////////////////////////////////////////////////

	// Comparison vector
	localparam	X = W/2+1;		// top-most bit position of comparison vector
	wire	[X:0]	sum;

	// Combinational variables
	reg	[X:0]	cmp_a, cmp_b;	// operands to sum for the comparison vector
	genvar		i;					// variable to generate middle bit positions

	// Lowest operand bit-pair for comparison
	always @(*) begin
		CMP_Lower(fcn[2:0], a[0], b[0], cmp_a[0], cmp_b[0]);
	end

	// Middle bits of the comparison can be performed two pairs at a time
	generate
		for (i = 2; i <= N; i = i+2) begin : cmp_gen
			always @(*) begin
				CMP_Middle(fcn[2:0], a[i:i-1], b[i:i-1], cmp_a[i/2], cmp_b[i/2]);
			end
		end : cmp_gen
	endgenerate

	// Topmost bit-pair comparison, with sign bit processing where relevant
	always @(*) begin
		CMP_Upper(fcn[2:0], a[N], b[N], cmp_a[W/2], cmp_b[W/2]);
	end

	// One last bit position for optionally complementing the result
	always @(*) begin
		cmp_a[X] = fcn[3];			// ~x == XOR(1'b1,x); x == XOR(1'b0,x)
		cmp_b[X] = 1'b0;
	end

	// It's all over except for the arithmetic (and there's no carry-in)
	assign sum = cmp_a + cmp_b;

	// The top bit of the sum (not its carry-out) holds the final answer
	assign o = sum[X];

	//==================== Comparison Lower task section ====================//

	task CMP_Lower;
		input	[2:0]	fcn;
		input	[0:0]	a_i;
		input	[0:0]	b_i;
		output[0:0]	a_o;
		output[0:0]	b_o;
	begin : cmp_lower

		reg lt, gt, eq;

		lt = (~a_i & b_i);
		gt = (a_i & ~b_i);
		eq = (~lt & ~gt);

		// Note that signed (arithmetic) and unsigned (magnitude) comparisons
		// use the same logic except at the topmost bit (i.e., the sign bit).
		//
		case (fcn)
			`CMP10_ULT,`CMP10_SLT:	a_o =  lt;
			`CMP10_ULE,`CMP10_SLE:	a_o = ~gt;
			`CMP10_EQU:					a_o =  eq;
			// all remaining cases must be undefined at this level
			default:						a_o = 1'bX;
		endcase

		// Set B the same as A to avoid any possible dependency on carry-in.
		b_o = a_o;

	end : cmp_lower

	endtask

	//==================== Comparison Middle task section ====================//

	task CMP_Middle;
		input	[2:0]	fcn;
		input	[1:0]	a_i;
		input	[1:0]	b_i;
		output[0:0]	a_o;
		output[0:0]	b_o;
	begin : cmp_middle

		reg lt0, gt0, lt1, gt1;

		lt0 = (~a_i[0] &  b_i[0]);
		gt0 = ( a_i[0] & ~b_i[0]);
		lt1 = (~a_i[1] &  b_i[1]);
		gt1 = ( a_i[1] & ~b_i[1]);

		// Note that less-than and less-than-or-equal comparisons use the same
		// logic except at the lowest bit position (i.e., the LSB level).
		//
		case (fcn)
			`CMP10_ULT, `CMP10_ULE, `CMP10_SLT, `CMP10_SLE: begin
				// three cases: surely true, surely false, and ambiguous pass-thru
				a_o = lt1 ? 1'b1 : gt1 ? 1'b0 : lt0 ? 1'b1 : gt0 ? 1'b0 : 1'b1;
				b_o = lt1 ? 1'b1 : gt1 ? 1'b0 : lt0 ? 1'b1 : gt0 ? 1'b0 : 1'b0;
			end
			`CMP10_EQU: begin
				// the path to equality is a narrow one
				a_o = ~lt1 & ~gt1 & ~lt0 & ~gt0;
				b_o = 1'b0;
			end
			default: begin
				// all remaining cases must be undefined at this level
				a_o = 1'bX;
				b_o = 1'bX;
			end
		endcase
	end : cmp_middle

	endtask

	//==================== Comparison Upper task section ====================//

	task CMP_Upper;
		input	[2:0]	fcn;
		input	[0:0]	a_i;
		input	[0:0]	b_i;
		output[0:0]	a_o;
		output[0:0]	b_o;
	begin
		// Assume the partial magnitude comparison result is on carry-in.
		case (fcn)
			`CMP10_ULT, `CMP10_ULE: begin
				// complete the magnitude comparison already in progress
				a_o = (~a_i & b_i) ? 1'b1 : (a_i & ~b_i) ? 1'b0 : 1'b1;
				b_o = (~a_i & b_i) ? 1'b1 : (a_i & ~b_i) ? 1'b0 : 1'b0;
			end
			`CMP10_SLT, `CMP10_SLE: begin
				// use sign bits to perform an (inverted) arithmetic comparison
				a_o = (~a_i & b_i) ? 1'b0 : (a_i & ~b_i) ? 1'b1 : 1'b0;
				b_o = (~a_i & b_i) ? 1'b0 : (a_i & ~b_i) ? 1'b1 : 1'b1;
			end
			`CMP10_EQU: begin
				// equality cannot be proven at this level, but inequality can
				a_o = (~a_i & b_i) ? 1'b0 : (a_i & ~b_i) ? 1'b0 : 1'b1;
				b_o = 1'b0;
			end
			default:	begin
				//synthesis translate_off
				$stop;	// this should never happen
				//synthesis translate_on
				a_o = 1'bX;
				b_o = 1'bX;
			end
		endcase
	end

	endtask

endmodule
