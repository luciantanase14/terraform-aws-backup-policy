#!/usr/bin/env python3
"""Fail if the README stops describing what the module builds.

The diagram is a claim about the system. When a resource is added to the module
and the README is not updated, the claim quietly becomes false.
"""

import re
import sys
from pathlib import Path

RESOURCE = re.compile(r'^\s*resource\s+"([a-z0-9_]+)"', re.M)

# Words a reader would look for, per resource type this module creates.
DESCRIBED_AS = {
    "aws_backup_plan": ("backup plan",),
    "aws_backup_selection": ("selection_tags", "tag selection"),
    "aws_backup_vault": ("vault",),
    "aws_backup_vault_lock_configuration": ("vault lock",),
    "aws_backup_vault_notifications": ("notification",),
    "aws_backup_vault_policy": ("vault policy", "copy into"),
    "aws_kms_key": ("customer managed key", "kms"),
}

# Plumbing nobody draws.
IGNORED = {
    "aws_backup_region_settings",
    "aws_iam_role",
    "aws_iam_role_policy",
    "aws_iam_role_policy_attachment",
    "aws_kms_alias",
}


def main():
    root = Path(__file__).resolve().parent.parent
    readme = (root / "README.md").read_text(encoding="utf-8").lower()

    if "```mermaid" not in readme:
        print("README has no diagram")
        return 1

    types = set()
    for path in root.rglob("*.tf"):
        if ".terraform" not in path.parts:
            types.update(RESOURCE.findall(path.read_text(encoding="utf-8")))

    problems = []
    for kind in sorted(types - IGNORED):
        words = DESCRIBED_AS.get(kind)
        if words is None:
            problems.append(f"{kind} is new, add it to DESCRIBED_AS or IGNORED")
        elif not any(w in readme for w in words):
            problems.append(f"{kind} is built but the README never mentions it")

    for problem in problems:
        print(problem)
    print(f"{len(types)} resource types, {len(problems)} undocumented")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
