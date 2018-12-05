I proceed this project to retrive it from dclk, and add cache, fix LOAD data hazard. 

Reconstruct from previous version. 

Places of modification: 
  1. jump instruction is from ID instead of EX. 
  2. delete dclk, so is beg/end_flag. And expand the use of staller. 
  3. make the response for branch instruction sequential, thus leads to one-clock cycle bubble (follow riscv's design). 