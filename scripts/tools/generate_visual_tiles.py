#!/usr/bin/env python3
"""Generate minimal tile atlas PNGs for game-world visual layers.

This script uses only the Python standard library and writes deterministic
32x32-tile atlases used by TileSet resources.
"""

from __future__ import annotations

import os
import json
import math
import struct
import zlib
from pathlib import Path
from typing import Iterable


ROOT = Path(__file__).resolve().parents[2]
OUT_DIR = ROOT / "assets" / "sprites" / "tiles"
TILE_SIZE = 32


def _chunk(chunk_type: bytes, payload: bytes) -> bytes:
    crc = zlib.crc32(chunk_type)
    crc = zlib.crc32(payload, crc)
    return struct.pack("!I", len(payload)) + chunk_type + payload + struct.pack("!I", crc & 0xFFFFFFFF)


def write_png(path: Path, width: int, height: int, rgba_bytes: bytes) -> None:
    if len(rgba_bytes) != width * height * 4:
        raise ValueError("rgba buffer size mismatch")

    raw_rows = bytearray()
    stride = width * 4
    for y in range(height):
        raw_rows.append(0)  # filter type 0
        start = y * stride
        raw_rows.extend(rgba_bytes[start : start + stride])

    compressed = zlib.compress(bytes(raw_rows), level=9)
    header = struct.pack("!IIBBBBB", width, height, 8, 6, 0, 0, 0)
    png = b"\x89PNG\r\n\x1a\n" + _chunk(b"IHDR", header) + _chunk(b"IDAT", compressed) + _chunk(b"IEND", b"")
    path.write_bytes(png)


def hex_to_rgba(hex_color: str, alpha: int = 255) -> tuple[int, int, int, int]:
    color = hex_color.strip().lstrip("#")
    if len(color) != 6:
        raise ValueError(f"invalid color: {hex_color}")
    return (int(color[0:2], 16), int(color[2:4], 16), int(color[4:6], 16), alpha)


def tint(channel: int, amount: int) -> int:
    return max(0, min(255, channel + amount))


def hash_u32(x: int, y: int, seed: int) -> int:
    value = (x * 374761393 + y * 668265263 + seed * 69069) & 0xFFFFFFFF
    value ^= value >> 13
    value = (value * 1274126177) & 0xFFFFFFFF
    value ^= value >> 16
    return value & 0xFFFFFFFF


def noise_signed(x: int, y: int, seed: int) -> float:
    return (hash_u32(x, y, seed) / 2147483647.5) - 1.0


def build_ground_atlas(palette_hex: Iterable[str]) -> bytes:
    palette = [hex_to_rgba(x) for x in palette_hex]
    width = TILE_SIZE * 3
    height = TILE_SIZE
    pixels = bytearray(width * height * 4)

    for tile_index, base in enumerate(palette):
        start_x = tile_index * TILE_SIZE
        for y in range(TILE_SIZE):
            for x in range(TILE_SIZE):
                idx = ((y * width) + (start_x + x)) * 4
                light = ((x // 4) + (y // 4)) % 2 == 0
                vertical = int((0.5 - (y / float(TILE_SIZE - 1))) * 12)
                grain = int(noise_signed(x + tile_index * 41, y, 17 + tile_index * 3) * 10)
                crack = ((x * 7 + y * 11 + tile_index * 13) % 29 == 0) or ((x - y + tile_index * 3) % 37 == 0)
                delta = (12 if light else -8) + vertical + grain
                if crack:
                    delta -= 14
                if x in (0, TILE_SIZE - 1) or y in (0, TILE_SIZE - 1):
                    delta -= 18
                pixels[idx + 0] = tint(base[0], delta)
                pixels[idx + 1] = tint(base[1], delta)
                pixels[idx + 2] = tint(base[2], delta)
                pixels[idx + 3] = 255

    return bytes(pixels)


def build_ground_detail_atlas(detail_hex: str, accent_hex: str, motif: str) -> bytes:
    width = TILE_SIZE * 4
    height = TILE_SIZE
    pixels = bytearray(width * height * 4)
    detail = hex_to_rgba(detail_hex, 0)
    accent = hex_to_rgba(accent_hex, 0)

    for tile_index in range(4):
        start_x = tile_index * TILE_SIZE
        for y in range(TILE_SIZE):
            for x in range(TILE_SIZE):
                idx = ((y * width) + (start_x + x)) * 4
                alpha = 0
                color = detail
                grain = int(abs(noise_signed(x + tile_index * 31, y, 91)) * 22)

                if motif == "chapel":
                    marked = (x in (15, 16) or y in (15, 16)) and abs(x - 16) + abs(y - 16) < 11 + tile_index
                    sparkle = (x + y + tile_index) % 11 == 0
                    if marked:
                        alpha = 62 + grain
                    elif sparkle:
                        alpha = 36 + grain // 2
                        color = accent
                elif motif == "forge":
                    marked = ((x + y + tile_index) % (5 + tile_index % 2) == 0) or (y > 20 and x % 6 < 2)
                    ember = (x * 3 + y * 5 + tile_index) % 17 == 0
                    if marked:
                        alpha = 56 + grain
                    elif ember:
                        alpha = 46 + grain // 2
                        color = accent
                elif motif == "sanctum":
                    marked = abs(x - 16) == abs(y - 16) or (x + tile_index) % 9 == 0
                    frost = (x + y * 2 + tile_index) % 13 == 0
                    if marked:
                        alpha = 54 + grain
                    elif frost:
                        alpha = 38 + grain // 2
                        color = accent
                else:
                    marked = ((x * 2 - y + tile_index) % 7 == 0) or ((x + y) % 9 == tile_index)
                    void_glow = (x * 5 + y * 3 + tile_index) % 19 == 0
                    if marked:
                        alpha = 60 + grain
                    elif void_glow:
                        alpha = 44 + grain // 2
                        color = accent

                brush = (x - 16) * (x - 16) + (y - 16) * (y - 16)
                if brush < 160 and alpha > 0:
                    alpha = min(255, alpha + (160 - brush) // 8)

                pixels[idx + 0] = color[0]
                pixels[idx + 1] = color[1]
                pixels[idx + 2] = color[2]
                pixels[idx + 3] = alpha

    return bytes(pixels)


def build_door_atlas(unlocked_hex: str, locked_hex: str) -> bytes:
    width = TILE_SIZE * 2
    height = TILE_SIZE
    pixels = bytearray(width * height * 4)
    colors = [hex_to_rgba(unlocked_hex), hex_to_rgba(locked_hex)]

    for tile_index, base in enumerate(colors):
        start_x = tile_index * TILE_SIZE
        for y in range(TILE_SIZE):
            for x in range(TILE_SIZE):
                idx = ((y * width) + (start_x + x)) * 4
                stripe = (x + y) % 6 == 0
                panel = abs(x - 16) < 10 and abs(y - 16) < 10
                rivet = (x in (6, 25) and y in (6, 25))
                rune = tile_index == 1 and ((x - 16) * (x - 16) + (y - 16) * (y - 16) in range(32, 40))
                grain = int(noise_signed(x + tile_index * 57, y, 151) * 8)
                delta = (14 if stripe else -5) + grain
                if panel:
                    delta += 8
                if rivet:
                    delta += 18
                if rune:
                    delta += 26
                if x in (0, TILE_SIZE - 1) or y in (0, TILE_SIZE - 1):
                    delta -= 22
                pixels[idx + 0] = tint(base[0], delta)
                pixels[idx + 1] = tint(base[1], delta)
                pixels[idx + 2] = tint(base[2], delta)
                pixels[idx + 3] = 255

    return bytes(pixels)


def build_hazard_atlas(pattern_steps: list[int], edge_alpha: int) -> bytes:
    width = TILE_SIZE * 3
    height = TILE_SIZE
    pixels = bytearray(width * height * 4)
    base_rgb = (255, 255, 255)

    for tile_index, step in enumerate(pattern_steps):
        start_x = tile_index * TILE_SIZE
        for y in range(TILE_SIZE):
            for x in range(TILE_SIZE):
                idx = ((y * width) + (start_x + x)) * 4
                edge = x in (0, TILE_SIZE - 1) or y in (0, TILE_SIZE - 1)
                swirl = int(abs(math.sin((x + tile_index * 5) * 0.34) + math.cos((y - tile_index * 3) * 0.27)) * 10)
                marked = ((x + y + swirl) % step == 0) or ((x - y + swirl) % (step + 1) == 0)
                grain = int(abs(noise_signed(x + tile_index * 19, y, 211)) * 14)
                alpha = 0
                if edge:
                    alpha = min(255, edge_alpha + grain)
                elif marked:
                    alpha = max(42, edge_alpha - 18 + grain)
                pixels[idx + 0] = base_rgb[0]
                pixels[idx + 1] = base_rgb[1]
                pixels[idx + 2] = base_rgb[2]
                pixels[idx + 3] = alpha

    return bytes(pixels)


def build_ambient_fx_atlas(glow_hex: str, accent_hex: str, pulse_step: int) -> bytes:
    width = TILE_SIZE * 4
    height = TILE_SIZE
    pixels = bytearray(width * height * 4)
    glow = hex_to_rgba(glow_hex, 0)
    accent = hex_to_rgba(accent_hex, 0)

    for tile_index in range(4):
        start_x = tile_index * TILE_SIZE
        step = max(3, pulse_step + tile_index)
        for y in range(TILE_SIZE):
            for x in range(TILE_SIZE):
                idx = ((y * width) + (start_x + x)) * 4
                alpha = 0
                color = glow

                ring = abs(x - 16) + abs(y - 16)
                major = ring % step == 0
                minor = (x * 3 + y * 5 + tile_index) % (step + 2) == 0
                spark = (x + y * 2 + tile_index * 3) % (step + 5) == 0
                halo = max(0, 120 - ((x - 16) * (x - 16) + (y - 16) * (y - 16))) // 6
                drift = int(abs(math.sin((x + tile_index * 2) * 0.22) + math.cos((y - tile_index) * 0.18)) * 8)

                if major:
                    alpha = 56 + halo + drift
                elif minor:
                    alpha = 36 + halo // 2 + drift
                elif spark:
                    alpha = 46 + halo // 2 + drift
                    color = accent

                pixels[idx + 0] = color[0]
                pixels[idx + 1] = color[1]
                pixels[idx + 2] = color[2]
                pixels[idx + 3] = alpha

    return bytes(pixels)


def write_atlas_manifest(entries: list[dict[str, object]]) -> None:
    manifest = {
        "style": "handdrawn_v1",
        "tile_size": TILE_SIZE,
        "atlas_count": len(entries),
        "atlases": entries,
    }
    manifest_path = OUT_DIR / "atlas_manifest.json"
    manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main() -> None:
    os.makedirs(OUT_DIR, exist_ok=True)

    chapter_palettes = {
        "ground_ch1.png": ["#4E5A64", "#72808A", "#A6B1B7"],
        "ground_ch2.png": ["#5A2E20", "#8C3E26", "#D96A2B"],
        "ground_ch3.png": ["#A6C8D8", "#DDEAF1", "#7CA5BD"],
        "ground_ch4.png": ["#1E1B2E", "#3A2C5A", "#6A4EA1"],
    }
    chapter_doors = {
        "doors_ch1.png": ("#39B75C", "#D84A4A"),
        "doors_ch2.png": ("#D28E35", "#B13A2F"),
        "doors_ch3.png": ("#72AFCF", "#3E6F93"),
        "doors_ch4.png": ("#8B6ED1", "#D15CA9"),
    }
    chapter_hazards = {
        "hazard_overlay_ch1.png": ([5, 4, 3], 66),
        "hazard_overlay_ch2.png": ([6, 5, 4], 72),
        "hazard_overlay_ch3.png": ([4, 3, 5], 62),
        "hazard_overlay_ch4.png": ([3, 4, 2], 78),
    }
    chapter_ambient_fx = {
        "ambient_fx_ch1.png": ("#F4EBC6", "#FFF4D0", 5),
        "ambient_fx_ch2.png": ("#FFAA62", "#FFE2BF", 4),
        "ambient_fx_ch3.png": ("#D5F4FF", "#FFFFFF", 6),
        "ambient_fx_ch4.png": ("#D09DFF", "#FFB4F3", 4),
    }
    chapter_ground_details = {
        "ground_detail_ch1.png": ("#D8D2C3", "#F1E8B8", "chapel"),
        "ground_detail_ch2.png": ("#4A2219", "#F3A34D", "forge"),
        "ground_detail_ch3.png": ("#E8F6FF", "#A8E1FF", "sanctum"),
        "ground_detail_ch4.png": ("#8F7BCE", "#FF8AE1", "void"),
    }
    manifest_entries: list[dict[str, object]] = []

    for filename, palette in chapter_palettes.items():
        atlas = build_ground_atlas(palette)
        write_png(OUT_DIR / filename, TILE_SIZE * 3, TILE_SIZE, atlas)
        manifest_entries.append({"file": filename, "layer": "ground", "variants": 3, "profile": "chapter"})

    for filename, detail_profile in chapter_ground_details.items():
        write_png(
            OUT_DIR / filename,
            TILE_SIZE * 4,
            TILE_SIZE,
            build_ground_detail_atlas(detail_profile[0], detail_profile[1], detail_profile[2]),
        )
        manifest_entries.append({"file": filename, "layer": "ground_detail", "variants": 4, "profile": str(detail_profile[2])})

    for filename, colors in chapter_doors.items():
        write_png(OUT_DIR / filename, TILE_SIZE * 2, TILE_SIZE, build_door_atlas(colors[0], colors[1]))
        manifest_entries.append({"file": filename, "layer": "doors", "variants": 2, "profile": "chapter"})

    for filename, hazard_profile in chapter_hazards.items():
        pattern_steps = hazard_profile[0]
        edge_alpha = hazard_profile[1]
        write_png(OUT_DIR / filename, TILE_SIZE * 3, TILE_SIZE, build_hazard_atlas(pattern_steps, edge_alpha))
        manifest_entries.append({"file": filename, "layer": "hazard", "variants": 3, "profile": "chapter"})

    for filename, fx_profile in chapter_ambient_fx.items():
        write_png(OUT_DIR / filename, TILE_SIZE * 4, TILE_SIZE, build_ambient_fx_atlas(fx_profile[0], fx_profile[1], int(fx_profile[2])))
        manifest_entries.append({"file": filename, "layer": "ambient_fx", "variants": 4, "profile": "chapter"})

    write_png(OUT_DIR / "doors.png", TILE_SIZE * 2, TILE_SIZE, build_door_atlas("#39B75C", "#D84A4A"))
    write_png(OUT_DIR / "hazard_overlay.png", TILE_SIZE * 3, TILE_SIZE, build_hazard_atlas([5, 4, 3], 66))
    manifest_entries.append({"file": "doors.png", "layer": "doors", "variants": 2, "profile": "compat"})
    manifest_entries.append({"file": "hazard_overlay.png", "layer": "hazard", "variants": 3, "profile": "compat"})
    write_atlas_manifest(manifest_entries)
    print(f"Generated tile atlases in: {OUT_DIR}")


if __name__ == "__main__":
    main()
