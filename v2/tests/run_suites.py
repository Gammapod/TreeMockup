"""Run V2 contract suites. Python 3.10+, standard library only."""
import argparse
from collections import Counter
from datetime import datetime, timezone
import json
import math
import os
from pathlib import Path
import re
import shutil
import signal
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]
PREFIX = "V2_TEST_RESULT "
STATUSES = ("passed", "failed", "error", "timeout", "not_run")
ERROR_LINE = re.compile(r"^\s*(?:SCRIPT ERROR:|ERROR:)", re.MULTILINE)


def validate_inventory(suites, root, owner=None):
    ids, scripts = set(), set()
    for suite in suites:
        if (not re.fullmatch(r"[a-z][a-z0-9_]*", suite["id"])
                or suite["id"] in ids or suite["script"] in scripts):
            raise ValueError("Invalid or duplicate suite ID/script")
        if not suite["area"] or not suite["invariants"]:
            raise ValueError("Each suite requires an area and invariant trace")
        ids.add(suite["id"])
        scripts.add(suite["script"])
    directory = root / "tests" / owner if owner else root / "tests"
    actual = {p.relative_to(root).as_posix() for p in directory.rglob("*_tests.gd")}
    if actual != scripts:
        raise ValueError(f"Inventory mismatch: unlisted={sorted(actual - scripts)}, "
                         f"missing={sorted(scripts - actual)}")


def load_inventory(root, owner=None):
    owners = (owner,) if owner else ("engine", "frontend")
    if any(name not in ("engine", "frontend") for name in owners):
        raise ValueError(f"Unknown owner: {owner}")
    suites = []
    for name in owners:
        entries = json.loads((root / "tests" / name / "suites.json").read_text(encoding="utf-8"))
        if not isinstance(entries, list):
            raise ValueError(f"Invalid {name} suite manifest")
        for suite in entries:
            path = suite["script"]
            prefix = f"tests/{name}/"
            if (not isinstance(path, str) or not path.startswith(prefix)
                    or any(part in ("", ".", "..") for part in path.split("/"))):
                raise ValueError(f"Suite path must belong to {name}: {path}")
        validate_inventory(entries, root, name)
        suites.extend(entries)
    if not owner:
        validate_inventory(suites, root)
    return suites


def select(suites, ids, areas, invariants):
    for key, requested in (("id", ids), ("area", areas), ("invariants", invariants)):
        known = {v for s in suites for v in
                 (s[key] if key == "invariants" else [s[key]])}
        if set(requested) - known:
            raise ValueError(f"Unknown {key}: {sorted(set(requested) - known)}")
    if not (ids or areas or invariants):
        return suites
    return [s for s in suites if s["id"] in ids or s["area"] in areas
            or set(s["invariants"]) & set(invariants)]


def terminate(process):
    if os.name == "nt":
        subprocess.run(["taskkill", "/PID", str(process.pid), "/T", "/F"],
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    else:
        try:
            os.killpg(process.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
    if process.poll() is None:
        process.kill()
    process.wait()


def run_suite(suite, command, folder, timeout):
    folder.mkdir(parents=True, exist_ok=True)
    stdout, stderr = folder / "stdout.log", folder / "stderr.log"
    result = dict(suite, status="error", duration=0, exit_code=None, assertions=None,
                  failed_assertions=None, passed_assertions=None, failures=[], errors=[],
                  stdout_log=str(stdout.resolve()), stderr_log=str(stderr.resolve()))
    start = time.monotonic()
    try:
        with stdout.open("wb") as out, stderr.open("wb") as err:
            process = subprocess.Popen(command, stdout=out, stderr=err,
                                       start_new_session=os.name != "nt")
            try:
                result["exit_code"] = process.wait(timeout=timeout)
            except subprocess.TimeoutExpired:
                terminate(process)
                result["exit_code"] = process.returncode
                result["status"] = "timeout"
                result["errors"].append(f"Exceeded {timeout:g}s timeout")
            except KeyboardInterrupt:
                terminate(process)
                raise
    except OSError as exc:
        result["errors"].append(str(exc))
    result["duration"] = round(time.monotonic() - start, 3)
    text = stdout.read_text(errors="replace") + "\n" + stderr.read_text(errors="replace")
    if result["status"] == "timeout" or result["errors"]:
        return result
    records = [line[len(PREFIX):] for line in text.splitlines() if line.startswith(PREFIX)]
    try:
        if len(records) != 1:
            raise ValueError(f"Expected one completion record; found {len(records)}")
        record = json.loads(records[0])
        if (record["schema_version"] != 1 or record["suite"] != suite["id"]
                or type(record["assertions"]) is not int or record["assertions"] < 1
                or not isinstance(record["failures"], list)
                or not all(isinstance(f, str) for f in record["failures"])
                or len(record["failures"]) > record["assertions"]):
            raise ValueError("Invalid completion record")
        result.update(assertions=record["assertions"], failures=record["failures"],
                      failed_assertions=len(record["failures"]),
                      passed_assertions=record["assertions"] - len(record["failures"]))
    except (ValueError, KeyError, TypeError) as exc:
        result["errors"].append(str(exc))
    diagnostics = [line for line in text.splitlines() if ERROR_LINE.match(line)]
    # Exact, suite-local diagnostic lines only; never broad regex suppression.
    expected = list(suite.get("expected_diagnostics", []))
    for line in diagnostics:
        if line in expected:
            expected.remove(line)
        else:
            result["errors"].append(line)
    if expected:
        result["errors"].append(f"Expected diagnostics absent: {expected}")
    if result["errors"]:
        result["status"] = "error"
    elif result["failures"]:
        result["status"] = "failed"
    elif result["exit_code"] != 0:
        result["errors"].append(f"Unexpected exit code {result['exit_code']}")
    else:
        result["status"] = "passed"
    return result


def summarize(results):
    counts = Counter(r["status"] for r in results)
    return {"status": "passed" if results and all(r["status"] == "passed" for r in results)
            else "failed", "totals": {s: counts[s] for s in STATUSES}}


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default=os.environ.get("GODOT", "godot"))
    parser.add_argument("--suite", action="append", default=[])
    parser.add_argument("--area", action="append", default=[])
    parser.add_argument("--invariant", action="append", default=[])
    parser.add_argument("--owner", choices=("engine", "frontend"))
    parser.add_argument("--timeout", type=float, default=60)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--list", action="store_true")
    args = parser.parse_args(argv)
    stamp = datetime.now(timezone.utc)
    output = (args.output or ROOT / "test-results" / stamp.strftime("%Y%m%dT%H%M%S.%fZ")).resolve()
    output.mkdir(parents=True, exist_ok=True)
    report = {"schema_version": 1, "started_at": stamp.isoformat(), "status": "error",
              "godot_version": None, "errors": [], "suites": [],
              "configuration": {"godot": args.godot, "timeout": args.timeout,
                                "suite": args.suite, "area": args.area,
                                 "invariant": args.invariant, "owner": args.owner}}
    started = time.monotonic()
    try:
        suites = load_inventory(ROOT, args.owner)
        suites = select(suites, args.suite, args.area, args.invariant)
        if args.list:
            for suite in suites:
                print(f"{suite['id']:22} {suite['area']:16} {','.join(suite['invariants'])}")
            return 0
        report["suites"] = [dict(s, status="not_run") for s in suites]
        if not math.isfinite(args.timeout) or args.timeout <= 0:
            raise ValueError("Timeout must be finite and positive")
        executable = shutil.which(args.godot)
        if not executable:
            raise ValueError(f"Godot executable not found: {args.godot}")
        version = subprocess.run([executable, "--version"], capture_output=True,
                                 text=True, timeout=10, check=True)
        report["godot_version"] = version.stdout.strip()
        for index, suite in enumerate(suites):
            result = run_suite(suite, [executable, "--headless", "--path", str(ROOT),
                                      "--script", suite["script"]],
                               output / suite["id"], args.timeout)
            report["suites"][index] = result
            print(f"{result['status'].upper():8} {suite['id']:22} {result['duration']:7.3f}s")
        report.update(summarize(report["suites"]))
    except (OSError, ValueError, KeyError, TypeError, subprocess.SubprocessError) as exc:
        report["errors"].append(str(exc))
    except KeyboardInterrupt:
        report["errors"].append("Run interrupted")
    report["duration"] = round(time.monotonic() - started, 3)
    report["totals"] = summarize(report["suites"])["totals"]
    (output / "report.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"{report['status'].upper()}: {report['totals']}")
    for error in report["errors"]:
        print(error)
    print(f"Report: {output / 'report.json'}")
    return 0 if report["status"] == "passed" else 1


if __name__ == "__main__":
    raise SystemExit(main())
