PE 指的是 Process Element， 就是逻辑核心(logic core)，一个逻辑核心上可以跑一个线程。
	这个概念引出是由于现在有很多双线程的处理器(double-thread core)，
	可以一个核心运行两个完全不同的任务/线程, 一个当两个用，所以不能单单当成一个核了，就说一个核有两个PE。
	
WFI(Wait for interrupt)和WFE(Wait for event)是两个让ARM核进入low-power standby模式的指令，由ARM architecture定义，由ARM core实现。

1）共同点
	WFI和WFE的功能非常类似，以ARMv8-A为例（参考DDI0487A_d_armv8_arm.pdf的描述），主要是“将ARMv8-A PE(Processing Element, 处理单元)设置为low-power standby state”。
	我们通常所说的standby模式，保持供电，关闭clock。

2）不同点
	那它们的区别体现在哪呢？主要体现进入和退出的方式上。
	对WFI来说，执行WFI指令后，ARM core会立即进入low-power standby state，直到有WFI Wakeup events发生。
	而WFE则稍微不同，执行WFE指令后，根据Event Register（一个单bit的寄存器，每个PE一个）的状态，有两种情况：如果Event Register为1，该指令会把它清零，然后执行完成（不会standby）；如果Event Register为0，和WFI类似，进入low-power standby state，直到有WFE Wakeup events发生。
	WFI wakeup event和WFE wakeup event可以分别让Core从WFI和WFE状态唤醒，这两类Event大部分相同，如任何的IRQ中断、FIQ中断等等，一些细微的差别，可以参考“DDI0487A_d_armv8_arm.pdf“的描述。
	而最大的不同是，WFE可以被任何PE上执行的SEV指令唤醒。
	所谓的SEV指令，就是一个用来改变Event Register的指令，有两个：SEV会修改所有PE上的寄存器；SEVL，只修改本PE的寄存器值。
	
1）WFI
	WFI一般用于cpuidle。
2）WFE
	WFE的一个典型使用场景，是用在spinlock中,使用WFE的流程是：
		a）资源空闲
		b）Core1访问资源，acquire lock，获得资源
		c）Core2访问资源，此时资源不空闲，执行WFE指令，让core进入low-power state
		d）Core1释放资源，release lock，释放资源，同时执行SEV指令，唤醒Core2
		e）Core2获得资源