#!/usr/bin/env python3
"""
Pre-commit hook runner for WorkOrder.
Discovers and runs hook scripts from group subdirectories on staged files.
"""

import importlib.util
import os
import subprocess
import sys
from pathlib import Path
from typing import List, Tuple


class PreCommitRunner:
    def __init__(self):
        self.hooks_dir = Path(__file__).parent
        self.project_root = self.hooks_dir.parent.parent
        git_work_tree = os.environ.get("GIT_WORK_TREE")
        if git_work_tree:
            self.git_cwd = Path(git_work_tree)
        else:
            try:
                self.git_cwd = Path(
                    subprocess.check_output(
                        ["git", "rev-parse", "--show-toplevel"], text=True
                    ).strip()
                )
            except Exception:
                self.git_cwd = self.project_root
        self.failed_hooks = []
        self.passed_hooks = []

    def get_staged_files(self) -> List[str]:
        try:
            result = subprocess.run(
                ["git", "diff", "--cached", "--name-only", "--diff-filter=ACM"],
                capture_output=True,
                text=True,
                cwd=str(self.git_cwd),
            )
            if result.returncode == 0:
                return [f.strip() for f in result.stdout.splitlines() if f.strip()]
            return []
        except Exception as e:
            print(f"Warning: Could not get staged files: {e}")
            return []

    def discover_hook_scripts(self) -> List[Tuple[str, Path]]:
        hook_scripts = []
        for group_dir in self.hooks_dir.iterdir():
            if group_dir.is_dir() and not group_dir.name.startswith("."):
                for script_file in group_dir.glob("*.py"):
                    if script_file.name != "__init__.py":
                        hook_scripts.append((group_dir.name, script_file))
        hook_scripts.sort(key=lambda x: x[0])
        return hook_scripts

    def run_hook_script(self, group: str, script_path: Path, staged_files: List[str]) -> bool:
        script_name = script_path.stem
        try:
            spec = importlib.util.spec_from_file_location(
                f"{group}_{script_name}", script_path
            )
            if spec and spec.loader:
                module = importlib.util.module_from_spec(spec)
                spec.loader.exec_module(module)

                if hasattr(module, "main"):
                    result = module.main(staged_files)
                elif hasattr(module, "run"):
                    result = module.run(staged_files)
                else:
                    print(f"  WARN {group}/{script_name}: No main() or run() function found")
                    return True

                return result == 0 or result is True
        except Exception as e:
            print(f"  FAIL {group}/{script_name}: Failed to run - {e}")
            return False

        try:
            result = subprocess.run(
                [sys.executable, str(script_path)] + staged_files,
                cwd=str(self.git_cwd),
                capture_output=True,
                text=True,
            )
            if result.stdout:
                print(result.stdout.strip())
            if result.stderr:
                print(result.stderr.strip())
            return result.returncode == 0
        except Exception as e:
            print(f"  FAIL {group}/{script_name}: Failed to execute - {e}")
            return False

    def run_all_hooks(self) -> bool:
        print("[pre-commit] Running hooks on staged files...")
        print("=" * 60)

        staged_files = self.get_staged_files()
        if not staged_files:
            print("  No files staged for commit")
            return True

        print(f"  Found {len(staged_files)} staged files")

        hook_scripts = self.discover_hook_scripts()
        if not hook_scripts:
            print("  WARN No hook scripts found")
            return True

        print(f"  Running {len(hook_scripts)} hook scripts...\n")

        all_passed = True
        for group, script_path in hook_scripts:
            script_name = script_path.stem
            print(f"  >> {group}/{script_name}...")
            success = self.run_hook_script(group, script_path, staged_files)
            if success:
                self.passed_hooks.append(f"{group}/{script_name}")
                print(f"  OK {group}/{script_name} - PASSED\n")
            else:
                self.failed_hooks.append(f"{group}/{script_name}")
                print(f"  FAIL {group}/{script_name} - FAILED\n")
                all_passed = False

        return all_passed

    def print_summary(self, success: bool):
        print("=" * 60)
        if success:
            print("[pre-commit] All hooks PASSED")
        else:
            print("[pre-commit] Some hooks FAILED")
            for hook in self.failed_hooks:
                print(f"    - {hook}")
        print("")


def main():
    runner = PreCommitRunner()
    try:
        success = runner.run_all_hooks()
        runner.print_summary(success)
        return 0 if success else 1
    except KeyboardInterrupt:
        print("\n  Pre-commit hooks interrupted by user")
        return 1
    except Exception as e:
        print(f"\n  Unexpected error: {e}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
