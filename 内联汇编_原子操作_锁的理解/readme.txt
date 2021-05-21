联汇编语法：
	① asm 
		也可以写作“__asm__”，表示这是一段内联汇编。
	② asm-qualifiers 
		有 3 个取值：volatile、inline、goto。
		volatile 的意思是易变的、不稳定的，用来告诉编译器不要随便优化这段代码，否则可能出问题。比
		如汇编指令“mov r0, r0”，它把 r0 的值复制到 r0，并没有实际做什么事情，你的本意可能是用这条指令
		来延时。编译器看到这指令后，可能就把它去掉了。加上 volatile 的话，编译器就不会擅自优化。
		其他 2 个取值我们不关心，也比较难以理解，不讲。
	③ AssemblerTemplate 
		汇编指令，用双引号包含起来，每条指令用“\n”分开，比如：
		“mov %0, %1\n”
		“add %0, %1, %2\n”
	④ OutputOperands 
		输出操作数，内联汇编执行时，输出的结果保存在哪里。
		格式如下，当有多个变量时，用逗号隔开：
		[ [asmSymbolicName] ] constraint (cvariablename)
			asmSymbolicName 是符号名，随便取，也可以不写。
			constraint 表示约束，有如下常用取值：
			constraint 描述
				m memory operand，表示要传入有效的地址，只要 CPU 能支持该地址，就可以传入
				r register operand，寄存器操作数，使用寄存器来保存这些操作数
				i immediate integer operand，表示可以传入一个立即数
			constraint 前还可以加上一些修饰字符，比如“=r”、“+r”、“=&r”，含义如下：
			constraint Modifier Characters 描述
				= 表示内联汇编会修改这个操作数，即：写
				+ 这个操作数即被读，也被写
				& 它是一个 earlyclobber 操作数
			cvariablename：C 语言的变量名。
		示例 1 如下：
		[result] "=r" (sum)
		它的意思是汇编代码中会通过某个寄存器把结果写入 sum 变量。在汇编代码中可以使用“%[result]”
		来引用它。
		示例 2 如下：
		"=r" (sum)
		在汇编代码中可以使用“%0”、“%1”等来引用它，这些数值怎么确定后面再说。
	⑤ InputOperands 
		输入操作数，内联汇编执行前，输入的数据保存在哪里。
		格式如下，当有多个变量时，用逗号隔开：
		[ [asmSymbolicName] ] constraint (cexpression)
			asmSymbolicName 是符号名，随便取，也可以不写。
			constraint 表示约束，参考上一小节，跟 OutputOperands 类似。
			cexpression：C 语言的表达式。
		示例 1 如下：
		[a_val]"r"(a), [b_val]"r"(b)
		示例 2 如下：
		"r"(a), "r"(b)
		它的意思变量 a、b 的值会放入某些寄存器。在汇编代码中可以使用%0、%1 等使用它们，这些数值后面
		再说。
	⑥ Clobbers 
		在汇编代码中，对于“OutputOperands”所涉及的寄存器、内存，肯定是做了修改。但是汇编代码中，
		也许要修改的寄存器、内存会更多。比如在计算过程中可能要用到 r3 保存临时结果，我们必须在“Clobbers”
		中声明 r3 会被修改。
		下面是一个例子：
		: "r0", "r1", "r2", "r3", "r4", "r5", "memory"
		我们常用的是有“cc”、“memory”，意义如下：
		Clobbers 描述
			cc 表示汇编代码会修改“flags register”
			memory 表示汇编代码中，除了“InputOperands”和“OutputOperands”中指定的之外，还会会读、写更多的内存


原子操作：
	在up中(< armv6)：
		static inline void atomic_##op(int i, atomic_t *v)
		{						
			raw_local_irq_save(flags); // 关中断，因为在up中没有其他的核来竞争这个资源，所以只需要考虑当前的核中的资源竞争者，
										而在内核态有两个方法可以被调度出去 1 其他的进程来抢占(preempt_disable/local_irq_disable) 2 中断(local_irq_disable)，
										因为local_irq_disable即可以关闭抢占又可以关闭中断，所以此处选择关闭中断的方法
			v->counter c_op i; // 操作原子量
			raw_local_irq_restore(flags); // 开中断
		}
	在smp中(> armv6)：而在smp中可以用ldrex给要操作的变量加上独占式访问，一但原子操作被打断，就会重新进行读改写的操作
		static inline void atomic_##op(int i, atomic_t *v)			\
		{									\
			unsigned long tmp;						\
			int result;							\
											\
			prefetchw(&v->counter);						\
			__asm__ __volatile__("@ atomic_" #op "\n"			\
		"1:	ldrex	%0, [%3]\n"						\
		"	" #asm_op "	%0, %0, %4\n"					\
		"	strex	%1, %0, [%3]\n"						\
		"	teq	%1, #0\n"						\
		"	bne	1b"							\
			: "=&r" (result), "=&r" (tmp), "+Qo" (v->counter)		\
			: "r" (&v->counter), "Ir" (i)					\
			: "cc");							\
		}	
		
		
	函数名 						作用
	atomic_read(v) 				读出原子变量的值，即 v->counter
	atomic_set(v,i) 			设置原子变量的值，即 v->counter = i
	atomic_inc(v) 				v->counter++
	atomic_dec(v) 				v->counter--
	atomic_add(i,v)				v->counter += i
	atomic_sub(i,v) 			v->counter -= i
	atomic_inc_and_test(v) 		先加 1，再判断新值是否等于 0；等于 0 的话，返回值为 1
	atomic_dec_and_test(v) 		先减 1，再判断新值是否等于 0；等于 0 的话，返回值为 1
	
	
	函数名 						作用
	set_bit(nr,p) 				设置(*p)的 bit nr 为 1
	clear_bit(nr,p) 			清除(*p)的 bit nr 为 0
	change_bit(nr,p) 			改变(*p)的 bit nr，从 1 变为 0，或是从 0 变为 1
	test_and_set_bit(nr,p) 		设置(*p)的 bit nr 为 1，返回该位的老值
	test_and_clear_bit(nr,p) 	清除(*p)的 bit nr 为 0，返回该位的老值
	test_and_change_bit(nr,p) 	改变(*p)的 bit nr，从 1 变为 0，或是从 0 变为 1；返回该位的老值
	
	
	

	
	


	

