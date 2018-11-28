# ACM 2018 CPU project for System 1

# 项目进行
我希望做出一个可以跑在板子上的cpu，那么我应当直到板子上的ram是怎么工作的，因此如果我不是基于板子上的运行方式设计的话，那么即使仿真过了，也毫无用处。

# 项目结构
所有的src文件都在src文件夹里，把它们放入vivado工程，然后我们就可以program device。然后就放着别管，之后运行一些control脚本，就可以将数据在电脑和fpga之间传输了。

# RAM
简而言之，我们可以读数据、写数据，但是我们只能一次操作8位！
input: clk_in(system clock), en_in(chip enable), r_nw_in(read/write select), a_in(memory address), d_in(data input), d_out(data output). 
在riscv_top当中声明了两个组件，一个是自己写的cpu，另一个是ram。而其中ram.v当中又是引用了common/block_ram.v当中写的single_port_ram_sync module，并且这个module在生成的时候读了"test.data"文件中的数据作为memory的初始化文件(for simulation)。

I think simulation may be persuasive, since ram is especially talored to simulation. 

# plan
什么都不管了，直接用ram进行simulation，不论能不能上板子，因为我不知道如何使用板子进行incremental analysis。
I aim to change the clock cycle. 
The whole purpose of cpu_pause is that, you have to catch up what is left over when you resume. I don't care about any other things. How could I do that? 
I choose to synchronize my pause, which means I check 'pause' signal only during the posedge clk. This means that inst-fetching has to hold back whenever it receives 'pause' signal. And it can get the instruction the next time, you know. 
OH NO! If I roll back, the next time, it will cause a bubble. So IF_ID just freeze, and IF step forward. 
OH NO! It's efficient though, but is difficult to understand. 
