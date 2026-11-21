#!/usr/bin/env python3
"""Read-only inventory of a Final Bell ZIP; optionally safely extract EXE/PCK."""
from __future__ import annotations

import argparse
from collections import Counter
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path, PurePosixPath
import shutil
import stat
import zipfile

SOURCE_SUFFIXES = {'.gd', '.gdc', '.cs', '.tscn', '.scn', '.tres', '.res', '.godot', '.gdshader', '.gdextension'}
ASSET_SUFFIXES = {'.blend', '.glb', '.gltf', '.fbx', '.obj', '.png', '.jpg', '.jpeg', '.webp', '.wav', '.ogg', '.mp3', '.anim'}
PACK_SUFFIXES = {'.pck', '.exe'}
MAX_FILE_BYTES = 4 * 1024**3
MAX_TOTAL_BYTES = 12 * 1024**3


def checksum(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open('rb') as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b''):
            digest.update(chunk)
    return digest.hexdigest()


def safe_path(name: str) -> Path | None:
    """Reject Zip Slip, absolute/drive paths, Windows ADS and ambiguous separators."""
    if not name or name.startswith(('/', '\\')) or '\\' in name or '\x00' in name:
        return None
    segments = name.rstrip('/').split('/')
    if not segments or any(p in ('', '.', '..') or ':' in p for p in segments):
        return None
    return Path(*PurePosixPath(name).parts)


def scan(zip_path: Path) -> tuple[dict, list[zipfile.ZipInfo]]:
    data = {
        'source': str(zip_path.resolve()),
        'archive_size_bytes': zip_path.stat().st_size,
        'archive_sha256': checksum(zip_path),
        'scan_time_utc': datetime.now(timezone.utc).isoformat(),
        'files': [],
        'unsafe_entries': [],
        'colliding_entries': [],
        'encrypted_entries': [],
    }
    seen = set()
    safe_files = []
    with zipfile.ZipFile(zip_path) as archive:
        for item in archive.infolist():
            rel = safe_path(item.filename)
            mode = item.external_attr >> 16
            is_link = stat.S_IFMT(mode) == stat.S_IFLNK
            if rel is None or is_link:
                data['unsafe_entries'].append(item.filename)
                continue
            if item.is_dir():
                continue
            key = rel.as_posix().casefold()
            if key in seen:
                data['colliding_entries'].append(item.filename)
                continue
            seen.add(key)
            if item.flag_bits & 1:
                data['encrypted_entries'].append(item.filename)
            kind = ('project' if rel.name.lower() == 'project.godot' else
                    'source' if rel.suffix.lower() in SOURCE_SUFFIXES else
                    'asset' if rel.suffix.lower() in ASSET_SUFFIXES else
                    'export' if rel.suffix.lower() in PACK_SUFFIXES else 'other')
            data['files'].append({
                'path': rel.as_posix(), 'size_bytes': item.file_size,
                'compressed_bytes': item.compress_size,
                'kind': kind, 'crc32': f'{item.CRC:08x}',
            })
            safe_files.append(item)
    data['counts_by_kind'] = dict(Counter(x['kind'] for x in data['files']))
    data['counts_by_extension'] = dict(sorted(Counter(Path(x['path']).suffix.lower() or '[none]'
                                                    for x in data['files']).items()))
    data['uncompressed_size_bytes'] = sum(x['size_bytes'] for x in data['files'])
    data['project_paths'] = [x['path'] for x in data['files'] if x['kind'] == 'project']
    data['pack_paths'] = [x['path'] for x in data['files'] if x['kind'] == 'export']
    return data, safe_files


def extract_packs(zip_path: Path, files: list[zipfile.ZipInfo], dest: Path) -> list[dict]:
    """Extract only EXE/PCK, with size, duplicate and Zip Slip safeguards."""
    selected = [x for x in files if Path(x.filename).suffix.lower() in PACK_SUFFIXES]
    if any(x.file_size > MAX_FILE_BYTES for x in selected):
        raise ValueError('Pack exceeds per-file safety limit (4 GiB)')
    if sum(x.file_size for x in selected) > MAX_TOTAL_BYTES:
        raise ValueError('Packs exceed total safety limit (12 GiB)')
    dest.mkdir(parents=True, exist_ok=True)
    extracted = []
    with zipfile.ZipFile(zip_path) as archive:
        for info in selected:
            relative = safe_path(info.filename)
            if relative is None:
                continue
            target = dest / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            if not target.parent.resolve().is_relative_to(dest.resolve()):
                raise ValueError(f'Refusing to write through symlink: {target}')
            if target.exists() or target.is_symlink():
                raise FileExistsError(f'Refusing to overwrite {target}')
            try:
                with archive.open(info) as src, target.open('xb') as dst:
                    shutil.copyfileobj(src, dst, length=1024 * 1024)
            except Exception:
                target.unlink(missing_ok=True)
                raise
            extracted.append({'path': str(target), 'size_bytes': target.stat().st_size,
                              'sha256': checksum(target)})
    return extracted


def render_markdown(report: dict) -> str:
    lines = [
        '# Final Bell: archive inventory', '',
        f"- Source: `{report['source']}`",
        f"- ZIP size: {report['archive_size_bytes']:,} bytes",
        f"- SHA-256: `{report['archive_sha256']}`",
        f"- Files: {len(report['files'])}",
        f"- Uncompressed content: {report['uncompressed_size_bytes']:,} bytes", '',
        '## Contents by type', '',
    ]
    for kind, count in sorted(report['counts_by_kind'].items()):
        lines.append(f'- {kind}: {count}')
    lines.extend(['', '## Godot projects', ''])
    lines.extend(f"- `{p}`" for p in report['project_paths'])
    if not report['project_paths']:
        lines.append('- No project.godot found in ZIP listing (not proof that source recovery is impossible).')
    lines.extend(['', '## Exports (.pck/.exe)', ''])
    lines.extend(f"- `{p}`" for p in report['pack_paths'])
    if not report['pack_paths']:
        lines.append('- None found.')
    lines.extend(['', '## Largest files', ''])
    for entry in sorted(report['files'], key=lambda x: x['size_bytes'], reverse=True)[:20]:
        lines.append(f"- {entry['size_bytes']:,} bytes — `{entry['path']}`")
    for field, heading in [('unsafe_entries', 'Skipped unsafe paths/symlinks'),
                           ('colliding_entries', 'Skipped duplicate/case-colliding paths'),
                           ('encrypted_entries', 'Encrypted entries')]:
        lines.extend(['', f'## {heading}', ''])
        lines.extend(f'- `{p}`' for p in report[field])
        if not report[field]:
            lines.append('- None detected.')
    lines.extend(['', '## Extracted packs', ''])
    for entry in report.get('extracted_packs', []):
        lines.append(f"- `{entry['path']}` ({entry['size_bytes']:,} bytes), sha256 `{entry['sha256']}`")
    if not report.get('extracted_packs'):
        lines.append('- None; use --extract-packs to extract EXE/PCK.')
    lines.extend(['', 'Note: this is a ZIP directory listing, not a Godot execution or recovered project.'])
    return '\n'.join(lines) + '\n'


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('archive', type=Path, help='Original Final Bell.zip (never modified)')
    parser.add_argument('--output', type=Path, default=Path('final_bell_audit'), help='Report directory')
    parser.add_argument('--extract-packs', action='store_true', help='Safely extract only EXE and PCK')
    args = parser.parse_args()
    if not args.archive.is_file():
        parser.error(f'File not found: {args.archive}')
    try:
        report, members = scan(args.archive)
        args.output.mkdir(parents=True, exist_ok=True)
        if args.extract_packs:
            report['extracted_packs'] = extract_packs(args.archive, members, args.output / 'packs')
        (args.output / 'inventory.json').write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding='utf-8')
        (args.output / 'inventory.md').write_text(render_markdown(report), encoding='utf-8')
    except (OSError, ValueError, zipfile.BadZipFile, RuntimeError) as exc:
        parser.exit(2, f'Inventory failed: {exc}\n')
    print(f"Scanned {len(report['files'])} files. Report: {args.output.resolve() / 'inventory.md'}")
    print(f"Projects: {len(report['project_paths'])}; EXE/PCK: {len(report['pack_paths'])}")
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
