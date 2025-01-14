#
# Run Parflow test
#
# Must have find_package(MPI) in project using this macro

cmake_minimum_required(VERSION 3.14)

# Execute command with error check
# cmd parameter passed in as reference
macro(pf_exec_check cmd)

  set( ENV{PF_TEST} "yes" )
  if (${PARFLOW_HAVE_SILO})
    set( ENV{PARFLOW_HAVE_SILO} "yes")
  endif()

  # Note: This method of printing the command is only necessary because the
  # 'COMMAND_ECHO' parameter of execute_process is relatively new, introduced
  # around cmake-3.15, and we'd like to be compatible with older cmake versions.
  # See the cmake_minimum_required above.
  list(JOIN ${cmd} " " cmd_str)
  message(STATUS "Executing: ${cmd_str}")
  execute_process (COMMAND ${${cmd}} RESULT_VARIABLE cmd_result OUTPUT_VARIABLE joined_stdout_stderr ERROR_VARIABLE joined_stdout_stderr)

  message(STATUS "Output:\n${joined_stdout_stderr}")
  if (cmd_result)
    message (FATAL_ERROR "Error (${cmd_result}) while running test.")
  endif()

  # If FAIL is present test fails
  string(FIND "${joined_stdout_stderr}" "FAIL" test)
  if (NOT ${test} EQUAL -1)
    message (FATAL_ERROR "Test Failed: output indicated FAIL")
  endif()

  # Test must say PASSED to pass
  string(FIND "${joined_stdout_stderr}" "PASSED" test)
  if (${test} LESS 0)
    message (FATAL_ERROR "Test Failed: output did not indicate PASSED")
  endif()

  string(FIND "${joined_stdout_stderr}" "Using Valgrind" test)
  if (NOT ${test} EQUAL -1)
    # Using valgrind
    string(FIND "${joined_stdout_stderr}" "ERROR SUMMARY: 0 errors" test)
    if (${test} LESS 0)
      message (FATAL_ERROR "Valgrind Errors Found")
    endif()
  endif()

endmacro()

# Clean a parflow directory
macro(pf_test_clean)
  file(GLOB FILES *.pfb* *.silo* *.pfsb* *.log .hostfile .amps.* *.out.pftcl *.pfidb *.out.txt default_richards.out *.out.wells indicator_field.out)
  if (NOT FILES STREQUAL "")
    file(REMOVE ${FILES})
  endif()

  file(GLOB FILES default_single.out water_balance.out default_overland.out LW_var_dz_spinup.out test.log.* richards_hydrostatic_equalibrium.out core.* samrai_grid.tmp.tcl samrai_grid2D.tmp.tcl CMakeCache.txt)
  if (NOT FILES STREQUAL "")
    file(REMOVE ${FILES})
  endif()
endmacro()

pf_test_clean ()

list(APPEND CMD tclsh ${PARFLOW_TEST})

if (${PARFLOW_HAVE_MEMORYCHECK})
  SET(ENV{PARFLOW_MEMORYCHECK_COMMAND} ${PARFLOW_MEMORYCHECK_COMMAND})
  SET(ENV{PARFLOW_MEMORYCHECK_COMMAND_OPTIONS} ${PARFLOW_MEMORYCHECK_COMMAND_OPTIONS})
endif()

if (${PARFLOW_HAVE_OAS3})
  # Create dummy namcouple file to successfully initialize OASIS3-MCT
  set(NAMCOUPLE_FILE namcouple)
  file(WRITE  ${NAMCOUPLE_FILE} "$NFIELDS\n")
  file(APPEND ${NAMCOUPLE_FILE} "  0\n")
  file(APPEND ${NAMCOUPLE_FILE} "$RUNTIME\n")
  file(APPEND ${NAMCOUPLE_FILE} "  0\n")
  file(APPEND ${NAMCOUPLE_FILE} "$NLOGPRT\n")
  file(APPEND ${NAMCOUPLE_FILE} "  0 0\n")
  file(APPEND ${NAMCOUPLE_FILE} "$STRINGS\n")
endif()

pf_exec_check(CMD)

if (${PARFLOW_HAVE_OAS3})
  # Delete dummy namcouple and log files generated by OASIS3-MCT
  file(GLOB FILES namcouple debug.root.01 nout.000000)
  if (NOT FILES STREQUAL "")
    file(REMOVE ${FILES})
  endif()
endif()

if (${PARFLOW_HAVE_MEMORYCHECK})
  UNSET(ENV{PARFLOW_MEMORYCHECK_COMMAND})
  UNSET(ENV{PARFLOW_MEMORYCHECK_COMMAND_OPTIONS})
endif()
