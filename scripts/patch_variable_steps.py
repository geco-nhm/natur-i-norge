#!/usr/bin/env python3
"""Rebuild nin_variables.steps_json (and description Trinn sections) with måleskala grouping.

Uses a local API dump (default: scratch/vars_api.json) so we can refresh the
bundled SQLite without a full web scrape. Import helpers from scrape_nin_data.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sqlite3
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
APP_ROOT = os.path.dirname(SCRIPT_DIR)
sys.path.insert(0, SCRIPT_DIR)

from nin_variable_steps import (  # noqa: E402
    build_steps_from_variabeltrinn,
    format_steps_for_description,
)


def walk_api_variables(data):
    """Yield (id, variabeltrinn) for every variable node in allekoder JSON."""
    found = {}

    def walk(item):
        kode = item.get('kode') or {}
        kid = kode.get('id')
        if kid:
            found[kid] = item.get('variabeltrinn')
        for key in ['variabelnavn', 'underordneteVariabler', 'underordneteKoder', 'variabler']:
            for sub in item.get(key) or []:
                walk(sub)

    for root in data.get('variabler') or []:
        walk(root)
    return found


_TRINN_SECTION_RE = re.compile(
    r'\nTrinn:.*\Z',
    re.DOTALL,
)


def replace_description_trinn(description: str | None, scales) -> str | None:
    if description is None:
        return None
    trinn_lines = format_steps_for_description(scales)
    trinn_block = '\n'.join(trinn_lines) if trinn_lines else ''
    if re.search(r'\nTrinn:', description):
        return _TRINN_SECTION_RE.sub(trinn_block, description)
    if trinn_block:
        return description.rstrip() + '\n' + trinn_block
    return description


def patch_database(db_path: str, api_path: str) -> dict:
    with open(api_path, encoding='utf-8') as f:
        api_data = json.load(f)
    api_vars = walk_api_variables(api_data)

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    cursor.execute('SELECT id, description, steps_json FROM nin_variables')
    rows = cursor.fetchall()

    updated = 0
    multi_scale = 0
    missing_in_api = 0

    for var_id, description, _old_steps in rows:
        if var_id not in api_vars:
            missing_in_api += 1
            continue
        scales = build_steps_from_variabeltrinn(api_vars[var_id])
        if scales and len(scales) > 1:
            multi_scale += 1
        steps_json = json.dumps(scales, ensure_ascii=False) if scales else None
        new_description = replace_description_trinn(description, scales)
        cursor.execute(
            'UPDATE nin_variables SET steps_json = ?, description = ? WHERE id = ?',
            (steps_json, new_description, var_id),
        )
        updated += 1

    conn.commit()
    conn.close()
    return {
        'updated': updated,
        'multi_scale': multi_scale,
        'missing_in_api': missing_in_api,
        'api_vars': len(api_vars),
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        '--db',
        default=os.path.join(APP_ROOT, 'assets', 'nin_database.sqlite'),
        help='Path to nin_database.sqlite',
    )
    parser.add_argument(
        '--api',
        default=os.path.join(APP_ROOT, 'scratch', 'vars_api.json'),
        help='Path to allekoder API dump JSON',
    )
    args = parser.parse_args()

    if not os.path.exists(args.api):
        raise SystemExit(f'API dump not found: {args.api}')
    if not os.path.exists(args.db):
        raise SystemExit(f'Database not found: {args.db}')

    stats = patch_database(args.db, args.api)
    print(
        f"Patched {stats['updated']} variables "
        f"({stats['multi_scale']} multi-scale) from {stats['api_vars']} API nodes; "
        f"missing_in_api={stats['missing_in_api']}"
    )


if __name__ == '__main__':
    main()
