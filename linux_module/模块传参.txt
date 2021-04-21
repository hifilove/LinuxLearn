module_param(name, type, perm)
	int age = 0;
	module_param(age, int, 权限)
module_param_array(name, type, num, perm)
module_param_cb(name, ops, arg, perm)

权限：对应参数在文件节点的权限
/sys/modules/hello/paramters/age	值即为加载模块时参数传递的值
perm:	S_IRWXUGO
	S_IALLUGO
	S_IRUGO
	S_IWUGO
	S_IXUGO