
# PlanAhead Launch Script for Pre-Synthesis Floorplanning, created by Project Navigator

create_project -name sobel_test -dir "C:/0152019/19lab/HL/sobel_test/planAhead_run_2" -part xc3s400anfgg400-4
set_param project.pinAheadLayout yes
set srcset [get_property srcset [current_run -impl]]
set_property target_constrs_file "C:/0152019/19lab/HL/HL_test/MT_pin.ucf" [current_fileset -constrset]
set hdlfile [add_files [list {../HL_400an/BRAM.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {sobel_test.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set_property top LDW $srcset
add_files [list {C:/0152019/19lab/HL/HL_test/MT_pin.ucf}] -fileset [get_property constrset [current_run]]
open_rtl_design -part xc3s400anfgg400-4
