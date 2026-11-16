"""Runner contracts Q1–Q3; use real subprocesses without requiring Godot."""
import json
import sys
import tempfile
import unittest
from unittest.mock import patch
from pathlib import Path

import run_suites as runner


class RunnerContracts(unittest.TestCase):
    def test_completion_and_process_evidence(self):
        # Q1: neither a zero exit nor a success record alone proves success.
        with tempfile.TemporaryDirectory() as folder:
            suite = {"id": "fixture", "script": "tests/fixture_tests.gd",
                     "area": "fixture", "invariants": ["Q1"]}
            record = {"schema_version": 1, "suite": "fixture",
                      "assertions": 2, "failures": []}
            good = "print(" + repr(runner.PREFIX + json.dumps(record)) + ")"
            cases = [
                (good, "passed"),
                ("print('Godot banner')", "error"),
                (good + "; raise SystemExit(1)", "error"),
                (good + "; print('SCRIPT ERROR: broken')", "error"),
                ("print(" + repr(runner.PREFIX + "{bad") + ")", "error"),
                (good + ";" + good, "error"),
                ("print(" + repr(runner.PREFIX + json.dumps(dict(record, suite="wrong"))) + ")", "error"),
                ("import time; time.sleep(10)", "timeout"),
            ]
            failed = dict(record, failures=["wrong result"])
            cases.append(("print(" + repr(runner.PREFIX + json.dumps(failed)) +
                          "); raise SystemExit(1)", "failed"))
            for index, (code, status) in enumerate(cases):
                with self.subTest(status=status, code=code):
                    result = runner.run_suite(suite, [sys.executable, "-c", code],
                                              Path(folder) / str(index), 0.5)
                    self.assertEqual(status, result["status"])
                    self.assertTrue(Path(result["stdout_log"]).exists())
                    self.assertTrue(Path(result["stderr_log"]).exists())
            expected = "ERROR: deliberate negative-path diagnostic"
            command = [sys.executable, "-c", good + "; print(" + repr(expected) + ")"]
            result = runner.run_suite(dict(suite, expected_diagnostics=[expected]),
                                      command, Path(folder) / "expected", 2)
            self.assertEqual("passed", result["status"])

    def test_mixed_run_continues_and_reports(self):
        # Q3: a failed suite must not prevent remaining suites from running.
        with tempfile.TemporaryDirectory() as folder:
            results = [{"status": "failed", "duration": 0.1},
                       {"status": "passed", "duration": 0.1}]
            with patch.object(runner.shutil, "which", return_value=sys.executable), \
                 patch.object(runner.subprocess, "run") as version, \
                 patch.object(runner, "run_suite", side_effect=results) as run:
                version.return_value.stdout = "fixture version"
                code = runner.main(["--suite", "run", "--suite", "content", "--output", folder])
            self.assertNotEqual(0, code)
            self.assertEqual(2, run.call_count)
            report = json.loads((Path(folder) / "report.json").read_text())
            self.assertEqual(1, report["totals"]["failed"])
            self.assertEqual(1, report["totals"]["passed"])

    def test_inventory_selection_and_totals(self):
        # Q2/Q3: complete inventory, explicit selectors, deduplication and totals.
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            (root / "tests").mkdir()
            for name in ("a", "b"):
                (root / "tests" / (name + "_tests.gd")).touch()
            suites = [{"id": name, "script": f"tests/{name}_tests.gd",
                       "area": "editor", "invariants": ["A3"]}
                      for name in ("a", "b")]
            runner.validate_inventory(suites, root)
            self.assertEqual(suites, runner.select(suites, ["a"], ["editor"], ["A3"]))
            with self.assertRaises(ValueError):
                runner.select(suites, ["typo"], [], [])
            (root / "tests" / "unlisted_tests.gd").touch()
            with self.assertRaises(ValueError):
                runner.validate_inventory(suites, root)
            report = runner.summarize([dict(status=s) for s in
                                       ("passed", "failed", "error", "timeout", "not_run")])
            self.assertEqual(report["status"], "failed")
            self.assertEqual(sum(report["totals"].values()), 5)

    def test_cli_configuration_failure_writes_report(self):
        # Q3: configuration failures are nonzero and leave machine-readable evidence.
        with tempfile.TemporaryDirectory() as folder:
            self.assertNotEqual(0, runner.main([
                "--godot", str(Path(folder) / "missing"), "--output", folder]))
            report = json.loads((Path(folder) / "report.json").read_text())
            self.assertEqual("error", report["status"])
            self.assertTrue(report["errors"])
            self.assertNotEqual(0, runner.main([
                "--suite", "unknown", "--output", folder]))


if __name__ == "__main__":
    unittest.main()
