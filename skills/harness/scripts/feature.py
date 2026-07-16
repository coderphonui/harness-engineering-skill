#!/usr/bin/env python3
"""feature.py — manage feature_list.json and the optional feature-development lifecycle.

Python 3 stdlib only. Run from the target repository root (where feature_list.json lives).

The JSON and markdown files remain the source of truth; this tool is an ACCELERATOR —
every operation it performs can be done by hand-editing the same files, so agents
without this tool (or humans) can always follow the same flow manually.

Commands:
  init [--lifecycle]            create feature_list.json (+ docs/features/ when --lifecycle)
  list                          table of all features
  show <id>                     one feature entry + its next gate
  new "<title>" [opts]          add a feature; scaffold its stage docs (full tier)
                                opts: --area X --tier full|light --priority N --affects a,b
  scaffold <id>                 (re)create missing stage docs for an existing entry
  advance <id>                  move one stage forward, enforcing the exit gate
  start <id>                    advance until in_progress (each gate still enforced)
  verify <id>                   run the entry's verification commands; record the result
  pass <id>                     final gate -> passing (alias for the last advance)
  regress <id> [<stage>]        move backward one stage (or to a named earlier stage); ungated
  block <id> "<reason>"         mark blocked (remembers the prior stage)
  unblock <id>                  restore the pre-block stage

Lifecycle (opt-in, rules.lifecycle.enabled):
  full tier:  proposed -> in_spec -> in_design -> in_progress -> in_qa -> passing
  light tier: not_started -> in_progress -> passing
Lifecycle off: every feature uses the light flow (today's default harness behavior).
"""

import datetime
import json
import re
import subprocess
import sys
from typing import NoReturn
from pathlib import Path

FEATURE_FILE = "feature_list.json"
FULL_FLOW = ["proposed", "in_spec", "in_design", "in_progress", "in_qa", "passing"]
LIGHT_FLOW = ["not_started", "in_progress", "passing"]
# Artifact whose completion gates LEAVING the stage.
STAGE_ARTIFACTS = {
    "proposed": "brief.md",
    "in_spec": "spec.md",
    "in_design": "design.md",
    "in_qa": "review.md",
}
DEFAULT_STAGES = ["brainstorm", "spec", "design", "implement", "qa"]
TEMPLATE_DIR = Path(__file__).resolve().parent.parent / "assets" / "templates" / "lifecycle"
WORKSPACE_MARKERS = [
    "pnpm-workspace.yaml", "turbo.json", "nx.json", "lerna.json",
    "rush.json", "go.work", "melos.yaml",
]


def die(msg) -> NoReturn:
    print(f"ERROR: {msg}", file=sys.stderr)
    sys.exit(1)


def gate_fail(what, why, fix) -> NoReturn:
    print(f"GATE FAILED: {what}", file=sys.stderr)
    print(f"WHY:  {why}", file=sys.stderr)
    print(f"FIX:  {fix}", file=sys.stderr)
    sys.exit(1)


def load():
    p = Path(FEATURE_FILE)
    if not p.is_file():
        die(f"{FEATURE_FILE} not found in {Path.cwd()} — run `feature.py init` or cd to the repo root")
    try:
        return json.loads(p.read_text())
    except json.JSONDecodeError as e:
        die(f"{FEATURE_FILE} is not valid JSON: {e}")


def save(data):
    Path(FEATURE_FILE).write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n")


def find(data, fid):
    for f in data.get("features", []):
        if f.get("id") == fid:
            return f
    die(f"no feature with id '{fid}' — see `feature.py list`")


def lifecycle_on(data):
    lc = data.get("rules", {}).get("lifecycle", {})
    return bool(lc.get("enabled")) if isinstance(lc, dict) else False


def tier_of(data, f):
    if not lifecycle_on(data):
        return "light"
    return f.get("tier") or data["rules"]["lifecycle"].get("default_tier", "full")


def flow_of(data, f):
    return FULL_FLOW if tier_of(data, f) == "full" else LIGHT_FLOW


def today():
    return datetime.date.today().isoformat()


def docs_dir(f):
    return Path(f.get("docs") or f"docs/features/{f['id']}")


def is_monorepo():
    if any(Path(m).exists() for m in WORKSPACE_MARKERS):
        return True
    pkg = Path("package.json")
    if pkg.is_file() and '"workspaces"' in pkg.read_text():
        return True
    cargo = Path("Cargo.toml")
    if cargo.is_file() and re.search(r"^\[workspace\]", cargo.read_text(), re.M):
        return True
    return False


def artifact_complete(path):
    """Complete = file exists and no {{placeholders}} remain."""
    if not path.is_file():
        return False, f"{path} does not exist"
    if "{{" in path.read_text():
        return False, f"{path} still contains {{{{placeholders}}}}"
    return True, ""


def render_template(name, f):
    src = TEMPLATE_DIR / name
    if not src.is_file():
        die(f"template {src} not found — is the skill installation intact?")
    text = src.read_text()
    return (text.replace("{{id}}", f["id"])
                .replace("{{title}}", f.get("title", ""))
                .replace("{{date}}", today()))


def scaffold_docs(data, f):
    if tier_of(data, f) != "full":
        print(f"NOTE: {f['id']} is light tier — no stage docs needed")
        return
    d = docs_dir(f)
    d.mkdir(parents=True, exist_ok=True)
    created = []
    for name in ("brief.md", "spec.md", "design.md", "review.md"):
        dst = d / name
        if not dst.exists():
            dst.write_text(render_template(name, f))
            created.append(str(dst))
    f["docs"] = str(d)
    print("created: " + ", ".join(created) if created else f"all stage docs already exist in {d}")


# ---------------- gates ----------------

def check_exit_gate(data, f):
    """Enforce the gate for LEAVING f's current status. Exits on failure."""
    status = f["status"]
    tier = tier_of(data, f)

    if tier == "full" and status in STAGE_ARTIFACTS:
        art = docs_dir(f) / STAGE_ARTIFACTS[status]
        ok, why = artifact_complete(art)
        if not ok:
            gate_fail(f"stage artifact for '{status}' incomplete", why,
                      f"complete {art} (fill every placeholder), then re-run")

    if status == "in_spec":
        ver = f.get("verification", [])
        if not ver or any("{{" in v for v in ver):
            gate_fail("verification commands not recorded",
                      "a spec is not done until its acceptance criteria are executable",
                      f"copy the Verification Plan from {docs_dir(f)/'spec.md'} into this "
                      f"entry's \"verification\" array in {FEATURE_FILE}")

    if status == "in_design" and is_monorepo() and not f.get("affects"):
        gate_fail("'affects' is empty in a monorepo",
                  "change-scope triage (which apps? contract changes?) must happen before code",
                  f"fill \"affects\" on {f['id']} per the design's Affected Components section")

    if status == "in_progress":
        lv = f.get("last_verification", {})
        if lv.get("result") != "PASS":
            gate_fail("implementation not verified",
                      "done = evidence; the verification commands must actually run and pass",
                      f"run `feature.py verify {f['id']}` (or run the commands and record the result)")

    if status == "in_qa":
        review = docs_dir(f) / "review.md"
        ok, why = artifact_complete(review)
        if not ok:
            gate_fail("QA review incomplete", why,
                      f"an INDEPENDENT checker (not the implementer) fills {review}")
        text = review.read_text()
        if not re.search(r"^Verdict:\s*Accept\s*$", text, re.M | re.I):
            gate_fail("review verdict is not Accept",
                      "only an independent Accept verdict moves a feature to passing (maker != checker)",
                      f"resolve the findings in {review}; the checker sets 'Verdict: Accept'")


def check_entry_gate(data, f, nxt):
    """Enforce the gate for ENTERING status nxt."""
    if nxt == "in_progress":
        others_active = [o["id"] for o in data["features"]
                         if o is not f and o.get("status") == "in_progress"]
        if others_active:
            gate_fail("WIP=1 violated",
                      f"feature(s) already in_progress: {', '.join(others_active)}",
                      "finish (or block, with a documented reason) the active feature first")
        in_qa = [o["id"] for o in data["features"]
                 if o is not f and o.get("status") == "in_qa"]
        if in_qa:
            print(f"WARNING: {', '.join(in_qa)} still awaiting QA — "
                  "prefer closing QA before starting new implementation")


def do_advance(data, f):
    status = f["status"]
    if status == "blocked":
        die(f"{f['id']} is blocked ({f.get('notes','')!r}) — use `feature.py unblock {f['id']}`")
    if status == "passing":
        print(f"{f['id']} is already passing")
        return False
    flow = flow_of(data, f)
    if status not in flow:
        die(f"status '{status}' is not in the {tier_of(data, f)}-tier flow {flow} — "
            f"fix the entry's status or tier in {FEATURE_FILE} "
            f"(hand-created entries in a full-tier project may need `feature.py scaffold {f['id']}` "
            f"and status 'proposed')")
    check_exit_gate(data, f)
    nxt = flow[flow.index(status) + 1]
    check_entry_gate(data, f, nxt)
    f["status"] = nxt
    if nxt == "passing":
        f.setdefault("evidence", []).append(f"{today()} moved to passing via gated transition")
    print(f"{f['id']}: {status} -> {nxt}")
    return True


# ---------------- commands ----------------

def cmd_init(args):
    if Path(FEATURE_FILE).exists():
        die(f"{FEATURE_FILE} already exists — refusing to overwrite")
    lifecycle = "--lifecycle" in args
    data = {
        "project": Path.cwd().name,
        "last_updated": today(),
        "rules": {
            "single_active_feature": True,
            "passing_requires_evidence": True,
            "do_not_skip_verification": True,
            "monorepo_root_gate": "when affects lists more than one app, only the root "
                                  "verification command can move a feature to passing",
            "state_machine": " -> ".join(LIGHT_FLOW) + " (+ blocked)",
            "lifecycle": {
                "enabled": lifecycle,
                "default_tier": "full",
                "stages": DEFAULT_STAGES,
                "state_machine_full": " -> ".join(FULL_FLOW) + " (+ blocked)",
            },
        },
        "features": [],
    }
    save(data)
    print(f"created {FEATURE_FILE} (lifecycle {'enabled' if lifecycle else 'disabled'})")
    if lifecycle:
        Path("docs/features").mkdir(parents=True, exist_ok=True)
        print("created docs/features/")


def cmd_list(_args):
    data = load()
    feats = data.get("features", [])
    if not feats:
        print("no features — add one with `feature.py new \"<title>\"`")
        return
    rows = [("ID", "STATUS", "TIER", "PRI", "AFFECTS", "TITLE")]
    for f in feats:
        rows.append((f.get("id", "?"), f.get("status", "?"), tier_of(data, f),
                     str(f.get("priority", "-")), ",".join(f.get("affects", [])) or "-",
                     f.get("title", "")))
    widths = [max(len(r[i]) for r in rows) for i in range(5)]
    for r in rows:
        print("  ".join(r[i].ljust(widths[i]) for i in range(5)) + "  " + r[5])


def cmd_show(args):
    data = load()
    if not args:
        die("usage: feature.py show <id>")
    f = find(data, args[0])
    print(json.dumps(f, indent=2, ensure_ascii=False))
    flow = flow_of(data, f)
    status = f["status"]
    if status in flow and status != "passing":
        nxt = flow[flow.index(status) + 1]
        art = STAGE_ARTIFACTS.get(status)
        gate = f"complete {docs_dir(f)/art}" if (art and tier_of(data, f) == "full") else \
               ("verification must PASS (feature.py verify)" if status == "in_progress" else "none")
        print(f"\ntier: {tier_of(data, f)}   next: {nxt}   exit gate: {gate}")


def cmd_new(args):
    data = load()
    title, area, tier, priority, affects = None, "feat", None, None, []
    i = 0
    while i < len(args):
        a = args[i]
        if a == "--area":
            i += 1; area = args[i]
        elif a == "--tier":
            i += 1; tier = args[i]
            if tier not in ("full", "light"):
                die("--tier must be full or light")
        elif a == "--priority":
            i += 1; priority = int(args[i])
        elif a == "--affects":
            i += 1; affects = [s.strip() for s in args[i].split(",") if s.strip()]
        elif title is None:
            title = a
        else:
            die(f"unexpected argument {a!r}")
        i += 1
    if not title:
        die('usage: feature.py new "<title>" [--area X] [--tier full|light] [--priority N] [--affects a,b]')

    nums = [int(m.group(1)) for f in data.get("features", [])
            if (m := re.match(rf"^{re.escape(area)}-(\d+)$", f.get("id", "")))]
    fid = f"{area}-{(max(nums) + 1) if nums else 1:03d}"
    f = {
        "id": fid,
        "priority": priority if priority is not None else len(data.get("features", [])) + 1,
        "area": area,
        "title": title,
        "user_visible_behavior": "",
        "status": "",
        "affects": affects,
        "verification": [],
        "evidence": [],
        "depends_on": [],
        "notes": "",
    }
    if tier:
        f["tier"] = tier
    f["status"] = FULL_FLOW[0] if tier_of(data, f) == "full" else LIGHT_FLOW[0]
    data.setdefault("features", []).append(f)
    if tier_of(data, f) == "full":
        scaffold_docs(data, f)
    data["last_updated"] = today()
    save(data)
    print(f"added {fid} ({tier_of(data, f)} tier, status {f['status']})")


def cmd_scaffold(args):
    data = load()
    if not args:
        die("usage: feature.py scaffold <id>")
    f = find(data, args[0])
    scaffold_docs(data, f)
    data["last_updated"] = today()
    save(data)


def cmd_advance(args):
    data = load()
    if not args:
        die("usage: feature.py advance <id>")
    f = find(data, args[0])
    if do_advance(data, f):
        data["last_updated"] = today()
        save(data)


def cmd_start(args):
    data = load()
    if not args:
        die("usage: feature.py start <id>")
    f = find(data, args[0])
    moved = False
    while f["status"] != "in_progress":
        if not do_advance(data, f):
            break
        moved = True
    if moved:
        data["last_updated"] = today()
        save(data)
    if f["status"] == "in_progress":
        print(f"{f['id']} is in_progress — WIP=1: work only on this until verified or blocked")


def cmd_verify(args):
    data = load()
    if not args:
        die("usage: feature.py verify <id>")
    f = find(data, args[0])
    cmds = f.get("verification", [])
    if not cmds or any("{{" in c for c in cmds):
        gate_fail("no runnable verification commands on this entry",
                  "a feature without executable verification can never earn 'passing'",
                  f"fill the \"verification\" array on {f['id']} in {FEATURE_FILE}")
    passed = 0
    for c in cmds:
        print(f"==> {c}", flush=True)
        r = subprocess.run(["bash", "-c", c])
        if r.returncode == 0:
            passed += 1
        else:
            print(f"FAILED (exit {r.returncode}): {c}", file=sys.stderr)
    result = "PASS" if passed == len(cmds) else "FAIL"
    stamp = datetime.datetime.now().isoformat(timespec="seconds")
    f["last_verification"] = {"date": stamp, "result": result,
                              "commands_passed": f"{passed}/{len(cmds)}"}
    f.setdefault("evidence", []).append(f"{stamp} verify {result} ({passed}/{len(cmds)} commands)")
    data["last_updated"] = today()
    save(data)
    print(f"verification {result} ({passed}/{len(cmds)}) — recorded on {f['id']}")
    sys.exit(0 if result == "PASS" else 1)


def cmd_pass(args):
    data = load()
    if not args:
        die("usage: feature.py pass <id>")
    f = find(data, args[0])
    flow = flow_of(data, f)
    if f["status"] not in flow or flow.index(f["status"]) != len(flow) - 2:
        die(f"{f['id']} is at '{f['status']}', not at the final gate "
            f"(expected '{flow[-2]}') — use `feature.py advance {f['id']}` to move through "
            f"the earlier stages")
    if do_advance(data, f):
        data["last_updated"] = today()
        save(data)


def cmd_regress(args):
    """Move BACKWARD one stage (or to a named earlier stage). Backward moves are ungated —
    gates only guard forward progress. Used when QA blocks or a stage's premise fails."""
    data = load()
    if not args:
        die("usage: feature.py regress <id> [<earlier-stage>]")
    f = find(data, args[0])
    flow = flow_of(data, f)
    status = f["status"]
    if status == "blocked":
        die(f"{f['id']} is blocked — unblock first, then regress")
    if status not in flow:
        die(f"status '{status}' is not in the {tier_of(data, f)}-tier flow {flow}")
    idx = flow.index(status)
    if idx == 0:
        die(f"{f['id']} is already at the first stage ({status})")
    if len(args) > 1:
        target = args[1]
        if target not in flow or flow.index(target) >= idx:
            die(f"target must be an earlier stage in {flow[:idx]}")
    else:
        target = flow[idx - 1]
    f["status"] = target
    f["notes"] = (f.get("notes", "") + f"\n[{today()}] REGRESSED {status} -> {target}").strip()
    # Rework invalidates prior verification evidence — it must be re-earned after the changes.
    if f.pop("last_verification", None) is not None:
        f.setdefault("evidence", []).append(
            f"{today()} last_verification cleared by regress to {target} — re-run verify")
    data["last_updated"] = today()
    save(data)
    print(f"{f['id']}: {status} -> {target} (regressed; forward gates apply again from here, "
          f"and verification must be re-run)")


def cmd_block(args):
    data = load()
    if len(args) < 2:
        die('usage: feature.py block <id> "<reason>"')
    f = find(data, args[0])
    if f["status"] == "blocked":
        die(f"{f['id']} is already blocked")
    f["blocked_from"] = f["status"]
    f["status"] = "blocked"
    reason = args[1]
    f["notes"] = (f.get("notes", "") + f"\n[{today()}] BLOCKED: {reason}").strip()
    data["last_updated"] = today()
    save(data)
    print(f"{f['id']} blocked (was {f['blocked_from']}): {reason}")


def cmd_unblock(args):
    data = load()
    if not args:
        die("usage: feature.py unblock <id>")
    f = find(data, args[0])
    if f["status"] != "blocked":
        die(f"{f['id']} is not blocked (status: {f['status']})")
    f["status"] = f.pop("blocked_from", LIGHT_FLOW[0])
    data["last_updated"] = today()
    save(data)
    print(f"{f['id']} unblocked -> {f['status']}")


COMMANDS = {
    "init": cmd_init, "list": cmd_list, "show": cmd_show, "new": cmd_new,
    "scaffold": cmd_scaffold, "advance": cmd_advance, "start": cmd_start,
    "verify": cmd_verify, "pass": cmd_pass, "regress": cmd_regress,
    "block": cmd_block, "unblock": cmd_unblock,
}


def main():
    argv = sys.argv[1:]
    if not argv or argv[0] in ("-h", "--help", "help"):
        print((__doc__ or "").strip())
        sys.exit(0)
    cmd = COMMANDS.get(argv[0])
    if not cmd:
        die(f"unknown command '{argv[0]}' — run `feature.py help`")
    cmd(argv[1:])


if __name__ == "__main__":
    main()
