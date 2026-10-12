#!/usr/bin/env python3
import os, re, glob, random, subprocess

VIVADO_SETTINGS = os.environ.get("VIVADO_SETTINGS", "/home/lenovo/tools/AMDDesignTools/2025.2/Vivado/settings64.sh")
SEEDS = random.sample(range(1000, 999999), 20)
os.makedirs("out/runs", exist_ok=True)

report = [f"{'Run':<5} | {'Seed':<8} | {'Status':<8} | {'Coverage'}", "-" * 38]
print("\n".join(report))
all_passed = True

for idx, seed in enumerate(SEEDS, 1):
    log_file = f"out/runs/run_seed_{seed}.log"
    cmd = f"source {VIVADO_SETTINGS} && xsim fifo_sim_snap --runall --sv_seed {seed} --cov_db_dir out -log {log_file}"

    try:
        res = subprocess.run(cmd, shell=True, executable="/bin/bash", capture_output=True, text=True, timeout=60)
        with open(log_file) as f:
            log = f.read()
    except Exception:
        log = ""
        res = None

    passed = (res and res.returncode == 0 and 
              "[SCB]   Status            : PASSED" in log and 
              not re.search(r"(\$error|\$fatal|Assertion error)", log, re.IGNORECASE))
    
    cov = re.search(r"Functional Coverage Report:\s+([\d\.]+)%", log)
    cov_str = f"{cov.group(1)}%" if cov else "N/A"

    if not passed:
        all_passed = False

    row = f"{idx:<5} | {seed:<8} | {'PASSED' if passed else 'FAILED':<8} | {cov_str}"
    print(row)
    report.append(row)

# Clean root artifacts
for f in glob.glob("xsim*.jou*") + glob.glob("*.pb") + glob.glob("hs_err_*.log") + glob.glob("*.wdb"):
    try: os.remove(f)
    except OSError: pass

summary = f"\nRegression Result: {'ALL PASSED' if all_passed else 'FAILED'}"
print(summary)
report.append(summary)

with open("out/regression_summary.rpt", "w") as f:
    f.write("\n".join(report) + "\n")

exit(0 if all_passed else 1)