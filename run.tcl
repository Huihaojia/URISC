set LOG_PATH "./report"
set DESIGN_NAME "URISC"

set target_library { /login_home/huihaojia/Codes/environment_verify/library/typical.db }
set link_library   { * /login_home/huihaojia/Codes/environment_verify/library/typical.db }
set symbol_library { /login_home/huihaojia/Codes/environment_verify/library/tsmc18.sdb }

read_file -format verilog {/login_home/huihaojia/Codes/URISC_final/src.v}

current_design $DESIGN_NAME

set_operating_conditions -library typical typical

set all_in_ex_clk [remove_from_collection [all_inputs] [get_ports clk]]
set all_in_ex_clk_rstn [remove_from_collection $all_in_ex_clk [get_ports reset]]
set_driving_cell -lib_cell INVX12 -library typical $all_in_ex_clk_rstn

set_fanout_load 2 [all_outputs]

create_clock -name "clock" -period 5 -waveform { 0.000 2.5  }  { clk  }
set_dont_touch_network  [ find clock clock ]

set_input_delay -max 1 -clock clock $all_in_ex_clk_rstn
set_output_delay -max 1 -clock clock [all_outputs]

set case_analysis_with_logic_constants true
set case_analysis_sequential_propagation never
set auto_wire_load_selection
set wire_load_mode top

compile -exact_map

uplevel #0 { report_timing -path full -delay max -nworst 1 -max_paths 1 -significant_digits 2 -sort_by group }
uplevel #0 { report_area -nosplit }

write -hierarchy -format ddc
write -hierarchy -format verilog -output /login_home/huihaojia/Codes/URISC_final/output/$DESIGN_NAME.v
write_sdf /login_home/huihaojia/Codes/URISC_final/output/$DESIGN_NAME.sdf
write_sdc /login_home/huihaojia/Codes/URISC_final/output/$DESIGN_NAME.sdc

#################################################################################
# Generate Final Reports
#################################################################################
redirect  [file join  checkTiming.rpt] { check_timing }

   redirect  [file join   reportConstraint_maxDelay.rpt] {  
    echo "Info : report_constraint" 
    report_constraint  -significant_digits 3 -max_delay
    echo "" 
    echo "Info : report_constraint -all_violators" 
    report_constraint -all_violators -max_delay -significant_digits 3
    echo "" 
    echo "Info : report_constraint -max_delay -verboes" 
    report_constraint -max_delay -verbose -significant_digits 3
  }  

report_area -hierarchy    		> ${LOG_PATH}/${DESIGN_NAME}-area.log
report_timing -nworst 30        > ${LOG_PATH}/${DESIGN_NAME}-timing.log
report_timing -max 30           > ${LOG_PATH}/${DESIGN_NAME}-timing_max.log
report_timing -nets -max 30     > ${LOG_PATH}/${DESIGN_NAME}-timing_net_max.log
report_hierarchy                > ${LOG_PATH}/${DESIGN_NAME}-hierarchy.log
report_power -hier              > ${LOG_PATH}/${DESIGN_NAME}-power.log

quit
