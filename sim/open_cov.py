#!/drives/c/msys64/ucrt64/bin/python3
# ===================================================================
# Project : AXI4 to APB4 IP
# ===================================================================
# File    : open_cov.py
# Author  : Nguyen Ngoc Man
# ===================================================================
# Description : 
# ===================================================================
from pathlib import Path
import os
import subprocess
import sys
import webbrowser
#
#--------------------OPEN HTML-----------------------
#
class Open_Coverage:
    HTML_DIR = "html_cov"
#
#
#
    def ask_open_report(self, report_path: Path) -> None:
        if report_path.exists():
            webbrowser.open(report_path.resolve().as_uri())
        else:
            print(f"Coverage report not found at {report_path}")
#
#
#
    def run(self) -> None:
        report_path = Path(self.HTML_DIR) / "index.html"
        self.ask_open_report(report_path)
        print("\nOpen Coverage on Website.")
#
#--------------------Main-----------------------
#
#============================================================================
#--------------------------MAIN METHOD----------------------------------
#============================================================================
def main():
    open_cov_h = Open_Coverage() 
    open_cov_h.run()
#============================================================================
#--------------------------MASTER of PROGRAM---------------------------------
#============================================================================

if __name__ == "__main__":
    main()

