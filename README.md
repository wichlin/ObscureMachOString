# ObscureMachOString
1、指定字符串混淆MachO格式文件、lib、framework、app。
2、代码实现是基于MachOView的开源代码修改的，增加了一个SaveMachO类，用于处理代码混淆。
mixStringInfo函数字义了要替换的字符串和新字符串，注意：新旧字符串的长度要一致，替换的范围包括：类名、函数名、常量字符串。
3、MachOView源码地址：https://github.com/gdbinit/MachOView
