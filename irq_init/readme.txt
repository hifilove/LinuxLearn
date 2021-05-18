arch\arm\kernel\entry-armv.S

.L__vectors_start:
    W(b)    vector_rst
    W(b)    vector_und
    W(ldr)  pc, .L__vectors_start + 0x1000
    W(b)    vector_pabt
    W(b)    vector_dabt
    W(b)    vector_addrexcptn
    W(b)    vector_irq <----发生中断时执行这条指令
    W(b)    vector_fiq