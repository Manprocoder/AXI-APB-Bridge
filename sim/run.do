#============================================================
# TCL Simulation & Coverage Automation
#============================================================

#---------------------------------------------
# Global setup
#---------------------------------------------
#
#---enter number of SLAVE 
#
puts "Enter number of SLAVE (VALID choices are: 1, 2, 3 and 4):"
gets stdin choice
set slave_cnt $choice
set UVM_HOME "C:/questasim64_10.7c/uvm-1.2"
set result_dir   ../SIM_RESULT
set bin_dir ../TRASH

# List of test cases
set test_list {base_test}
#
# Cleanup old result & coverage directories
#

if {![file exists $result_dir]} {
    file mkdir $result_dir
}

if {![file exists $bin_dir]} {
    file mkdir $bin_dir
}
#---------------------------------------------
# Clean old results
#---------------------------------------------
proc clean_result {dir bin_dir} {
    # Safety check: directory must exist
    if {![file isdirectory $dir]} {
        puts "Warning: $dir does not exist or is not a directory."
        return
    }

    foreach item [glob -nocomplain -directory $dir *] {
        if {[file isdirectory $item]} {
            # Recursively clean subdirectory first
            puts "Entering directory: $item"
            clean_result $item $bin_dir

            # After recursion, check if empty
            set remaining [glob -nocomplain -directory $item *]
            if {![llength $remaining]} {
                if {[catch {file delete -force $item} err]} {
                    puts "️ Could not delete empty dir $item: $err"
                } else {
                    puts " Deleted empty dir: $item"
                }
            } else {
                puts "️ Directory not empty: $item → remaining: $remaining"
            }

        } else {
            # Process files
            set fname [file tail $item]
            set ext [file extension $fname]
            set base [file rootname $fname]

            if {[string equal -nocase $fname "vsim.log"] || [string equal -nocase $fname "vsim.wlf"]} {
                # Rename and move to bin_dir
                set newname "${base}_trash${ext}"
                set dest [file join $bin_dir $newname]

                if {[catch {file rename -force $item $dest} err]} {
                    puts " Could not move $fname to $bin_dir: $err"
                } else {
                    puts " Moved $fname → $dest"
                }
            } else {
                # Delete everything else
                if {[catch {file delete -force $item} err]} {
                    puts " Could not delete file $item: $err"
                } else {
                    puts " Deleted file: $item"
                }
            }
        }
    }
}

clean_result $result_dir $bin_dir
#delete all old files (vsim.log, vsim.wlf)
#file delete -force $bin_dir
#---------------------------------------------
# Main loop for SLAVE_CNT
#---------------------------------------------
    puts "=================================================="
    puts ">> Running simulation for SLAVE_CNT = $slave_cnt"
    puts "=================================================="

    #---------------------------------------------
    # Prepare directories for this run
    #---------------------------------------------
    set slv_dir $result_dir/${slave_cnt}SLAVE
    if {![file exists $slv_dir]} {
        file mkdir $slv_dir
    }
    #---------------------------------------------
    # Compilation
    #---------------------------------------------
    vlog -work work \
      +define+UVM_CMDLINE_NO_DPI \
      +define+UVM_REGEX_NO_DPI \
      +define+UVM_NO_DPI \
      +define+PRINT_TO_COMPARE_FILE \
      +define+PRINT_TO_SUM_FILE \
      +define+CLK_CYCLE=10 \
      +define+SLAVE_CNT=$slave_cnt \
      +incdir+$UVM_HOME/src \
        -f listfile.f \
        -timescale 1ns/1ns \
        -l $slv_dir/vlog.log \
        +cover
    #---------------------------------------------
    # Run all test cases
    #---------------------------------------------
    foreach test_case $test_list {
        puts "--------------------------------------------------"
        puts ">> Running test: $test_case with SLAVE_CNT = $slave_cnt"
        puts "--------------------------------------------------"
        set test_slv_dir $slv_dir/${test_case}
        file mkdir $test_slv_dir
        #
        # clear all files before run new SIM
        #
        # Subdirectories
        foreach subdir {IF_SVA SVA REQ_INFO COMPARE SIM_SUMMARY CHECKER_ERROR HTML_COV} {
            if {![file exists $test_slv_dir/$subdir]} {
                file mkdir $test_slv_dir/$subdir
            }
        }

        #---------------------------------------------
        # Pre-create empty log files
        #---------------------------------------------
        foreach f {
            IF_SVA/apb_error.log
            IF_SVA/axi_error.log
            SVA/sva_sb.log
            REQ_INFO/req_detail.log
            COMPARE/cmp.log
            SIM_SUMMARY/summary.log
            CHECKER_ERROR/chk_error.log
        } {
            set fh [open $test_slv_dir/$f w]
            close $fh
        }
        set ucdb_file $test_slv_dir/${test_case}_cov.ucdb
        set vsim_file $test_slv_dir/vsim.log
        set wlf_file  $test_slv_dir/vsim.wlf

        # Clear log
        set f [open $vsim_file w]
        close $f

        vsim -voptargs=+acc work.tb \
          +UVM_TESTNAME=$test_case \
          +UVM_VERBOSITY=UVM_LOW \
          -coverage \
          -coveranalysis \
          -cvgperinstance \
          -wlf $wlf_file \
          -l $vsim_file \
          -do "	do add_wave.do; 
		run -all; 
		coverage exclude -srcfile arbiter.sv -line 298;
		coverage exclude -scope /tb/dut_top/arbiter_inst/abt_st -ftrans abt_cs ABT_GO->ABT_IDLE
		coverage save $ucdb_file; 
		"
        #  
        # HTML report for this test
        vcover report -html -htmldir $test_slv_dir/HTML_COV \
            -verbose -assert -cvg -code bcesftx -source -details=abcdefgst -binrhs -testhitdataAll -stmtaltflow \
            -testdetails $ucdb_file

        # Text report for this test
        set report_file $test_slv_dir/report.txt
        coverage report -file $report_file -byfile -assert -directive -cvg -codeAll

        puts ">>> Completed test: $test_case"
    }
puts "=================================================="
puts ">>> All runs completed!"
puts "=================================================="
