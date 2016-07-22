
# PlanAhead Launch Script for Post-Synthesis floorplanning, created by Project Navigator

create_project -name My_miniUART_Zynq -dir "C:/Users/BowenHsu/Documents/VideoProcessing/My_miniUART_Zynq/planAhead_run_2" -part xc7z020clg484-1
set_property design_mode GateLvl [get_property srcset [current_run -impl]]
set_property edif_top_file "C:/Users/BowenHsu/Documents/VideoProcessing/My_miniUART_Zynq/My_miniUART_Zynq.ngc" [ get_property srcset [ current_run ] ]
add_files -norecurse { {C:/Users/BowenHsu/Documents/VideoProcessing/My_miniUART_Zynq} }
set_property target_constrs_file "My_miniUART_Zynq.ucf" [current_fileset -constrset]
add_files [list {My_miniUART_Zynq.ucf}] -fileset [get_property constrset [current_run]]
link_design
