set tests {
  auto_mode_test 
  sensor_test 
  sensor_limit_values_test 
  global_test 
  manual_mode_test
  long_push_button_test
}

  cd {..\smart_lamp_controller.sim\sim_1\behav\xsim}

  set log_dir "../regression_logs"
  set coverage_dir "../regression_coverage"
  file delete -force $log_dir $coverage_dir
  file mkdir $log_dir $coverage_dir


foreach test $tests {
  set seed [expr {int(rand()*100000)}]

  set_property xsim.simulate.runtime 1000s [get_filesets sim_1]
  set_property xsim.elaborate.coverage.dir $coverage_dir [get_filesets sim_1]
  set_property xsim.elaborate.coverage.name "${test}_${seed}_cov" [get_filesets sim_1]
  set_property xsim.elaborate.coverage.type all [get_filesets sim_1]
  
  puts "-----------------------------------"
  puts "Running test: $test with seed $seed"
  puts "-----------------------------------"

  set_property -name {xsim.simulate.xsim.more_options} \
    -value "-testplusarg UVM_TESTNAME=$test -testplusarg UVM_VERBOSITY=UVM_LOW -sv_seed $seed" \
    -objects [get_filesets sim_1]

  launch_simulation

  export_xsim_coverage \
    -cov_db_dir $coverage_dir \
    -cov_db_name "${test}_${seed}_cov" \
    -output_dir "$coverage_dir/report_${test}_${seed}"

  close_sim

  after 1000

  file copy -force simulate.log "$log_dir/${test}_${seed}.log"
}
