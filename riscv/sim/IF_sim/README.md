# This test tests whether instruction can be fetched using delayed clocks. 
In this set of simulation, I finally get the idea of how the whole system fetch instruction from ram. 

1. Every digital system has to have reset signal, because synthesis doesn't allow 'initial'. 
2. synthesis doesn't allow edge-trigger and level-trigger going together. 
3. !!! Don't write ram !!! Always read !!! 
4. Formalize inst-fetching as a FSM. 

// this is just fairly natural, cause control and communication obviously needs time! 

- consider the process of reading

  1. #(0) addr <- 0; // dclk posedge -- reading/ new address is coming
  2. #(1) addr <- 1; 
  3. #(2) addr <- 2; // read $(0)
  4. #(3) addr <- 3; // read $(1)
  5. #(4) addr <- 4; // read $(2)
  6. #(5) // wire $(3); dclk posedge -- reading/ new address is coming

- consider writing a byte. 

  1. #(0) din <- (data0); we <- `Enable; addr <- 0; // prepare to write. 
  2. #(1) din <- (data1); addr <- 1; // $(0) is in. 
  3. #(2) din <- (data2); addr <- 2; // $(1) is in. 
  4. #(3) din <- (data3); addr <- 3; // $(2) is in. 
  5. #(4) din <- Z; we = `Disable; addr = ???; // $(3) is in. 

# Conclusion
Clock should be set in a period of 5. 

# if-sim code explanation. 
I write wrong dclk period, and misunderstood ram's rw signal. I have to rewrite many things in the original project. The simulation of code reside in this folder is awefully wrong. The initial data is unreadable because I write Z into ram. 

# About timing issue 
The backbone of the digital system should lie on dclk. Only operations concerning instruction-fetching should I work under clk. It can be triggered by FSM. 

# About rw enable signal 
These are delivered to negotiator instead of going to ram directly, because we need to avoid casual writing. If no writing requests, IF will read forever. Thus no need for IF's negotiator signal. 

# About test on board 
I can Immediately test on board that whether FPGA has fetched target address. This can be tested by using LED to indicate the bytes in mem. And let IF module to fetch the same address all the time. **I put all the simulation related file in 'FPGA_test' folder.**