#!/bin/bash
# create-wk-agent.sh — 从 manifest 生成一个新的 per-component 开发 agent。
#
# 设计：wk-im-dev/ 本身即模板（single template, no drift）。生成器克隆它，
# 然后做 slug 改名 + 组件名替换 + 依据 manifest 重生成 components.conf。
# 组件名替换会顺带把 identity / 约束 / 文档里的旧组件名改掉，无需单独模板化散文。
#
# 用法：
#   tools/create-wk-agent.sh --manifest manifests/example-pay.json --out /tmp/wk-pay-dev
#   tools/create-wk-agent.sh --manifest manifests/im.json --out /tmp/regen   # dogfood
#
# Created by yuxilong on 2026/06/15

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEMPLATE="$REPO_ROOT/wk-im-dev"
MANIFEST=""
OUT=""
FORCE=0
REGISTER=1

usage() {
  cat <<'USAGE'
Usage: create-wk-agent.sh --manifest <file> --out <dir> [--template <dir>] [--force] [--no-register]

  --manifest <file>   组件 agent manifest（JSON）。
  --out <dir>         输出目录（生成的 agent 根目录）。
  --template <dir>    模板源（默认 <repo>/wk-im-dev）。
  --force             输出目录已存在时先清空。
  --no-register       不把生成的 agent 写入仓库 .claude-plugin/marketplace.json。
                      默认：当 --out 直接位于仓库根下时自动 upsert 注册。
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --manifest) MANIFEST="${2:-}"; shift 2 ;;
    --out)      OUT="${2:-}"; shift 2 ;;
    --template) TEMPLATE="${2:-}"; shift 2 ;;
    --force)    FORCE=1; shift ;;
    --no-register) REGISTER=0; shift ;;
    -h|--help)  usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

[ -n "$MANIFEST" ] || { echo "ERROR: --manifest required" >&2; usage >&2; exit 2; }
[ -n "$OUT" ]      || { echo "ERROR: --out required" >&2; usage >&2; exit 2; }
[ -f "$MANIFEST" ] || { echo "ERROR: manifest not found: $MANIFEST" >&2; exit 1; }
[ -d "$TEMPLATE" ] || { echo "ERROR: template not found: $TEMPLATE" >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "ERROR: python3 required" >&2; exit 1; }

if [ -e "$OUT" ]; then
  if [ "$FORCE" -eq 1 ]; then rm -rf "$OUT"; else
    echo "ERROR: output exists: $OUT (use --force to overwrite)" >&2; exit 1
  fi
fi

python3 - "$MANIFEST" "$TEMPLATE" "$OUT" "$REPO_ROOT" "$REGISTER" <<'PY'
import json, os, re, shutil, sys

manifest_path, template, out = sys.argv[1], sys.argv[2], sys.argv[3]
repo_root, register = sys.argv[4], sys.argv[5] == "1"
m = json.load(open(manifest_path))

# --- source (template) identity, fixed ---
SRC_SLUG = "wk-im-dev"
SRC_CORE = "wk-im"            # slug without trailing "-dev"
SRC_COMPONENTS = ["BTIMService", "BTIMModule"]
SRC_SDK = "ThirdPartyIMSDK"

# --- target identity, derived from manifest ---
slug = m["slug"]
core = slug[:-4] if slug.endswith("-dev") else slug          # wk-pay
tgt_components = [c["name"] for c in m["components"]]
tgt_sdk = m.get("sdk_literal", SRC_SDK)
version = m.get("version", "1.0.0")

file_prefix_src, file_prefix_tgt = SRC_CORE + "-", core + "-"
marker_src, marker_tgt = SRC_CORE.upper().replace("_", "-") + "-", core.upper().replace("_", "-") + "-"
env_src,    env_tgt    = SRC_CORE.upper().replace("-", "_") + "_", core.upper().replace("-", "_") + "_"

if len(tgt_components) != len(SRC_COMPONENTS):
    sys.stderr.write(
        f"WARN: template has {len(SRC_COMPONENTS)} components, manifest has "
        f"{len(tgt_components)}. Component-name substitution maps positionally for "
        f"the first {min(len(SRC_COMPONENTS), len(tgt_components))}; review prose/diagrams.\n")

# Ordered substitutions. Component names + SDK first (whole tokens), then prefixes.
subs = []
for s, t in zip(SRC_COMPONENTS, tgt_components):
    subs.append((s, t))
subs.append((SRC_SDK, tgt_sdk))
subs += [(file_prefix_src, file_prefix_tgt), (marker_src, marker_tgt), (env_src, env_tgt)]

def rewrite(text):
    for s, t in subs:
        text = text.replace(s, t)
    return text

TEXT_EXT = {".md", ".sh", ".json", ".toml", ".conf", ".py", ".txt", ""}
SKIP_NAMES = {".git", ".DS_Store"}

# --- copy tree ---
def ignore(d, names):
    return [n for n in names if n in SKIP_NAMES]
# symlinks=True keeps e.g. agents/constraints.md -> ../skills/... as a relative
# symlink (still valid in the output tree) instead of flattening it to a file.
shutil.copytree(template, out, ignore=ignore, symlinks=True)

# --- rewrite contents + rename files (skip symlinks: rewrite the real file once) ---
for root, dirs, files in os.walk(out):
    for fn in files:
        p = os.path.join(root, fn)
        if os.path.islink(p):
            continue
        ext = os.path.splitext(fn)[1]
        is_launcher = (fn == SRC_SLUG)  # extensionless launcher
        if ext in TEXT_EXT or is_launcher:
            try:
                with open(p, "r", encoding="utf-8") as f:
                    data = f.read()
                with open(p, "w", encoding="utf-8") as f:
                    f.write(rewrite(data))
            except (UnicodeDecodeError, IsADirectoryError):
                pass
    # rename files containing the source file prefix or the launcher name
    for fn in files:
        new = fn.replace(file_prefix_src, file_prefix_tgt)
        if fn == SRC_SLUG:
            new = slug
        if new != fn:
            os.rename(os.path.join(root, fn), os.path.join(root, new))

# --- regenerate components.conf authoritatively from manifest ---
lines = ["# Generated by create-wk-agent from " + os.path.basename(manifest_path),
         "agent\t" + slug]
for c in m["components"]:
    sr = c.get("scope_root", c["name"])
    lines.append("component\t%s\t%s\t%s" % (c["name"], c.get("role", ""), sr))
for fr in m.get("forbid_import", []):
    for tgt in fr["targets"]:
        lines.append("forbid_import\t%s\t%s" % (fr["component"], tgt))
for kw in m.get("privacy_keywords", []):
    lines.append("privacy\t" + kw)
for rp in m.get("readonly_paths", []):
    lines.append("readonly\t" + rp)
with open(os.path.join(out, "components.conf"), "w", encoding="utf-8") as f:
    f.write("\n".join(lines) + "\n")

# --- rewrite plugin manifests from manifest fields ---
for rel in [".claude-plugin/plugin.json", ".codex-plugin/plugin.json"]:
    p = os.path.join(out, rel)
    if not os.path.exists(p):
        continue
    pj = json.load(open(p))
    pj["name"] = slug
    pj["version"] = version
    pj["description"] = m.get("description", pj.get("description", ""))
    if "keywords" in m:
        pj["keywords"] = m["keywords"]
    with open(p, "w", encoding="utf-8") as f:
        json.dump(pj, f, ensure_ascii=False, indent=2)
        f.write("\n")

# --- reset CHANGELOG to a stub ---
cl = os.path.join(out, "CHANGELOG.md")
if os.path.exists(cl):
    with open(cl, "w", encoding="utf-8") as f:
        f.write("# %s Changelog\n\n## v%s\n\n- 由 create-wk-agent 从 %s 生成。\n"
                % (slug, version, os.path.basename(manifest_path)))

# --- register into repo marketplace.json -----------------------------------
# Auto-register only when the output is a top-level dir directly under the repo
# root (so source.path = basename is a valid git-subdir). Generating into /tmp
# (example/dogfood) leaves the real marketplace untouched. Reuse the first
# existing entry's repo URL so team mirrors are preserved.
def register_marketplace():
    if not register:
        return "marketplace: skipped (--no-register)"
    mp = os.path.join(repo_root, ".claude-plugin", "marketplace.json")
    if not os.path.exists(mp):
        return "marketplace: %s not found, skipped" % mp
    out_abs = os.path.realpath(out)
    if os.path.dirname(out_abs) != os.path.realpath(repo_root):
        return ("marketplace: out not directly under repo root (%s) — "
                "register manually" % repo_root)
    data = json.load(open(mp))
    plugins = data.setdefault("plugins", [])
    default_url = "https://github.com/YuXilong-Labs/Agents.git"
    repo_url = default_url
    if plugins and isinstance(plugins[0].get("source"), dict):
        repo_url = plugins[0]["source"].get("url", default_url)
    entry = {
        "name": slug,
        "description": m.get("description", ""),
        "author": {"name": data.get("owner", {}).get("name", "YuXilong-Labs")},
        "category": "development",
        "keywords": m.get("keywords", []),
        "homepage": "https://github.com/YuXilong-Labs/Agents",
        "source": {"source": "git-subdir", "url": repo_url,
                   "path": os.path.basename(out_abs), "ref": "main"},
    }
    for i, p in enumerate(plugins):
        if p.get("name") == slug:
            plugins[i] = entry
            action = "updated"
            break
    else:
        plugins.append(entry)
        action = "added"
    with open(mp, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write("\n")
    return "marketplace: %s entry '%s' in %s" % (action, slug, mp)

register_msg = register_marketplace()

# --- residual scan ---
# Only flag a source token if its target differs (else it's a dogfood self-regen
# where the "source" literal is legitimately the intended output).
candidates = [
    (SRC_SLUG, slug),
    (SRC_CORE, core),
    (SRC_CORE.upper().replace("_", "-"), core.upper().replace("_", "-")),
    (SRC_CORE.upper().replace("-", "_"), core.upper().replace("-", "_")),
    (SRC_SDK, tgt_sdk),
]
candidates += list(zip(SRC_COMPONENTS, tgt_components))
residual_tokens = [s for s, t in candidates if s != t]
hits = {}
for root, dirs, files in os.walk(out):
    dirs[:] = [d for d in dirs if d not in SKIP_NAMES]
    for fn in files:
        p = os.path.join(root, fn)
        if os.path.splitext(fn)[1] not in TEXT_EXT and fn != slug:
            continue
        if os.path.islink(p):
            continue
        try:
            data = open(p, encoding="utf-8").read()
        except (UnicodeDecodeError, OSError):
            continue
        for tok in residual_tokens:
            if tok in data:
                hits.setdefault(os.path.relpath(p, out), set()).add(tok)

print("✅ generated agent: %s" % out)
print("   slug=%s  components=%s  version=%s" % (slug, ",".join(tgt_components), version))
print("   " + register_msg)
if hits:
    print("\n⚠️  residual source references (review — usually domain prose in docs):")
    for f in sorted(hits):
        print("   %s: %s" % (f, ", ".join(sorted(hits[f]))))
else:
    print("   no residual source references.")

# --- domain-prose hints (informational; skip on dogfood self-regen) ---------
# IM-specific domain nouns aren't tokens in `subs`, so they survive generation
# inside hand-written essays (knowledge topics, README examples). List the files
# so the human knows exactly what to rewrite for the new domain.
if slug != SRC_SLUG:
    domain_nouns = ["messageBody", "msgContent", "attachmentURL", "消息", "会话", "未读"]
    dhits = {}
    for root, dirs, files in os.walk(out):
        dirs[:] = [d for d in dirs if d not in SKIP_NAMES]
        for fn in files:
            p = os.path.join(root, fn)
            if os.path.splitext(fn)[1] not in TEXT_EXT and fn != slug:
                continue
            if os.path.islink(p):
                continue
            try:
                data = open(p, encoding="utf-8").read()
            except (UnicodeDecodeError, OSError):
                continue
            found = [n for n in domain_nouns if n in data]
            if found:
                dhits[os.path.relpath(p, out)] = found
    if dhits:
        print("\nℹ️  domain prose to rewrite for the new domain (IM nouns remain):")
        for f in sorted(dhits):
            print("   %s: %s" % (f, ", ".join(dhits[f])))
        print("   tip: also rename skills/im-knowledge & skills/im-review dirs + their refs.")
PY
