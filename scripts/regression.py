#!/usr/bin/env python3
import subprocess
import re
import random

SEEDS = random.sample(range(1000, 999999), 5)
VIVADO_CMD = "source /home/lenovo/tools/AMDDesignTools/2025.2/Vivado/settings64.sh && xsim fifo_sim_snap --runall --sv_seed"

print(f"{'Run':<5} | {'Seed':<10} | {'Status':<8} | {'Coverage'}")
print("-" * 40)

all_passed = True
for idx, seed in enumerate(SEEDS, 1):
    res = subprocess.run(
        f"{VIVADO_CMD} {seed}",
        shell=True,
        capture_output=True,
        text=True,
        executable="/bin/bash"
    )

    status = "PASSED" if "[SCB]   Status            : PASSED" in res.stdout else "FAILED"
    cov_match = re.search(r"Functional Coverage Report:\s+([\d\.]+)%", res.stdout)
    coverage = f"{cov_match.group(1)}%" if cov_match else "N/A"

    if status != "PASSED":
        all_passed = False

    print(f"{idx:<5} | {seed:<10} | {status:<8} | {coverage}")

print("-" * 40)
print("Regression Result:", "ALL PASSED" if all_passed else "FAILED")
exit(0 if all_passed else 1)