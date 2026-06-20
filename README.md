# IEEE-754 Single Precision Floating-Point Adder

A high-performance, 32-bit Floating-Point Adder/Subtractor designed in SystemVerilog. This IP core is architected as a foundational building block for digital signal processing (DSP) and embedded audio accelerators. 

It implements a "Compliance-0" optimization of the IEEE-754 standard (flushing denormals to zero, unifying NaNs to Infinity) to balance mathematical precision with FPGA logic utilization and power efficiency. The datapath is heavily verified against the Berkeley Hardfloat golden reference model, achieving a >99.6% accuracy rate on randomized vectors, limited only by the theoretical 1-ULP noise floor of a highly optimized 49-bit double-width barrel shifter.

## 🚀 Key Features

* **Custom Datapath:** Fully pipelined 32-bit architecture divided into Sign, Exponent, Mantissa, Normalization, Rounding, and Exception handling stages.
* **Precision Shifting:** Utilizes a 49-bit shift capture buffer to guarantee flawless Guard, Round, and Sticky (GRS) bit evaluation before rounding.
* **Rounding Modes:** Supports 5 configurable rounding operations:
  * `IEEE_near` (Round to nearest, ties to even)
  * `IEEE_zero` (Truncate)
  * `IEEE_pinf` (Round towards +Infinity)
  * `IEEE_ninf` (Round towards -Infinity)
  * `near_maxMag` (Round to nearest, ties away from zero)
* **Advanced Verification:** * 100 exhaustive corner-case combinations (+/- NaN, Inf, Zero, Denorm, Norm).
  * 5,000 highly randomized 32-bit test vectors.
* **SystemVerilog Assertions (SVA):** Integrates both Immediate Assertions (for mutually exclusive flag clamping) and Concurrent Assertions (time-traveling evaluation of 2-cycle pipelined results).

## 📂 Repository Structure

The repository is organized to cleanly separate the RTL source code, golden reference models, and specific EDA tool workflows.

* 📦 **IEEE-754-FP-Adder**
  * 📁 **Modules/** — Core SystemVerilog RTL and Verification
    * 📄 `fp_adder_top.sv` — Top-level module wrapper
    * 📄 `mant_calc.sv` — Mantissa alignment & 49-bit shift logic
    * 📄 `round_adder.sv` — GRS bit evaluation & rounding
    * 📄 `tb_adder.sv` — Master testbench & pipeline sync
    * 📄 `fp_adder_assertions.sv` — Immediate & concurrent SVAs
  * 📁 **Reference model/** — Berkeley Hardfloat library files
  * 📁 **Quartus_project/** — Intel Quartus Prime synthesis & physical mapping
  * 📁 **Questa_simulation_project/** — Questa/ModelSim simulation & coverage workspace
  * 📁 **Requirments/** — Architectural specs and lab guidelines
  * 📁 **Report/** — Technical documentation and block diagrams

## 🛠️ Verification & Simulation

This project relies on a decoupled simulation approach, running testbenches exclusively in Questa Intel Starter FPGA Edition.

### Running the Testbench

1. Open the `Questa_simulation_project/` workspace in Questa.
2. Ensure all files in the `Modules/` and `Reference model/` directories are added to the project.
3. Compile all files (*Compile -> Compile All*).
4. Execute the following command in the Questa transcript to launch the testbench with full visibility for the assertions:
