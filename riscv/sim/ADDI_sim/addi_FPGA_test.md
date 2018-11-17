In this test, we construct the full five-stage pipeline architecture. But it only support a special kind of 'DISPLAY' instruction, which is a variation of existing instruction. The purpose of this instruction is to display ram data and register word in order to debug.

This type of instruction encounters a problem that, it has to compete with IF for the opportunity to use ram. 

DISPLAY register: ADDI 0010011 rd
![avatar](./ADDI.png)

DISPLAY ram: 
![avatar](./LB.png)

This test repeatedly read instruction at 0. To monitor registerfile data, we add a dbg port in registerfile for debug purposes. 
'full_cpu.v' is a master module that connects all components of CPU. 