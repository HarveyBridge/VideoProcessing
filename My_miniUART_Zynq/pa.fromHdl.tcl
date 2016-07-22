
# PlanAhead Launch Script for Pre-Synthesis Floorplanning, created by Project Navigator

create_project -name My_miniUART_Zynq -dir "C:/Users/BowenHsu/Documents/VideoProcessing/My_miniUART_Zynq/planAhead_run_1" -part xc7z020clg484-1
set_param project.pinAheadLayout yes
set srcset [get_property srcset [current_run -impl]]
set_property target_constrs_file "My_miniUART_Zynq.ucf" [current_fileset -constrset]
set hdlfile [add_files [list {utils.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {uart_lib.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {TxUnit_2.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {Txunit.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {RxUnit_2.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {Rxunit.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {clkUnit.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {miniUART_2.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {miniuart.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {My_miniUART_Zynq.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set_property top My_miniUART_Zynq $srcset
add_files [list {My_miniUART_Zynq.ucf}] -fileset [get_property constrset [current_run]]
open_rtl_design -part xc7z020clg484-1
