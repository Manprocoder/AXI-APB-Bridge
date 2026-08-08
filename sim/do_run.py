#!/drives/c/msys64/ucrt64/bin/python3
# ===================================================================
# Project : AXI4 to APB4 IP
# File    : do_run.py
# Author  : Nguyen Ngoc Man
# Purpose : Parent script to build and simulate the environment
# ===================================================================

from pathlib import Path
import os
import subprocess
import sys
import webbrowser
#
#
#
class Print_info_for_debug:
    PRINT_AXI_WREQ_EN = 0
    PRINT_AXI_RREQ_EN = 0
    PRINT_AXI_WDATA_EN = 0
    PRINT_APB_TRANS_EN = 0
#
#--------------------PRINT INFO FOR DEBUG-----------------------
#
    def print_or_not(self) -> int:
        return self._ask_yes_no("Print debug info(AXI write/read request, AXI write data, APB transaction in Monitor)? [1/0]: ", 0)
#
#
#
    def _ask_yes_no(self, prompt: str, default: int) -> int:
        ans = input(prompt).strip().lower()
        if not ans:
            return default
        return 1 if ans in ("1", "y", "yes") else 0

    def ask_print_info_for_debug(self) -> None:

        if self.print_or_not() == 0:
            return
#
        self.PRINT_AXI_WREQ_EN = self._ask_yes_no(
            "Print AXI Write Request? [1/0]: ", self.PRINT_AXI_WREQ_EN
        )
        self.PRINT_AXI_RREQ_EN = self._ask_yes_no(
            "Print AXI Read Request? [1/0]: ", self.PRINT_AXI_RREQ_EN
        )
        self.PRINT_AXI_WDATA_EN = self._ask_yes_no(
            "Print AXI Write Data? [1/0]: ", self.PRINT_AXI_WDATA_EN
        )
        self.PRINT_APB_TRANS_EN = self._ask_yes_no(
            "Print APB Transaction? [1/0]: ", self.PRINT_APB_TRANS_EN
        )
        print(f"=====================================================================================")
        print(f"PRINT_AXI_WREQ_EN  = {self.PRINT_AXI_WREQ_EN}")
        print(f"PRINT_AXI_RREQ_EN  = {self.PRINT_AXI_RREQ_EN}")
        print(f"PRINT_AXI_WDATA_EN = {self.PRINT_AXI_WDATA_EN}")
        print(f"PRINT_APB_TRANS_EN = {self.PRINT_APB_TRANS_EN}")
        print(f"=====================================================================================")
#
#
#
class SimulationRunner:
    DEFAULT_SLAVE_CNT = 1
    DEFAULT_COVERAGE = 0
    COV_DIR = "coverage"
    HTML_DIR = "html_cov"

    def __init__(self):
        self.env = os.environ.copy()

        # QuestaSim installation directory, Python script runs independently from configuration of bashrc
    # this is the reason why the existence of the following line
        questa_bin = r"C:\questasim64_10.7c\win64"

        # Prepend QuestaSim to PATH
        self.env["PATH"] = questa_bin + ";" + self.env["PATH"]


    def run_make(self, target: str, slave_cnt: int, gen_cov: int, name_of_test: str, verbosity_level: str) -> None:
        cmd = ["make", target, f"NO_SLAVE={slave_cnt}", f"COVERAGE={gen_cov}", f"COV_DIR={self.COV_DIR}", f"HTML_DIR={self.HTML_DIR}", f"TESTNAME={name_of_test}", f"VERBOSITY={verbosity_level}"]

        print(f"\n$ {' '.join(cmd)}")

        subprocess.run(
            cmd,
            env=self.env,
            check=True,
        )
    def ask_slave_count(self) -> int:
        raw = input(
            f"Enter SLAVE_CNT (APB SLAVEs) "
        ).strip()
        value = int(raw) if raw else self.DEFAULT_SLAVE_CNT
        return value if value != 0 else 1
#
#
#
    def ask_generate_coverage(self) -> int:
        ans = input("Generate coverage report? [1/0]: ").strip().lower()
        if not ans:
            return self.DEFAULT_COVERAGE
        return 1 if ans in ("1", "y", "yes") else 0
#
#
#
    def ask_uvm_verbosity(self) -> str:
        verbosity_levels = ["UVM_LOW", "UVM_MEDIUM", "UVM_HIGH"]
        default_idx = 1  # default -> UVM_MEDIUM

        while True:
            print("0: UVM_LOW")
            print("1: UVM_MEDIUM")
            print("2: UVM_HIGH")
            choice = input(f"\nSelect UVM_VERBOSITY (default={default_idx}): ").strip()

            if choice == "":
                return verbosity_levels[default_idx]

            if choice.isdigit():
                idx = int(choice)
                if 0 <= idx < len(verbosity_levels):
                    return verbosity_levels[idx]

            # invalid input (non-digit or out-of-range) -> fall back to default
            print("Invalid choice, using default.")
            return verbosity_levels[default_idx]
#
#
#
    def ask_run_test_selection(self) -> str:
        # project/
        project_dir = Path(__file__).resolve().parent.parent

        # project/testcases
        testcase_dir = project_dir / "testcases"

        if not testcase_dir.exists():
            print(f"Cannot find directory: {testcase_dir}")
            sys.exit(1)

        # Get all *.sv filenames without extension
#--Additional explanation: f.stem returns file_name without extension
#--.glob: search files and directories that match pattern ".sv"
        tests = sorted(f.stem for f in testcase_dir.glob("*.sv"))
        #--Exclude virtual class base_test
#
        tests = [t for t in tests if t not in ("base_test", "test_pkg")]
        if not tests:
            print("No testcase files found.")
            sys.exit(1)

        print("\n================================================================")
        print("------------------------Available testcases----------------------")
        print("=================================================================")

        for i, test in enumerate(tests):
            print(f"{i}: {test}")

        while True:
            choice = input(f"\nSelect testcase [0-{len(tests)-1}] (default=0): ").strip()

            if choice == "":
                return tests[0]

            if choice.isdigit():
                idx = int(choice)
                if 0 <= idx < len(tests):
                    return tests[idx]

            print("Invalid selection. Please try again.")
         
#
#--------------------OPEN HTML-----------------------
#
    def ask_open_report(self, report_path: Path) -> None:
        print(f"=====================================================================================")
        print(f"------------------------------COVERAGE HTML WEBSITE----------------------------------")
        print(f"=====================================================================================")

        ans = input("Open coverage report in browser? [1/0]: ").strip().lower()
        if ans in ("1", "y", "yes"):
            if report_path.exists():
                webbrowser.open(report_path.resolve().as_uri())
            else:
                print(f"Coverage report not found at {report_path}")
#
#--------------------RUN METHOD-----------------------
#
    def run(self) -> None:
        slave_cnt = self.ask_slave_count()
        level_of_verbosity = self.ask_uvm_verbosity();
        gen_cov = self.ask_generate_coverage()
        name_of_test = self.ask_run_test_selection()
#
        targets = ["clean", "build", "run"]
        if gen_cov:
            targets.append("cov_report")
#        targets.append("wave")
        for target in targets:
            try:
                self.run_make(target, slave_cnt, gen_cov, name_of_test, level_of_verbosity)
            except subprocess.CalledProcessError as err:
                print(
                f"\n'make {target}' failed "
                f"(exit {err.returncode}), stopping."
                )
                sys.exit(err.returncode)
            if target == "cov_report":
                report_path = Path(self.HTML_DIR) / "index.html"
                self.ask_open_report(report_path)
        print("\nSimulation completed successfully.")
#============================================================================
#--------------------------MAIN METHOD----------------------------------
#============================================================================
def main():
    info_h = Print_info_for_debug() 
    runner_h = SimulationRunner()
    info_h.ask_print_info_for_debug()
    runner_h.run()
#============================================================================
#--------------------------MASTER of PROGRAM---------------------------------
#============================================================================

if __name__ == "__main__":
    main()
