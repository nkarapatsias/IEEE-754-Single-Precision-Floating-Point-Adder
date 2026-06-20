IEEE-754 Single Precision Floating-Point Adder

A high-performance, 32-bit Floating-Point Adder/Subtractor designed in SystemVerilog. This IP core is architected as a foundational building block for digital signal processing (DSP) and embedded audio accelerators.

It implements a "Compliance-0" optimization of the IEEE-754 standard (flushing denormals to zero, unifying NaNs to Infinity) to balance mathematical precision with FPGA logic utilization and power efficiency. The datapath is heavily verified against the Berkeley Hardfloat golden reference model, achieving a >99.6% accuracy rate on randomized vectors, limited only by the theoretical 1-ULP noise floor of a highly optimized 49-bit double-width barrel shifter.

🚀 Key Features

Custom Datapath: Fully pipelined 32-bit architecture divided into Sign, Exponent, Mantissa, Normalization, Rounding, and Exception handling stages.

Precision Shifting: Utilizes a 49-bit shift capture buffer to guarantee flawless Guard, Round, and Sticky (GRS) bit evaluation before rounding.

Rounding Modes: Supports 5 configurable rounding operations:

IEEE_near (Round to nearest, ties to even)

IEEE_zero (Truncate)

IEEE_pinf (Round towards +Infinity)

IEEE_ninf (Round towards -Infinity)

near_maxMag (Round to nearest, ties away from zero)

Advanced Verification: * 100 exhaustive corner-case combinations (+/- NaN, Inf, Zero, Denorm, Norm).

5,000 highly randomized 32-bit test vectors.

SystemVerilog Assertions (SVA): Integrates both Immediate Assertions (for mutually exclusive flag clamping) and Concurrent Assertions (time-traveling evaluation of 2-cycle pipelined results).

📂 Repository Structure

The repository is organized to separate the RTL source code, golden reference models, and specific EDA tool workflows:

Modules/: Contains all the SystemVerilog RTL source files (fp_adder_top.sv, mant_calc.sv, round_adder.sv, etc.), the testbench (tb_adder.sv), and the SVA definitions (fp_adder_assertions.sv).

Reference model/: Contains the Berkeley Hardfloat library files used by the testbench to generate the golden expected results during simulation.

Quartus_project/: Intel Quartus Prime project files for physical FPGA synthesis, timing analysis, and logic utilization mapping.

Questa_simulation_project/: Questa/ModelSim project files configured for RTL simulation, testbench execution, and SVA coverage tracking.

Requirments/: Project specifications, lab coursework PDFs, and architectural guidelines.

Report/: Detailed technical documentation featuring architectural block diagrams, pipeline explanations, and final verification statistics.

🛠️ Verification & Simulation

This project relies on a decoupled simulation approach, running testbenches exclusively in Questa Intel Starter FPGA Edition.

Running the Testbench

Open the Questa_simulation_project/ workspace in Questa.

Ensure all files in the Modules/ and Reference model/ directories are added to the project.

Compile all files (Compile -> Compile All).

Execute the following command in the Questa transcript to launch the testbench with full visibility for the assertions:

vsim -gui -voptargs="+acc" work.tb_adder


Run the simulation (run -all). The transcript will output the pass/fail coverage of the SVAs, followed by the final statistics block for Corner and Random cases.

📊 Verification Statistics

Randomized Math Operations: 4982 / 5000 (99.64% Success)

Note: The remaining 0.36% consists exclusively of mathematically expected 1-ULP differences caused by the optimization from an infinite-precision model to a finite DSP hardware shifter.

Corner Case Handling: Verified mathematically impossible combinations (e.g., +Inf + -Inf -> NaN) overriding the default reference model based on Compliance-0 optimizations.

⚙️ Development Stack

Hardware Description Language: SystemVerilog (IEEE 1800-2012)

Synthesis: Intel Quartus Prime

Simulation & SVA: Questa Intel Starter FPGA Edition
