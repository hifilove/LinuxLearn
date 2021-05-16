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
														
														





