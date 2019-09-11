# Compare10, a carry-chain compare unit
This is the repository for **Compare10**, a ten-function compare unit written in Verilog.  The core of the design is an adder inferred in such a way that it performs comparison operations instead of sums and differences.  As such, it targets FPGA devices with dedicated carry chain hardware.

FPGA carry primitives are generally faster than an equivalent collection of logical elements with fabric connections.  Therefore, **Compare10** can be faster and smaller than an equivalent design using inferred comparators with an output multiplexer.

Certain aspects of the design are optimized for a 6-input lookup table (LUT6) architecture.  Specifically, the design target was a Xilinx Spartan-6 (LX9), and the tool environment was ISE Project Navigator v14.7.  I expect this design would work the same on other Xilinx LUT6 devices, including newer ones as long as Vivado infers the **Compare10** adder the same way as ISE.  The design would probably not work well on devices with 4-input LUTs, such as the Spartan-3.  I have no idea how it would fare on other companies' devices.

More information about the overall design and implementation is available in a comment block near the top of the `Compare.v` file.

## Files
Name | Purpose
---- | -------
Compare.v    | Source file for the **Compare10** module.
Compare10.vh | Header file to define 10 comparison functions (CMP10_\*).
cmp_tb.v     | Simulation test bench for the **Compare10** module.
Top.v        | Example top module instantiating **Compare10**.

To use **Compare10** in a project, you'll need the `Compare.v` file at a minimum, and probably `Compare10.vh` too.  The `cmp_tb.v` file can be used for simulation and testing.  The `Top.v` file isn't required, but I used it to help evaluate the implementation quality.

## Interface
```Verilog
module Compare10(
    input [3:0] fcn,     // comparison function (see Compare10.vh)
    input [N:0] a,       // first operand to be compared
    input [N:0] b,       // second operand (e.g., a < b)
    output      o        // True or False comparison result
);
parameter       W = 32;  // operand bus width (i.e., word size)
localparam      N = W-1; // most significant bit (MSB) position of a word
```
