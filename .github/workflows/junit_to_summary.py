#!/usr/bin/env python3
"""Append a JUnit XML report as a markdown summary to $GITHUB_STEP_SUMMARY."""
from __future__ import annotations

import os
import sys
import xml.etree.ElementTree as ET
from pathlib import Path


def main() -> int:
    if len(sys.argv) < 3:
        print("usage: junit_to_summary.py <junit.xml> <title>", file=sys.stderr)
        return 2

    xml_path = Path(sys.argv[1])
    title = sys.argv[2]
    summary_path = os.environ.get("GITHUB_STEP_SUMMARY")

    lines: list[str] = [f"## {title}", ""]

    if not xml_path.exists():
        lines += [f"_No results file found at `{xml_path}`._", ""]
        _write(summary_path, lines)
        return 0

    tree = ET.parse(xml_path)
    root = tree.getroot()
    suites = root.findall("testsuite") if root.tag == "testsuites" else [root]

    total = failures = errors = skipped = 0
    time_total = 0.0
    failed_cases: list[tuple[str, str, str]] = []

    for suite in suites:
        total += int(suite.attrib.get("tests", 0))
        failures += int(suite.attrib.get("failures", 0))
        errors += int(suite.attrib.get("errors", 0))
        skipped += int(suite.attrib.get("skipped", 0))
        try:
            time_total += float(suite.attrib.get("time", 0) or 0)
        except ValueError:
            pass

        for case in suite.findall("testcase"):
            for kind in ("failure", "error"):
                node = case.find(kind)
                if node is not None:
                    name = case.attrib.get("name", "")
                    classname = case.attrib.get("classname", "")
                    msg = (node.attrib.get("message") or (node.text or "")).strip()
                    failed_cases.append((classname, name, msg[:500]))

    passed = total - failures - errors - skipped
    status = "PASSED" if (failures == 0 and errors == 0) else "FAILED"

    lines += [
        f"**Status:** {status}  ",
        "",
        "| Total | Passed | Failed | Errors | Skipped | Time |",
        "|------:|-------:|-------:|-------:|--------:|-----:|",
        f"| {total} | {passed} | {failures} | {errors} | {skipped} | {time_total:.2f}s |",
        "",
    ]

    if failed_cases:
        lines += ["### Failures", ""]
        for classname, name, msg in failed_cases:
            full = f"{classname}::{name}" if classname else name
            lines.append(f"<details><summary><code>{full}</code></summary>\n")
            lines.append("```")
            lines.append(msg or "(no message)")
            lines.append("```")
            lines.append("</details>")
        lines.append("")

    _write(summary_path, lines)
    return 0


def _write(summary_path: str | None, lines: list[str]) -> None:
    text = "\n".join(lines) + "\n"
    if summary_path:
        with open(summary_path, "a", encoding="utf-8") as fh:
            fh.write(text)
    else:
        sys.stdout.write(text)


if __name__ == "__main__":
    raise SystemExit(main())
