This FPGA test is about implementing load and store instruction.

Execute a single store or load instruction of one byte repeatedly, showing the results on FPGA leds. 
![avatar](./ldst.png)

The main difficulty is that our ram is one-way accessible. We need to stall IF module's instruction fetching in order to do memory accessing. 

The idea of MEM module is basically the same as IF module. 
![avatar](./ldst_explain.png)

In this experiment, implement LH first. 

MEM_SIM: In this experiment, we connect MEM with RAM_ARBITRATOR which further provides control signals to RAM. We first use STORE instruction to STORE a particular kind of data into $(0) of RAM. Then use the corresponding instruction to read the same amount of data. Simulation shows that this is valid. 

Then, I'll make STORE instruction flow through the entire pipeline, thus applying changes to the whole architecture. 