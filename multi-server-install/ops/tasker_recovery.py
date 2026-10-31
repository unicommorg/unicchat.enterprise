#!/usr/bin/env python3
"""Check dependencies before an explicitly requested Tasker recreation."""
import argparse
from pathlib import Path
import subprocess


def recover(compose, recreate=False):
    # A fresh probe must succeed on EVERY invocation, including an existing install.
    result = subprocess.run(compose + ["run", "--rm", "--no-deps", "dependency-probe", "--once"], check=False)
    if result.returncode:
        return result.returncode
    if recreate:
        return subprocess.run(compose + ["up", "-d", "--no-deps", "--force-recreate", "unicchat-tasker"], check=False).returncode
    return 0


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--compose-file", choices=("docker-compose.yml", "compose.tasker.yml"), default="docker-compose.yml")
    parser.add_argument("--recreate", action="store_true", help="Recreate only Tasker after successful preflight")
    args = parser.parse_args()
    root = Path(__file__).resolve().parent.parent
    compose = ["docker", "compose", "--project-directory", str(root), "--env-file", str(root / ".env"),
               "-f", str(root / args.compose_file), "-f", str(root / "compose.dependency-probe.yml")]
    return recover(compose, args.recreate)


if __name__ == "__main__":
    raise SystemExit(main())
