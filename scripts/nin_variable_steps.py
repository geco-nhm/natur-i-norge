#!/usr/bin/env python3
"""Pure helpers for NiN variable måleskala / trinn grouping (no network deps)."""

from __future__ import annotations


def build_steps_from_variabeltrinn(variabeltrinn):
    """Preserve each måleskala as its own group instead of flattening all trinn.

    Returns a list of scale objects:
      [{maaleskalaNavn, maaleskalatypeEnum, maaleskalatypeNavn, enhetEnum, enhetNavn, trinn: [...]}, ...]
    or None when there are no steps.
    """
    if not variabeltrinn:
        return None

    scales = []
    for vt in variabeltrinn:
        trinn_list = []
        for tr in vt.get('trinn') or []:
            trinn_list.append({
                'verdi': tr.get('verdi'),
                'navn': tr.get('beskrivelse'),
                'kode': tr.get('kode'),
            })
        if not trinn_list:
            continue
        scales.append({
            'maaleskalaNavn': vt.get('maaleskalaNavn'),
            'maaleskalatypeEnum': vt.get('maaleskalatypeEnum'),
            'maaleskalatypeNavn': vt.get('maaleskalatypeNavn'),
            'enhetEnum': vt.get('enhetEnum'),
            'enhetNavn': vt.get('enhetNavn'),
            'trinn': trinn_list,
        })
    return scales or None


def format_steps_for_description(scales):
    """Render grouped scales into the synthesized description Trinn section."""
    if not scales:
        return []

    # Legacy flat list support (pre-grouping scrapes)
    if scales and isinstance(scales[0], dict) and 'trinn' not in scales[0] and 'verdi' in scales[0]:
        lines = ['\nTrinn:']
        for s in scales:
            lines.append(f"- {s.get('verdi')}: {s.get('navn')}")
        return lines

    lines = ['\nTrinn:']
    for scale in scales:
        name = scale.get('maaleskalaNavn') or scale.get('maaleskalatypeEnum') or 'Ukjent'
        type_name = scale.get('maaleskalatypeNavn')
        unit = scale.get('enhetNavn')
        header_bits = [f"Måleskala {name}"]
        if type_name:
            header_bits.append(type_name)
        if unit:
            header_bits.append(f"enhet: {unit}")
        lines.append('')
        lines.append(f"{' — '.join(header_bits)}:")
        for s in scale.get('trinn') or []:
            lines.append(f"- {s.get('verdi')}: {s.get('navn')}")
    return lines
