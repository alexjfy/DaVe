Regression Scripts

This directory contains the scripts used for regression execution and coverage result merging.

Files:

testlist.tcl

  Tcl script used to run the complete regression in Vivado.

  The script:
    Executes all verification tests defined in the test list.
    Generates individual simulation logs.
    Collects coverage information for each test run.
    Exports HTML coverage reports.
  
  Usage:
    Open Vivado and execute:
      source {<full_path_to_directory>\scripts\testlist.tcl}

    Generated files:
      regression_logs/ – simulation logs for each test and seed.
      regression_coverage/ – coverage databases and reports.

merge_cov.py

  Python script used to merge coverage information from all generated HTML coverage reports.

  The script:
    Parses all coverage reports found in regression_coverage.
    Extracts coverpoint bins and cross bins.
    Accumulates hit counts across all regression runs.
    Generates a merged coverage summary file.

  Before running:
    Required package:
      pip install beautifulsoup4

  Usage:
    Run the script from a terminal:
      python merge_cov.py

    Generated file:
      regression_coverage/merged_cov.csv

  The script also prints uncovered bins in the terminal.

Typical Workflow:
  Create a project in Vivado in Smart_Lamp_Controller directory. It is recommended to keep the default name "project_1"
  Run a Simulation to create the xsim directory, then close the simulation
  Run the regression from Vivado:
    cd {<full_path_to_directory>\project_1\project_1.sim\sim_1\behav\xsim}
    source {<full_path_to_directory>\scripts\testlist.tcl}
  Wait for all tests and coverage reports to be generated.
  Open a terminal in this directory and execute:
    python merge_cov.py