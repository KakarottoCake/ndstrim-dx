#!/usr/bin/env python3
"""Trim the padding from Nintendo DS(i) ROMs, with no toolchain required.

Double-click this file on macOS to process every `.nds` ROM sitting in the
same folder, or run it from a terminal against specific files:

    ./TrimAllNDS.command foo.nds bar.nds

This is a dependency-free companion to the `ndstrim` binary and implements the
same algorithm: the ROM's real length comes from its header, and NTR-only ROMs
keep the trailing RSA certificate so that Download Play keeps working.
"""

from __future__ import annotations

import os
import struct
import sys

# Header layout. Offsets are into the raw header; see src/nds.rs for the
# equivalent struct definition.
HEADER_READ_SIZE = 532  # Enough to reach ntr_twl_rom_size.
NTR_HEADER_SIZE = 0x15E  # Number of leading bytes covered by the header CRC.
UNITCODE_OFF = 0x12
NTR_ROM_SIZE_OFF = 0x80
LOGO_OFF = 0xC0
LOGO_END = 0x15C
HEADER_CRC_OFF = 0x15E
NTR_TWL_ROM_SIZE_OFF = 0x210

LOGO_CRC = 0xCF56  # CRC-16 of the Nintendo logo in a valid header.
RSA_MAGIC = b"ac"  # Marks an RSA cert, found just past the ROM data.
RSA_SIZE = 0x88  # Size of the RSA cert that enables Download Play.

COPY_CHUNK = 1024 * 1024


def _build_crc16_table() -> list[int]:
    """Precomputes a byte-at-a-time table for CRC-16/MODBUS."""
    table = []
    for byte in range(256):
        crc = byte
        for _ in range(8):
            crc = (crc >> 1) ^ 0xA001 if crc & 1 else crc >> 1
        table.append(crc)
    return table


_CRC16_TABLE = _build_crc16_table()


def crc16(data: bytes) -> int:
    """Computes CRC-16/MODBUS, matching the `crc` crate's CRC_16_MODBUS."""
    crc = 0xFFFF
    for byte in data:
        crc = (crc >> 8) ^ _CRC16_TABLE[(crc ^ byte) & 0xFF]
    return crc


class RomError(Exception):
    """A file that cannot, or need not, be trimmed."""


def human(size: float) -> str:
    """Formats a byte count for display."""
    for unit in ("B", "KiB", "MiB"):
        if size < 1024:
            return f"{size:.0f} {unit}" if unit == "B" else f"{size:.1f} {unit}"
        size /= 1024
    return f"{size:.1f} GiB"


def dest_path(path: str) -> str:
    """Returns the name of the trimmed copy of `path`."""
    return os.path.splitext(path)[0] + ".trim.nds"


def _read_header(f) -> bytes:
    """Reads a header from an open ROM and verifies it."""
    header = f.read(HEADER_READ_SIZE)
    if len(header) < HEADER_CRC_OFF + 2:
        raise RomError("invalid header (file too short)")

    if crc16(header[LOGO_OFF:LOGO_END]) != LOGO_CRC:
        raise RomError("invalid Nintendo logo checksum")

    stored_crc = struct.unpack_from("<H", header, HEADER_CRC_OFF)[0]
    if stored_crc != crc16(header[:NTR_HEADER_SIZE]):
        raise RomError("invalid header checksum")

    return header


def _trimmed_size(f, header: bytes, file_size: int) -> int:
    """Computes the size of the ROM contents described by `header`."""
    if header[UNITCODE_OFF] != 0x00:  # A TWL (DSi) ROM.
        if len(header) < NTR_TWL_ROM_SIZE_OFF + 4:
            raise RomError("invalid DSi header (file too short)")
        return struct.unpack_from("<I", header, NTR_TWL_ROM_SIZE_OFF)[0]

    size = struct.unpack_from("<I", header, NTR_ROM_SIZE_OFF)[0]

    # NTR-only ROMs may carry an RSA cert past the ROM data; keeping it
    # preserves Download Play.
    if file_size > size:
        f.seek(size)
        if f.read(2) == RSA_MAGIC:
            size += RSA_SIZE

    return size


def _copy_prefix(src, path: str, length: int) -> None:
    """Writes the first `length` bytes of `src` to `path`.

    The copy lands on a temporary file that is renamed into place only once it
    is complete, so an interrupted run can never leave behind a partial ROM
    that looks valid.
    """
    tmp_path = path + ".partial"
    try:
        with open(tmp_path, "wb") as out:
            remaining = length
            while remaining > 0:
                chunk = src.read(min(remaining, COPY_CHUNK))
                if not chunk:
                    raise RomError("unexpected end of file while copying")
                out.write(chunk)
                remaining -= len(chunk)
        os.replace(tmp_path, path)
    except BaseException:
        # Clean up on any failure, including Ctrl-C.
        try:
            os.unlink(tmp_path)
        except OSError:
            pass
        raise


def trim_rom(path: str, mode: str) -> tuple[int, int]:
    """Trims the ROM at `path` according to `mode`.

    `mode` is one of "copy", "inplace" or "simulate". Returns the original and
    trimmed sizes, and raises `RomError` if `path` is not a trimmable ROM.
    """
    with open(path, "rb") as f:
        file_size = os.fstat(f.fileno()).st_size
        header = _read_header(f)
        size = _trimmed_size(f, header, file_size)

        if file_size <= size:
            raise RomError("already trimmed")

        if mode == "copy":
            f.seek(0)
            _copy_prefix(f, dest_path(path), size)

    if mode == "inplace":
        with open(path, "r+b") as f:
            f.truncate(size)

    return file_size, size


def gather_roms(paths: list[str]) -> list[str]:
    """Returns the ROMs to process, either those named or those alongside us."""
    if paths:
        return paths

    names = [
        name
        for name in os.listdir(".")
        if name.lower().endswith(".nds")
        and not name.lower().endswith(".trim.nds")
        and os.path.isfile(name)
    ]
    return sorted(names, key=str.lower)


def choose_mode() -> str | None:
    """Prompts for a trimming mode, returning None if the user backs out."""
    print("\nHow would you like to trim these files?")
    print("  1. Create trimmed copies  (keeps originals, writes *.trim.nds)  [default]")
    print("  2. Trim in place          (overwrites originals - irreversible!)")
    print("  3. Simulate               (report savings, change nothing)")

    try:
        choice = input("\nChoose option [1]: ").strip()
    except EOFError:
        choice = ""

    if choice == "3":
        return "simulate"
    if choice != "2":
        return "copy"

    print("\n  WARNING: this overwrites your ROMs in place and cannot be undone.")
    try:
        if input('  Type "yes" to continue: ').strip().lower() != "yes":
            return None
    except EOFError:
        return None

    return "inplace"


def main() -> int:
    paths = sys.argv[1:]
    if not paths:
        # Finder launches .command files from the user's home directory, so
        # move to wherever this script actually lives before scanning.
        os.chdir(os.path.dirname(os.path.realpath(sys.argv[0])))

    print("==================================================")
    print("             Nintendo DS ROM Trimmer              ")
    print("==================================================")
    if not paths:
        print(f"Scanning directory: {os.getcwd()}\n")

    roms = gather_roms(paths)
    if not roms:
        print("No .nds files found in the directory.")
        finish()
        return 1

    print("Found files:")
    for index, name in enumerate(roms, 1):
        print(f"  {index}. {os.path.basename(name)}")

    mode = choose_mode()
    if mode is None:
        print("\nAborted; nothing was changed.")
        finish()
        return 1

    print("\nStarting trimming process..." if mode != "simulate" else "\nSimulating...")
    print("--------------------------------------------------")

    trimmed = 0
    saved = 0
    total = len(roms)
    for index, path in enumerate(roms, 1):
        label = f"  [{index}/{total}] {os.path.basename(path)}"
        try:
            file_size, size = trim_rom(path, mode)
        except RomError as e:
            print(f"{label}: skipped, {e}")
        except OSError as e:
            print(f"{label}: error, {e.strerror or e}")
        else:
            trimmed += 1
            saved += file_size - size
            print(
                f"{label}: {human(file_size)} -> {human(size)}"
                f" (saves {human(file_size - size)})"
            )

    print("--------------------------------------------------")
    verb = "Would trim" if mode == "simulate" else "Trimmed"
    print(f"Finished! {verb} {trimmed} of {total} files, {human(saved)} saved.")

    finish()
    return 0


def finish() -> None:
    """Keeps the Terminal window open when the script was double-clicked."""
    if not sys.argv[1:] and sys.stdin.isatty():
        try:
            input("\nPress Enter to exit...")
        except EOFError:
            pass


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        print("\nInterrupted; nothing was left half-written.")
        sys.exit(130)
