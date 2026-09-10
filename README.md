# Digital IC
个人学习数字ic的学习资料仓库

路科验证V0课程练习:

使用vcs查看波形

```shell
vcs -full64  -debug_access+all -sverilog -timescale=1ns/1ps  router.v tb03m.sv  -top tb
```

```shell
./simv -gui &
```


使用Questa Sim 查看仿真

```shell
vlog -sv packet.sv
```

```shell
vsim work.tb3 -voptargs=+acc -classdebug
```

