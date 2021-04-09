# To build

make cortex-arm

# To launch in qemu
```
qemu-system-arm -M mps2-an385 --kernel src/zenroom.bin -nographic -semihosting -S -gdb tcp::3333 
```
# To connect from gdb-multiarch
```
gdb-multiarch
tar rem:3333
file src/zenroom.elf
b main
c
lay src
mon system_reset
foc c
foc s
lay reg
```
