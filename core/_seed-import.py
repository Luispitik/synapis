#!/usr/bin/env python3
"""
Sinapsis Seed Importer
──────────────────────
Imports seed instincts (YAML) into _instincts-index.json.

Idempotent: skips IDs already present. Safe to re-run.
Default source directory: <repo>/seeds/instincts/*.yaml (ship-with-install).
Override with --seeds-dir to use a custom location.

Schema mapping (seed YAML → Sinapsis instinct):
    id          → id
    trigger     → trigger_pattern
    action      → inject
    domain      → domain
    confidence  → level via thresholds:
                    ≥0.90 → permanent
                    0.70-0.89 → confirmed
                    <0.70 → draft
    source      → origin (prefixed "seed:" if not already)
    first_seen  → first_triggered (T00:00:00Z)
    last_seen   → last_triggered (T00:00:00Z)
    occurrences → occurrences (default 0)
    tags, scope, evidence → discarded (kept only in source YAML)

Optional CLI flags:
    --skip <id,id,...>          Don't import these IDs (comma-separated)
    --force-draft <id,id,...>   Import these but force level=draft
    --seeds-dir <path>          Override seeds source directory
    --index-path <path>         Override destination index
    --dry-run                   Show what would be imported; write nothing

Attribution: seed format originated in fs-cortex (MIT © Fernando Montero).
Sinapsis extends it with discrete levels via confidence thresholds.
"""
from __future__ import annotations
import argparse
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path


def default_skills_dir() -> Path:
    override = os.environ.get('SINAPSIS_HOME')
    root = Path(override) if override else (Path.home() / '.claude')
    return root / 'skills'


def default_seeds_dir() -> Path:
    here = Path(__file__).resolve().parent
    repo_seeds = here.parent / 'seeds' / 'instincts'
    if repo_seeds.exists():
        return repo_seeds
    return default_skills_dir() / '_seeds' / 'instincts'


def parse_yaml_simple(text: str) -> dict:
    """
    Minimal YAML parser for seed format (flat scalar key: value).
    Handles single-/double-quoted strings. Ignores nested lists (tags, evidence).
    """
    result = {}
    in_frontmatter = False
    for raw in text.splitlines():
        line = raw.rstrip()
        stripped = line.strip()
        if stripped == '---':
            if in_frontmatter:
                break
            in_frontmatter = True
            continue
        if not in_frontmatter:
            continue
        if not stripped or stripped.startswith('#'):
            continue
        if line.startswith(' ') or line.startswith('\t'):
            continue
        if ':' not in line:
            continue
        key, _, value = line.partition(':')
        key = key.strip()
        value = value.strip()
        if value.startswith('"') and value.endswith('"'):
            value = value[1:-1]
        elif value.startswith("'") and value.endswith("'"):
            value = value[1:-1]
        result[key] = value
    return result


def confidence_to_level(conf_str: str) -> str:
    try:
        c = float(conf_str)
    except (ValueError, TypeError):
        return 'draft'
    if c >= 0.90:
        return 'permanent'
    if c >= 0.70:
        return 'confirmed'
    return 'draft'


def iso_from_date(d: str) -> str:
    if not d:
        return ''
    try:
        dt = datetime.strptime(d, '%Y-%m-%d').replace(tzinfo=timezone.utc)
        return dt.strftime('%Y-%m-%dT%H:%M:%S.000Z')
    except ValueError:
        return d


def map_seed_to_instinct(seed: dict) -> dict:
    source = seed.get('source', 'seed')
    origin = source if source.startswith('seed') else f'seed:{source}'
    return {
        'id': seed['id'],
        'domain': seed.get('domain', 'general'),
        'level': confidence_to_level(seed.get('confidence', '0.5')),
        'trigger_pattern': seed.get('trigger', ''),
        'inject': seed.get('action', ''),
        'origin': origin,
        'added': datetime.now(timezone.utc).strftime('%Y-%m-%d'),
        'occurrences': int(seed.get('occurrences', '0') or '0'),
        'last_triggered': iso_from_date(seed.get('last_seen', '')),
        'first_triggered': iso_from_date(seed.get('first_seen', '')),
        'sessions_seen': [],
    }


def parse_id_list(value: str) -> set[str]:
    if not value:
        return set()
    return {x.strip() for x in value.split(',') if x.strip()}


def main() -> int:
    ap = argparse.ArgumentParser(description='Import seed instincts into Sinapsis index.')
    ap.add_argument('--seeds-dir', type=Path, default=default_seeds_dir())
    ap.add_argument('--index-path', type=Path,
                    default=default_skills_dir() / '_instincts-index.json')
    ap.add_argument('--skip', type=str, default='', help='IDs to skip (comma-separated)')
    ap.add_argument('--force-draft', type=str, default='',
                    help='IDs to import as draft (comma-separated)')
    ap.add_argument('--dry-run', action='store_true')
    args = ap.parse_args()

    skip_ids = parse_id_list(args.skip)
    force_draft_ids = parse_id_list(args.force_draft)

    if not args.seeds_dir.exists():
        print(f'ERROR: seeds dir missing: {args.seeds_dir}', file=sys.stderr)
        return 1
    if not args.index_path.exists():
        print(f'ERROR: instincts index missing: {args.index_path}', file=sys.stderr)
        return 1

    index = json.loads(args.index_path.read_text(encoding='utf-8'))
    existing_ids = {i['id'] for i in index.get('instincts', [])}

    imported, already, forced, skipped_override = [], [], [], []

    for yaml_file in sorted(args.seeds_dir.glob('*.yaml')):
        seed = parse_yaml_simple(yaml_file.read_text(encoding='utf-8'))
        sid = seed.get('id')
        if not sid:
            print(f'  WARN: no id in {yaml_file.name}, skipping')
            continue
        if sid in skip_ids:
            skipped_override.append(sid)
            continue
        if sid in existing_ids:
            already.append(sid)
            continue
        instinct = map_seed_to_instinct(seed)
        if sid in force_draft_ids:
            instinct['level'] = 'draft'
            forced.append(sid)
        index.setdefault('instincts', []).append(instinct)
        imported.append((sid, instinct['level']))

    if args.dry_run:
        print('[DRY-RUN] No files modified.')
    else:
        args.index_path.write_text(
            json.dumps(index, indent=2, ensure_ascii=False) + '\n',
            encoding='utf-8',
        )
        print(f'[OK] Wrote {args.index_path}')

    print(f'Imported ({len(imported)}):')
    for sid, lvl in imported:
        mark = ' (forced draft)' if sid in forced else ''
        print(f'  + {sid:35s} [{lvl}]{mark}')
    if already:
        print(f'Already present ({len(already)}): ' + ', '.join(already))
    if skipped_override:
        print(f'Skipped by --skip ({len(skipped_override)}): ' + ', '.join(skipped_override))
    return 0


if __name__ == '__main__':
    sys.exit(main())
