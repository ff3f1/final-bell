#!/usr/bin/env python3
"""Inspect Godot PCK v3/v4; optionally extract compiled code/metadata, never execute files."""
from __future__ import annotations
import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import struct

U32 = struct.Struct("<I")
HEADER = struct.Struct("<6I2Q")
SUFFIXES = {".gdc", ".remap", ".import", ".json", ".cfg", ".bin", ".binary",
            ".txt", ".svg", ".gdshader"}


def take(f, size: int) -> bytes:
    data = f.read(size)
    if len(data) != size:
        raise ValueError("Truncated PCK")
    return data


def safe_path(name: str) -> Path:
    if name.startswith("res://"):
        name = name[6:]
    parts = name.split("/")
    if not name or name.startswith(("/", "\\")) or "\\" in name or ":" in name:
        raise ValueError(f"Unsafe path: {name!r}")
    if any(part in ("", ".", "..") for part in parts):
        raise ValueError(f"Unsafe path: {name!r}")
    return Path(*parts)


def read_index(path: Path):
    with path.open("rb") as f:
        magic, fmt, major, minor, patch, flags, base, directory = HEADER.unpack(take(f, 40))
        if magic != 0x43504447 or fmt not in (3, 4):
            raise ValueError("Expected standalone Godot PCK format v3/v4")
        if flags & 1:
            raise ValueError("Encrypted index is not supported")
        length = path.stat().st_size
        if not (104 <= base <= directory <= length):
            raise ValueError("Invalid PCK offsets")
        f.seek(directory)
        count = U32.unpack(take(f, 4))[0]
        if count > 1_000_000:
            raise ValueError("Suspicious PCK entry count")
        seen, files = set(), []
        for _ in range(count):
            n = U32.unpack(take(f, 4))[0]
            if not 1 <= n <= 4096:
                raise ValueError("Invalid PCK path length")
            name = take(f, n).rstrip(b"\0").decode("utf-8")
            rel = safe_path(name)
            key = rel.as_posix().casefold()
            if key in seen:
                raise ValueError(f"Duplicate PCK path: {name}")
            seen.add(key)
            offset, size = struct.unpack("<QQ", take(f, 16))
            checksum = take(f, 16).hex()
            item_flags = U32.unpack(take(f, 4))[0]
            absolute = base + offset
            if not item_flags & 2 and not (base <= absolute <= absolute + size <= directory):
                raise ValueError(f"Out-of-bounds PCK entry: {name}")
            files.append({"path": rel.as_posix(), "offset": absolute,
                          "size": size, "md5": checksum, "flags": item_flags})
    info = {"format": fmt, "godot_version": f"{major}.{minor}.{patch}",
            "flags": flags, "file_count": count, "size_bytes": length,
            "file_base": base, "directory_offset": directory}
    return info, files


def verify(path: Path, files: list[dict]) -> list[str]:
    bad = []
    with path.open("rb") as f:
        for item in files:
            if item["flags"] & 3:
                bad.append(item["path"] + " (encrypted or removed)")
                continue
            f.seek(item["offset"])
            remaining = item["size"]
            digest = hashlib.md5()
            while remaining:
                block = f.read(min(1024 * 1024, remaining))
                if not block:
                    break
                digest.update(block)
                remaining -= len(block)
            if remaining or digest.hexdigest() != item["md5"]:
                bad.append(item["path"])
    return bad


def extract_metadata(path: Path, files: list[dict], root: Path):
    root = root.resolve()
    with path.open("rb") as f:
        for item in files:
            if item["flags"] & 3 or Path(item["path"]).suffix.lower() not in SUFFIXES:
                continue
            target = root / safe_path(item["path"])
            target.parent.mkdir(parents=True, exist_ok=True)
            if not target.parent.resolve().is_relative_to(root):
                raise ValueError("Output symlink escapes destination")
            if target.exists() or target.is_symlink():
                raise FileExistsError(f"Will not overwrite: {target}")
            f.seek(item["offset"])
            left = item["size"]
            digest = hashlib.md5()
            try:
                with target.open("xb") as out:
                    while left:
                        chunk = f.read(min(1024 * 1024, left))
                        if not chunk:
                            raise ValueError("Truncated member")
                        digest.update(chunk)
                        out.write(chunk)
                        left -= len(chunk)
                if digest.hexdigest() != item["md5"]:
                    raise ValueError("Extracted MD5 mismatch")
            except Exception:
                target.unlink(missing_ok=True)
                raise


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("pck", type=Path)
    parser.add_argument("--out", type=Path, default=Path("final_bell_pck_audit"))
    parser.add_argument("--verify", action="store_true")
    parser.add_argument("--extract-metadata", action="store_true")
    opts = parser.parse_args()
    info, files = read_index(opts.pck)
    failures = verify(opts.pck, files) if opts.verify else None
    opts.out.mkdir(parents=True, exist_ok=True)
    (opts.out / "pck_inventory.json").write_text(
        json.dumps({"header": info, "files": files, "verification_errors": failures},
                   indent=2, ensure_ascii=False), encoding="utf-8")
    kinds = Counter(Path(x["path"]).suffix.lower() for x in files)
    lines = ["# Godot PCK inventory", "", f"Godot: {info['godot_version']}",
             f"Pack format: {info['format']}", f"Files: {len(files)}",
             f"Verified MD5: {'not run' if failures is None else f'{len(files)-len(failures)}/{len(files)}'}", ""]
    lines.extend(f"- {ext}: {num}" for ext, num in kinds.most_common())
    (opts.out / "pck_inventory.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    if opts.extract_metadata:
        extract_metadata(opts.pck, files, opts.out / "extracted")
    print("\n".join(lines))
    if failures:
        raise SystemExit(f"{len(failures)} verification errors")


if __name__ == "__main__":
    main()
