I proceed this project to retrive it from dclk, and add cache, fix LOAD data hazard. 

Reconstruct from previous version. 

Places of modification: 
  1. jump instruction is from ID instead of EX. 
  2. delete dclk, so is beg/end_flag. And expand the use of staller. 
  3. make the response for branch instruction sequential, thus leads to one-clock cycle bubble (follow riscv's design). 

Progress and current problem: 
  1. Forwarding is good. Data-hazard excluding LOAD is good. But this may be fake because of the very long instruction fetching process, making data-hazard impossible to happen. 
  2. Branch and jump is good. branch instruction is decoded during ID phase, and are sequentially fed back to IF, which creates one bubble. 
  3. **The only problem is load, and the real mess lies in structural hazard in ?competing MEMORY access between IF and MEM phases.**
  If I consider above problem more carefully. 

If MEM wants RAM, but RAM is occupied, then everything stalls except IF. Otherwise, IF has just fetched a whole instruction, we stall everything except MEM. These stall signals are issued by STALLER, which determines situations by RAM_ARBITRATOR's input. 

Although MEM & IF access cause pipeline stalls, they are not counted as DATA_HAZARD and CONTROL_HAZARD. And they can be treated simultaenously. 


DEBUGGING: consider all possible hazard situations, excluding hazard caused by rdy. 
forwarding: no. LOAD MEM. 