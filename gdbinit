source ~/.gdb-print.py
set auto-load safe-path /
set print pretty on
set print array on
set history filename ~/.gdb_history
set history save
set disassembly-flavor intel
set pagination off
set width 0
set height 0
set output-radix 16
set confirm off

# breakpoints: break, clear, enable, disable, tbreak, awatch
# step: stepi,stepo, finish
# search func/var: info functions/variables <regexp>
# mem: diassemble $addr, x/cmz $addr, set $addr
# set architecture i386:x86-64 / i386
