#!/drives/c/msys64/ucrt64/bin/python3
# ===================================================================
# Project : AXI to APB IP
# File    : run.py
# Author  : Nguyen Ngoc Man
# Purpose : Parent script to build and simulate the environment
# ===================================================================

from pathlib import Path
import os
import subprocess
import sys
import webbrowser

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


    def run_make(self, target: str, slave_cnt: int, gen_cov: int) -> None:
        cmd = ["make", target, f"NO_SLAVE={slave_cnt}", f"COVERAGE={gen_cov}", f"COV_DIR={self.COV_DIR}", f"HTML_DIR={self.HTML_DIR}"]

        print(f"\n$ {' '.join(cmd)}")

        subprocess.run(
            cmd,
            env=self.env,
            check=True,
        )

    def ask_slave_count(self) -> int:
        raw = input(
            f"Enter SLAVE_CNT (APB SLAVEs) "
            f"[{self.DEFAULT_SLAVE_CNT}]: "
        ).strip()

        return int(raw) if raw else self.DEFAULT_SLAVE_CNT

    def ask_generate_coverage(self) -> int:
        ans = input("Generate coverage report? [1/0]: ").strip().lower()
        if not ans:
            return self.DEFAULT_COVERAGE
        return 1 if ans in ("1", "y", "yes") else 0
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
        gen_cov = self.ask_generate_coverage()
        targets = ["clean", "build", "run"]
        if gen_cov:
            targets.append("cov_report")
        targets.append("wave")
        for target in targets:
            try:
                self.run_make(target, slave_cnt, gen_cov)
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
    runner = SimulationRunner()
    runner.run()
#============================================================================
#--------------------------MASTER of PROGRAM---------------------------------
#============================================================================

if __name__ == "__main__":
    main()
