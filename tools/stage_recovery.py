#!/usr/bin/env python3
"""Stage a verified Godot PCK and a separate legacy source ZIP.

This does not decompile GDC, SCN, or CTEX; versions are kept separate.
"""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import zipfile

from pck_inspect import read_index, safe_path

METADATA = {".gdc", ".import", ".remap", ".json", ".txt", ".cfg", ".binary", ".svg"}


def stage(legacy_zip: Path, pck: Path, output: Path, full: bool = False):
    if output.exists() and any(output.iterdir()):
        raise FileExistsError(f"Output must be empty: {output}")
    output.mkdir(parents=True, exist_ok=True)
    src_root = output / "legacy-source"
    pck_root = output / "exported-pack"
    src_root.mkdir()
    pck_root.mkdir()

    with zipfile.ZipFile(legacy_zip) as archive:
        bad = archive.testzip()
        if bad:
            raise ValueError(f"Source archive CRC failed: {bad}")
        for member in archive.infolist():
            if member.is_dir():
                continue
            rel = safe_path(member.filename)
            dst = src_root / rel
            dst.parent.mkdir(parents=True, exist_ok=True)
            if dst.exists() or dst.is_symlink():
                raise FileExistsError(f"Duplicate source file: {rel}")
            with archive.open(member) as inp, dst.open("xb") as out:
                shutil.copyfileobj(inp, out)

    header, entries = read_index(pck)
    source_names = [p.relative_to(src_root).as_posix().removeprefix("final_bell/").removesuffix(".gd")
                    for p in src_root.rglob("*.gd")]
    compiled_names = [item["path"].removesuffix(".gdc")
                      for item in entries if item["path"].endswith(".gdc")]
    only_compiled = sorted(set(compiled_names) - set(source_names))

    with pck.open("rb") as archive:
        for item in entries:
            if not full and Path(item["path"]).suffix.lower() not in METADATA:
                continue
            if item["flags"] & 3:
                raise ValueError(f"Encrypted/removed entry: {item['path']}")
            dst = pck_root / safe_path(item["path"])
            dst.parent.mkdir(parents=True, exist_ok=True)
            if not dst.parent.resolve().is_relative_to(pck_root.resolve()):
                raise ValueError("Output symlink escapes destination")
            if dst.exists() or dst.is_symlink():
                raise FileExistsError(f"Duplicate PCK file: {dst}")
            archive.seek(item["offset"])
            remaining = item["size"]
            digest = hashlib.md5()
            try:
                with dst.open("xb") as out:
                    while remaining:
                        chunk = archive.read(min(1024 * 1024, remaining))
                        if not chunk:
                            raise ValueError(f"Truncated PCK entry: {item['path']}")
                        digest.update(chunk)
                        out.write(chunk)
                        remaining -= len(chunk)
                if digest.hexdigest() != item["md5"]:
                    raise ValueError(f"MD5 mismatch: {item['path']}")
            except Exception:
                dst.unlink(missing_ok=True)
                raise

    status = {
        "pck_header": header,
        "pck_entries": len(entries),
        "legacy_scripts": len(source_names),
        "compiled_scripts": len(compiled_names),
        "scripts_shared_by_path": sorted(set(source_names) & set(compiled_names)),
        "compiled_only_scripts": only_compiled,
        "source_only_scripts": sorted(set(source_names) - set(compiled_names)),
        "full_binary_export": full,
        "outstanding": ["GDC decompilation", "SCN/CTEX conversion", "Godot game test"],
    }
    (output / "RECOVERY_MANIFEST.json").write_text(
        json.dumps(status, indent=2, ensure_ascii=False), encoding="utf-8")
    rows = ["# Final Bell recovery staging", "",
            "This is not a restored playable Godot project.", "",
            f"Indexed PCK entries: {len(entries)}; Godot {header['godot_version']}",
            f"Legacy GD: {len(source_names)}; compiled GDC: {len(compiled_names)}",
            "", "## Compiled-only script paths", ""]
    rows.extend("- " + s + ".gd" for s in only_compiled)
    rows.extend(["", "## Layout", "",
                 "legacy-source/: unmodified earlier source snapshot",
                 "exported-pack/: compiled Godot resources from the real PCK",
                 "RECOVERY_MANIFEST.json: detailed comparison", "",
                 "Do not replace older source code with compiled files.",
                 "Use GDRETools to decompile the original PCK and restore source assets."])
    (output / "README.md").write_text("\n".join(rows) + "\n", encoding="utf-8")
    return status


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("legacy_zip", type=Path)
    parser.add_argument("pck", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--full", action="store_true",
                        help="extract all original compiled resources (~630 MiB)")
    args = parser.parse_args()
    result = stage(args.legacy_zip, args.pck, args.output, full=args.full)
    print(result["pck_entries"], "PCK entries staged;",
          result["compiled_scripts"], "GDC;",
          len(result["compiled_only_scripts"]), "compiled-only.")


if __name__ == "__main__":
    main()
