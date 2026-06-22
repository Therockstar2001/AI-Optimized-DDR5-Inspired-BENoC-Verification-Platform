#!/usr/bin/env python3

from pathlib import Path
import re

LOG_FILE = Path("sim/run.log")
COV_FILE = Path("sim/coverage_full_random.txt")


def read_file(path: Path) -> str:
    if not path.exists():
        print(f"[WARN] Missing file: {path}")
        return ""
    return path.read_text(errors="ignore")


def extract_float(pattern: str, text: str):
    match = re.search(pattern, text)
    return match.group(1) if match else "N/A"


def extract_int(pattern: str, text: str):
    match = re.search(pattern, text)
    return match.group(1) if match else "N/A"


def main():
    log_text = read_file(LOG_FILE)
    cov_text = read_file(COV_FILE)

    crc_pass = log_text.count("[CRC PASS]")
    crc_fail = log_text.count("[CRC FAIL]")
    sb_pass = log_text.count("[SB PASS]")
    sb_fail = log_text.count("[SB FAIL]")

    total_requests = extract_int(r"Total requests\s*=\s*(\d+)", log_text)
    responses = extract_int(r"Responses\s*=\s*(\d+)", log_text)
    throughput = extract_float(r"Request throughput\s*=\s*([0-9.]+)", log_text)
    avg_latency = extract_float(r"Avg CPU latency\s*=\s*([0-9.]+)", log_text)
    max_latency = extract_int(r"Max CPU latency\s*=\s*(\d+)", log_text)
    min_latency = extract_int(r"Min CPU latency\s*=\s*(\d+)", log_text)

    covergroup_cov = extract_float(
        r"TOTAL COVERGROUP COVERAGE:\s*([0-9.]+)%",
        cov_text
    )

    overall_cov = extract_float(
        r"Total Coverage By Instance.*?:\s*([0-9.]+)%",
        cov_text
    )

    print("===================================")
    print(" BENoC VERIFICATION SUMMARY")
    print("===================================")
    print(f"Scoreboard PASS count : {sb_pass}")
    print(f"Scoreboard FAIL count : {sb_fail}")
    print(f"CRC PASS count        : {crc_pass}")
    print(f"CRC FAIL count        : {crc_fail}")
    print(f"Total requests        : {total_requests}")
    print(f"Responses             : {responses}")
    print(f"Throughput            : {throughput} req/cycle")
    print(f"Avg CPU latency       : {avg_latency} cycles")
    print(f"Max CPU latency       : {max_latency} cycles")
    print(f"Min CPU latency       : {min_latency} cycles")
    print(f"Covergroup coverage   : {covergroup_cov}%")
    print(f"Overall coverage      : {overall_cov}%")
    print("===================================")

    if sb_fail != 0:
        print("[RESULT] FAIL: Scoreboard failures detected")
    elif crc_fail == 0:
        print("[RESULT] WARN: No CRC error injection observed")
    else:
        print("[RESULT] PASS: Functional checks, CRC injection, and coverage completed")


if __name__ == "__main__":
    main()
