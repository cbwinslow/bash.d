#!/usr/bin/env python3
from __future__ import annotations
import argparse, os, re
from dataclasses import dataclass
from typing import List
TASKS_FILE = os.path.join("cloudcurio-monorepo", "docs", "tasks", "TASKS.md")
@dataclass
class Task:
    raw_line: str
    task_id: str
    short_name: str
    tests: str | None
    done: bool
TASK_LINE_RE = re.compile(r"^- \[(?P<mark>[ xX])]\s+(?P<id>[A-Z0-9_-]+):\s+(?P<name>.+)$")
def parse_tasks(path: str) -> List[Task]:
    tasks: List[Task] = []
    if not os.path.exists(path):
        raise FileNotFoundError(f"Tasks file not found: {path}")
    with open(path, "r", encoding="utf-8") as f:
        lines = f.readlines()
    i = 0
    while i < len(lines):
        line = lines[i].rstrip("\n")
        m = TASK_LINE_RE.match(line)
        if not m:
            i += 1
            continue
        mark = m.group("mark")
        task_id = m.group("id")
        short_name = m.group("name")
        done = mark.lower() == "x"
        tests: str | None = None
        j = i + 1
        while j < len(lines) and lines[j].startswith("      "):
            stripped = lines[j].strip()
            if stripped.lower().startswith("tests:"):
                tests = stripped[len("tests:"):].strip()
                break
            j += 1
        tasks.append(Task(line, task_id, short_name, tests, done))
        i = j
    return tasks
def cmd_list() -> None:
    tasks = parse_tasks(TASKS_FILE)
    if not tasks:
        print("No tasks found in TASKS.md"); return
    for t in tasks:
        status = "DONE" if t.done else "TODO"
        print(f"[{status}] {t.task_id}: {t.short_name}")
        if t.tests:
            print(f"    tests: {t.tests}")
def main() -> int:
    p = argparse.ArgumentParser(description="Helper for cbw-todo tasks.")
    sub = p.add_subparsers(dest="command", required=True)
    sub.add_parser("list", help="List tasks and test commands.")
    args = p.parse_args()
    if args.command == "list":
        cmd_list()
    else:
        p.error(f"Unknown command: {args.command}")
    return 0
if __name__ == "__main__":
    raise SystemExit(main())
