/*****************************************************************************
Copyright (c) 2019, John R. Peace
All rights reserved.

This file is part of the "carry-chain-compare-unit" project at:
https://github.com/evil-mad-engineer/carry-chain-compare-unit

Licensed under the BSD-3-Clause license.  For more information,
see the LICENSE file in the project repository at the URL above.
*****************************************************************************/

`ifndef _COMPARE10_
`define _COMPARE10_

///////////////////////////////////////////////////////////////////////////////
// Create Date:	13:23:04 09/09/2019
// Module Name:	Compare10.vh
// Design Name:	Compare10
// Project Name:	cmp
// Target Device:	Xilinx Spartan-6
// Tool versions:	Xilinx ISE 14.7
// Description:	`include' file for Compare10, a ten-function compare unit
///////////////////////////////////////////////////////////////////////////////

// Comparison unit function codes; order is critical to promote bit-banging
//
`define	CMP10_ULT	4'h0	// bit 0 distinguishes ULE/ULT, UGT/UGE, etc.
`define	CMP10_ULE	4'h1
`define	CMP10_SLT	4'h2	// bit 1 distinguishes signed from unsigned
`define	CMP10_SLE	4'h3
`define	CMP10_EQU	4'h4	// bit 2 distinguishes EQU/NEQ from all others
//		4'h5 - 4'h7 unused
`define	CMP10_UGE	4'h8	// bit 3 indicates complement (e.g., UGE is ~ULT)
`define	CMP10_UGT	4'h9
`define	CMP10_SGE	4'hA
`define	CMP10_SGT	4'hB
`define	CMP10_NEQ	4'hC
//		4'hD - 4'hF unused

`endif // _COMPARE10_
