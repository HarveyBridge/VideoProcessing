
# PlanAhead Launch Script for Post-Synthesis floorplanning, created by Project Navigator

create_project -name sobel_test -dir "C:/0152019/19lab/HL/sobel_test/planAhead_run_4" -part xc3s400anfgg400-4
set_property design_mode GateLvl [get_property srcset [current_run -impl]]
set_property edif_top_file "C:/0152019/19lab/HL/sobel_test/LDW.ngc" [ get_property srcset [ current_run ] ]
add_files -norecurse { {C:/0152019/19lab/HL/sobel_test} }
set_property target_constrs_file "C:/0152019/19lab/HL/HL_test/MT_pin.ucf" [current_fileset -constrset]
add_files [list {C:/0152019/19lab/HL/HL_test/MT_pin.ucf}] -fileset [get_property constrset [current_run]]
link_design
