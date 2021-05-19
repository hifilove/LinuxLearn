head.S
a. __lookup_processor_type : 使用汇编指令读取CPU ID, 根据该ID找到对应的proc_info_list结构体(里面含有这类CPU的初始化函数、信息)

b. __vet_atags : 判断是否存在可用的ATAGS或DTB

c. __create_page_tables : 创建页表, 即创建虚拟地址和物理地址的映射关系

d. __enable_mmu : 使能MMU, 以后就要使用虚拟地址了

e. __mmap_switched : 上述函数里将会调用__mmap_switched

f. 把bootloader传入的r2参数, 保存到变量__atags_pointer中

g. 调用C函数start_kernel

init/main.c
start_kernel // init/main.c
    setup_arch(&command_line);  // arch/arm/kernel/setup.c
        mdesc = setup_machine_fdt(__atags_pointer);  // arch/arm/kernel/devtree.c
                    early_init_dt_verify(phys_to_virt(dt_phys)  // 判断是否有效的dtb, drivers/of/ftd.c
                                    initial_boot_params = params;
                    mdesc = of_flat_dt_match_machine(mdesc_best, arch_get_next_mach);  // 找到最匹配的machine_desc, drivers/of/ftd.c
                                    while ((data = get_next_compat(&compat))) {
                                        score = of_flat_dt_match(dt_root, compat);
                                        if (score > 0 && score < best_score) {
                                            best_data = data;
                                            best_score = score;
                                        }
                                    }


                    early_init_dt_scan_nodes();      // drivers/of/ftd.c
                        /* Retrieve various information from the /chosen node */
                        of_scan_flat_dt(early_init_dt_scan_chosen, boot_command_line);

                        /* Initialize {size,address}-cells info */
                        of_scan_flat_dt(early_init_dt_scan_root, NULL);

                        /* Setup memory, calling early_init_dt_add_memory_arch */
                        of_scan_flat_dt(early_init_dt_scan_memory, NULL);


        arm_memblock_init(mdesc);   // arch/arm/kernel/setup.c
            early_init_fdt_reserve_self();
                    /* Reserve the dtb region */
                    // 把DTB所占区域保留下来, 即调用: memblock_reserve
                    early_init_dt_reserve_memory_arch(__pa(initial_boot_params),
                                      fdt_totalsize(initial_boot_params),
                                      0);           
            early_init_fdt_scan_reserved_mem();  // 根据dtb中的memreserve信息, 调用memblock_reserve
            

        unflatten_device_tree();    // arch/arm/kernel/setup.c
            __unflatten_device_tree(initial_boot_params, NULL, &of_root,
                        early_init_dt_alloc_memory_arch, false);            // drivers/of/fdt.c
                
                /* First pass, scan for size */
                size = unflatten_dt_nodes(blob, NULL, dad, NULL);
                
                /* Allocate memory for the expanded device tree */
                mem = dt_alloc(size + 4, __alignof__(struct device_node));
                
                /* Second pass, do actual unflattening */
                unflatten_dt_nodes(blob, mem, dad, mynodes);
                    populate_node
                        np = unflatten_dt_alloc(mem, sizeof(struct device_node) + allocl,
                                    __alignof__(struct device_node));
                        
                        np->full_name = fn = ((char *)np) + sizeof(*np);
                        
                        populate_properties
                                pp = unflatten_dt_alloc(mem, sizeof(struct property),
                                            __alignof__(struct property));
                            
                                pp->name   = (char *)pname;
                                pp->length = sz;
                                pp->value  = (__be32 *)val;
        machine_desc = mdesc;




    init_IRQ();
        if (IS_ENABLED(CONFIG_OF) && !machine_desc->init_irq)
            irqchip_init();   // 一般使用它
				irqchip_init // drivers/irqchip/irqchip.c
					of_irq_init(__irqchip_of_table);  // 对设备树文件中每一个中断控制器节点, 调用对应的处理函数
						为每一个符合的"interrupt-controller"节点,
						分配一个of_intc_desc结构体, desc->irq_init_cb = match->data; // = IRQCHIP_DECLARE中传入的函数
						并调用处理函数
						
						(先调用root irq controller对应的函数, 再调用子控制器的函数, 再调用更下一级控制器的函数...)
						for_each_matching_node_and_match(np, matches, &match) { //找出节点的compteb属性和desc一样的节点
								if (!of_property_read_bool(np, "interrupt-controller") // 如果是中断控制器
									continue;

								
								desc = kzalloc(sizeof(*desc), GFP_KERNEL);
								desc->irq_init_cb = match->data; // 把初始化放在irq_init_cb中
								list_add_tail(&desc->list, &intc_desc_list);
							}

							while (!list_empty(&intc_desc_list)) {
								
								list_for_each_entry_safe(desc, temp_desc, &intc_desc_list, list) {
									ret = desc->irq_init_cb(desc->dev, desc->interrupt_parent); // 调用irq_init_cb
								}
							}

        else
            machine_desc->init_irq();




    rest_init();
        pid = kernel_thread(kernel_init, NULL, CLONE_FS);
                    kernel_init
                        kernel_init_freeable();
                            do_basic_setup();
                                do_initcalls();
                                    for (level = 0; level < ARRAY_SIZE(initcall_levels) - 1; level++)
                                        do_initcall_level(level);  // 比如 do_initcall_level(3)
                                                                               for (fn = initcall_levels[3]; fn < initcall_levels[3+1]; fn++)
                                                                                    do_one_initcall(initcall_from_entry(fn));  // 就是调用"arch_initcall_sync(fn)"中定义的fn函数
											of_platform_default_populate_init
												of_platform_default_populate(NULL, NULL, NULL);
													of_platform_populate(NULL, of_default_bus_match_table, NULL, NULL)
														for_each_child_of_node(root, child) {
															rc = of_platform_bus_create(child, matches, lookup, parent, true);  // 调用过程看下面
																	dev = of_platform_device_create_pdata(bus, bus_id, platform_data, parent);  // 生成bus节点的platform_device结构体
																	if (!dev || !of_match_node(matches, bus))  // 如果bus节点的compatile属性不吻合matches成表, 就不处理它的子节点
																		return 0;

																	for_each_child_of_node(bus, child) {    // 取出每一个子节点
																		pr_debug("   create child: %pOF\n", child);
																		rc = of_platform_bus_create(child, matches, lookup, &dev->dev, strict);   // 处理它的子节点, of_platform_bus_create是一个递归调用
																			// 遇到pinctrl控制器
																			samsung_pinctrl_probe  // drivers/pinctrl/samsung/pinctrl-samsung.c
																				最终会调用到 s3c24xx_eint_init // drivers/pinctrl/samsung/pinctrl-s3c24xx.c
																				
																					// eint0,1,2,3的处理函数在处理root irq controller时已经设置; 
																					// 设置eint4_7, eint8_23的处理函数(它们是分发函数)
																					for (i = 0; i < NUM_EINT_IRQ; ++i) {
																						unsigned int irq;

																						if (handlers[i]) /* add by weidongshan@qq.com, 不再设置eint0,1,2,3的处理函数 */
																						{
																							irq = irq_of_parse_and_map(eint_np, i);
																							if (!irq) {
																								dev_err(dev, "failed to get wakeup EINT IRQ %d\n", i);
																								return -ENXIO;
																							}

																							eint_data->parents[i] = irq;
																							irq_set_chained_handler_and_data(irq, handlers[i], eint_data);
																						}
																					}

																					// 为GPF、GPG设置irq_domain
																					for (i = 0; i < d->nr_banks; ++i, ++bank) {
																					
																						ops = (bank->eint_offset == 0) ? &s3c24xx_gpf_irq_ops
																										   : &s3c24xx_gpg_irq_ops;

																						bank->irq_domain = irq_domain_add_linear(bank->of_node, bank->nr_pins, ops, ddata);
																					}
																			
																			
																			// 遇到有人使用某个中断控制器的domain的时候
																			of_device_alloc (drivers/of/platform.c)
																				dev = platform_device_alloc("", PLATFORM_DEVID_NONE);  // 分配 platform_device
																				
																				num_irq = of_irq_count(np);  // 计算中断数
																				
																				of_irq_to_resource_table(np, res, num_irq) // drivers/of/irq.c, 根据设备节点中的中断信息, 构造中断资源
																					of_irq_to_resource
																						int irq = of_irq_get(dev, index);  // 获得virq, 中断号
																										rc = of_irq_parse_one(dev, index, &oirq); // drivers/of/irq.c, 解析设备树中的中断信息, 保存在of_phandle_args结构体中
																										
																										domain = irq_find_host(oirq.np);   // 查找irq_domain, 每一个中断控制器都对应一个irq_domain
																										
																										irq_create_of_mapping(&oirq);             // kernel/irq/irqdomain.c, 创建virq和中断信息的映射
																											irq_create_fwspec_mapping(&fwspec);
																												irq_create_fwspec_mapping(&fwspec);
																													irq_domain_translate(domain, fwspec, &hwirq, &type) // 调用irq_domain->ops->xlate, 把设备节点里的中断信息解析为hwirq, type
																													
																													virq = irq_find_mapping(domain, hwirq); // 看看这个hwirq是否已经映射, 如果virq非0就直接返回
																													
																													virq = irq_create_mapping(domain, hwirq); // 否则创建映射
																																virq = irq_domain_alloc_descs(-1, 1, hwirq, of_node_to_nid(of_node), NULL);  // 返回未占用的virq
																																
																																irq_domain_associate(domain, virq, hwirq) // 调用irq_domain->ops->map(domain, virq, hwirq), 做必要的硬件设置
																		
																		
																			// 驱动程序从platform_device的"中断资源"取出中断号, 就可以request_irq了
																			
																			
																		if (rc) {
																			of_node_put(child);
																			break;
																		}
																	}
																dev = of_device_alloc(np, bus_id, parent);   // 根据device_node节点的属性设置platform_device的resource
															if (rc) {
																of_node_put(child);
																break;
															}
														}
														
														





