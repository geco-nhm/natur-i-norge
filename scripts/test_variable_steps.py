#!/usr/bin/env python3
"""Regression tests for multi-scale variabeltrinn → steps_json grouping."""

from __future__ import annotations

import json
import os
import sys
import unittest

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, SCRIPT_DIR)

from nin_variable_steps import (  # noqa: E402
    build_steps_from_variabeltrinn,
    format_steps_for_description,
)


def _load_no_aa_variabeltrinn():
    api_path = os.path.join(os.path.dirname(SCRIPT_DIR), 'scratch', 'vars_api.json')
    with open(api_path, encoding='utf-8') as f:
        data = json.load(f)

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
    return found['NO-AA']


class VariableStepsGroupingTest(unittest.TestCase):
    def test_no_aa_preserves_seven_scales(self):
        vt = _load_no_aa_variabeltrinn()
        scales = build_steps_from_variabeltrinn(vt)
        self.assertIsNotNone(scales)
        self.assertEqual(len(scales), 7)
        names = [s['maaleskalaNavn'] for s in scales]
        self.assertEqual(names, ['T1c', 'T1b', 'T1a', 'T0', 'D1b', 'D1a', 'D0'])
        total_trinn = sum(len(s['trinn']) for s in scales)
        self.assertEqual(total_trinn, 79)
        # Must not be an undifferentiated flat list of trinn dicts
        self.assertTrue(all('trinn' in s for s in scales))
        self.assertFalse(any('verdi' in s for s in scales))

    def test_empty_variabeltrinn(self):
        self.assertIsNone(build_steps_from_variabeltrinn(None))
        self.assertIsNone(build_steps_from_variabeltrinn([]))
        self.assertIsNone(build_steps_from_variabeltrinn([{'trinn': []}]))

    def test_single_scale_still_grouped(self):
        vt = [{
            'maaleskalaNavn': 'T0',
            'maaleskalatypeEnum': 'T0',
            'maaleskalatypeNavn': 'Tetthetsskala',
            'enhetEnum': 'T',
            'enhetNavn': 'Tetthet',
            'trinn': [
                {'verdi': '1', 'beskrivelse': 'lav', 'kode': '1'},
                {'verdi': '2', 'beskrivelse': 'høy', 'kode': '2'},
            ],
        }]
        scales = build_steps_from_variabeltrinn(vt)
        self.assertEqual(len(scales), 1)
        self.assertEqual(scales[0]['maaleskalaNavn'], 'T0')
        self.assertEqual(len(scales[0]['trinn']), 2)
        self.assertEqual(scales[0]['trinn'][0]['navn'], 'lav')

    def test_description_lists_scale_headers(self):
        scales = build_steps_from_variabeltrinn(_load_no_aa_variabeltrinn())
        lines = format_steps_for_description(scales)
        joined = '\n'.join(lines)
        self.assertIn('Måleskala T1c', joined)
        self.assertIn('Måleskala D0', joined)
        # Flat concat would omit scale headers entirely
        self.assertGreaterEqual(joined.count('Måleskala '), 7)


if __name__ == '__main__':
    unittest.main()
