This is a folder for myself riscv source code compilation. 

It use a makefile to invoke riscv compilation toolchain installed in /opt/riscv/bin. The toolchain compiles .s code to both .bin and .data, of which the .bin file can be used by FPGA controller and .data can be examined directly. 

command:
1. make name.bin  # you get .bin file 
2. make name.data # you get .data file 