In this set of simulation, we deal with JUMP instructions. 

![avatar](./jp1.png)

![avatar](./jp2.png)

JAL do two things:
1.  Add sign-extended immdiate to the pc. 
2.  Store (pc+4) into target register rd. 

Self analysis: in ID phase, we can change the PC register, thus no control hazard occurs in 'UNCONDITIONAL JUMPS'. The left dst is calculated in EX phase, and the arithmetic result is well regulated by forwarding. 

![avatar](./jp3.png)

![avatar](./jp4.png)

![avatar](./inst_format.png)

output aluop to IF, together with the target jumping address. 

All Jump and Branch instrucitons feedback at EX phase. Ports are also defined in ID phase, for further functional design improvement. 

Question may arise when we continue stl_IFID_o, because we suppose everything between instruction-fetching and EX be flushed. When we BUBBLE IDEX, we are actually preventing the previous instruction going from IFID through ID to IDEX. The second wrong instrucion hasn't been fetched yet. Because FLUSH signals are combinational, we can control IF module at the beginning of dclk, thus fetching a correct second instruction, making IFID's work meaningful after fetching a 'jumped, valid instruction'. 
