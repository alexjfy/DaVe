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
      source {<full_path_to_directory>\testlist.tcl}

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
  Run the regression from Vivado:
    source {<full_path_to_directory>\testlist.tcl}
  Wait for all tests and coverage reports to be generated.
  Open a terminal in this directory and execute:
    python merge_cov.py