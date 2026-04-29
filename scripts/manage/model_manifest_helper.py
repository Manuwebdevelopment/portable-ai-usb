#!/usr/bin/env python3
"""Portable AI USB - Model Manifest Helper"""
import json
import sys
import os

MANIFEST_PATH = os.environ.get("MANIFEST_PATH", "")
CMD = sys.argv[1] if len(sys.argv) > 1 else "info"

if not MANIFEST_PATH or not os.path.exists(MANIFEST_PATH):
    print("ERROR: Manifest not found: " + MANIFEST_PATH, file=sys.stderr)
    sys.exit(1)

with open(MANIFEST_PATH) as f:
    manifest = json.load(f)

models = manifest.get("models", [])
rules = manifest.get("detection_rules", {})

if CMD == "info":
    model_id = sys.argv[2] if len(sys.argv) > 2 else ""
    if not model_id:
        print("ERROR: Model ID required", file=sys.stderr)
        sys.exit(1)
    for m in models:
        if m["id"] == model_id:
            print(json.dumps(m, indent=2))
            sys.exit(0)
    print(f"ERROR: Model '{model_id}' not found", file=sys.stderr)
    sys.exit(1)

elif CMD == "list":
    print("=== Available Models ===")
    print(f"{'ID':<25} {'Name':<30} {'Size':<6} {'Min RAM':<8} {'Rec RAM':<17} {'Use Case'}")
    print("---")
    for m in sorted(models, key=lambda x: x["priority"]):
        print(f"{m['id']:<25} {m['name']:<30} {m['size_gb']:<6}GB  {m['ram_min_gb']:<8}GB  {m['ram_recommended_gb']:<17}GB  {m['use_case']}")
    print()
    print("Detection Rules:")
    for rule_id, rule in rules.items():
        recommended = ", ".join(rule["recommended"][:2])
        warning = rule.get("warning", "")
        status = "(limited)" if warning else "(ok)"
        w = f" - {warning}" if warning else ""
        print(f"  {rule_id}: {recommended} [{status}]{w}")

elif CMD == "recommend":
    ram_gb = int(sys.argv[2]) if len(sys.argv) > 2 else 0
    if ram_gb == 0:
        print("ERROR: RAM (in GB) required", file=sys.stderr)
        sys.exit(1)
    # Find best matching rule
    for rule_id in ["ultra_high_ram", "high_ram", "medium_ram", "low_ram"]:
        if rule_id in rules:
            rule = rules[rule_id]
            cond = rule["condition"]
            if "128" in cond and ram_gb >= 128:
                print(" | ".join(rule["recommended"]))
                break
            elif "16" in cond and ram_gb >= 16:
                print(" | ".join(rule["recommended"]))
                break
            elif "8" in cond and ram_gb >= 8:
                print(" | ".join(rule["recommended"]))
                break
            elif "4" in cond and ram_gb >= 4:
                print(" | ".join(rule["recommended"]))
                break
            else:
                print(" | ".join(rule["recommended"]))
                break
    else:
        # Pick smallest model that fits
        candidates = [m for m in models if ram_gb >= m["ram_min_gb"]]
        if candidates:
            print(candidates[0]["id"])
        else:
            print("")
            print("No models fit your hardware", file=sys.stderr)
            sys.exit(1)

elif CMD == "auto-select":
    ram_gb = int(sys.argv[2]) if len(sys.argv) > 2 else 0
    if ram_gb == 0:
        print("ERROR: RAM (in GB) required", file=sys.stderr)
        sys.exit(1)
    candidates = [(m["priority"], m["id"]) for m in models if ram_gb >= m["ram_min_gb"]]
    if candidates:
        candidates.sort()
        print(candidates[0][1])
    else:
        print("No models fit your hardware (RAM: {}GB)".format(ram_gb), file=sys.stderr)
        sys.exit(1)

elif CMD == "manifest":
    print(json.dumps(manifest, indent=2))

elif CMD == "pull-urls":
    model_id = sys.argv[2] if len(sys.argv) > 2 else ""
    if not model_id:
        print("ERROR: Model ID required", file=sys.stderr)
        sys.exit(1)
    for m in models:
        if m["id"] == model_id:
            dl = m["downloads"]
            print("ollama:      {}".format(dl["ollama"]))
            print("huggingface: {}".format(dl["huggingface_primary"]))
            print("mirror:      {}".format(dl["huggingface_mirror"]))
            print("size:        {}GB".format(m["size_gb"]))
            print("ram_min:     {}GB".format(m["ram_min_gb"]))
            sys.exit(0)
    print("ERROR: Model '{}' not found".format(model_id), file=sys.stderr)
    sys.exit(1)

else:
    print("Unknown command: {}".format(CMD), file=sys.stderr)
    sys.exit(1)
