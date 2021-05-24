i2c-dev.c分析

内核中有一个文件i2c-dev.c，这个文件的会在在所有i2c-adapter注册后，被当作i2c-dev.ko一个模块插入到内核中，
	当插入之后回去调用他的module_init(i2c_dev_init)函，代码接续如下：
	i2c_dev_init
		register_chrdev_region(MKDEV(I2C_MAJOR, 0), I2C_MINORS, "i2c") // 占用一块主设备号为I2C_MAJOR I2C_MINORS个数量设备号（由主设备号和子设备号组成）
		class_create(THIS_MODULE, "i2c-dev") // 创建一个class用于创建设备节点
		i2c_for_each_dev(NULL, i2cdev_attach_adapter) // 便利每个一i2c-adapter然后执行i2cdev_attach_adapter这个函数
			i2cdev_attach_adapter
				cdev_init(&i2c_dev->cdev, &i2cdev_fops) // 初始化一个字符设备，并将这个设备的操作函数赋值为i2cdev_fops，
														也就是所有的adapter都会创建一个字符设备用i2cdev_fops里面的操作面向用户态
					i2cdev_fops.open = i2cdev_open
											i2c_get_adapter(minor) // 获得这个设备所对应的adapter
											kzalloc(sizeof(*client), GFP_KERNEL) // 创建一个i2c-client用于后面的传输使用
											client->adapter = adap
											file->private_data = client // 私有数据的保存
					i2cdev_fops.unlocked_ioctl = i2cdev_ioctl
													struct i2c_client *client = file->private_data
													case I2C_SLAVE:
													case I2C_SLAVE_FORCE:
														client->addr = arg // 设置client的地址
													case I2C_RDWR: {
														copy_from_user
														return i2cdev_ioctl_rdwr
																	i2c_transfer
																		__i2c_transfer
																			adap->algo->master_xfer // 调用了每个这个adapter中的algo中的master_xfer发送msgs
													case I2C_SMBUS: {
														copy_from_user
														return i2cdev_ioctl_smbus
																	i2c_smbus_xfer
																		__i2c_smbus_xfer
																			xfer_func = adapter->algo->smbus_xfe
																				xfer_func // 调用了每个这个adapter中的algo中的smbus_xfe发送msgs
													}
														client->addr = arg;
				i2c_dev->dev.devt = MKDEV(I2C_MAJOR, adap->nr)) // 将这个字符设备的设备号修改为主设备号为I2C_MAJOR，子设备号为adapter_number
				cdev_device_add(&i2c_dev->cdev, &i2c_dev->dev)
					cdev_add(cdev, dev->devt, 1) // 将这个设备添加进内核