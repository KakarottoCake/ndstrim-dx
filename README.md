# ndstrim

`ndstrim` is a simple utility to trim the excess padding space from Nintendo DS and DSi ROMs, reducing their file size without affecting gameplay.

It preserves the RSA certificates at the end of NTR-only ROMs to ensure features like **Download Play** continue to work properly.

---

## 🚀 Easy macOS Usage (Double-Click)

If you are on macOS (M1/M2/M3 Apple Silicon or Intel), you can trim your files with a simple
double-click — no Rust toolchain, no terminal, and nothing to install:

1. Place **[TrimAllNDS.command](TrimAllNDS.command)** in the directory containing your `.nds` files.
2. Double-click **[TrimAllNDS.command](TrimAllNDS.command)**.
3. Choose what you'd like to do:
   - **Create trimmed copies** — writes `.trim.nds` files and leaves your originals alone (default)
   - **Trim in place** — overwrites the originals, and asks you to confirm first because it cannot
     be undone
   - **Simulate** — reports how much space you'd save without changing anything

Files that aren't valid ROMs are reported and skipped, never modified. If a run is interrupted,
no half-written ROM is left behind.

The script can also be pointed at specific files from a terminal:

```bash
./TrimAllNDS.command foo.nds bar.nds
```

---

## 🛠️ CLI Usage (Rust Binary)

If you prefer building and running from the command line:

### Standard (create a `.trim.nds` copy)

```bash
ndstrim foo.nds bar.nds baz.nds
```

The original ROMs are left untouched. You can optionally provide a custom extension to use in
place of `trim.nds` by passing the `-e` flag. Ensure that the extension you provide contains no
leading dot.

### In-place

If you don't care about preserving the original ROMs, you can run:

```bash
ndstrim -i foo.nds bar.nds baz.nds
```

This will trim the files in-place, and **is irreversible**.

### Simulated

If you want to check what `ndstrim` would do — e.g. how much size would be reduced — without
making any changes, you can use:

```bash
ndstrim -s foo.nds bar.nds baz.nds
```

This option can be combined with `-i`.

### Help

Launching `ndstrim` without arguments will display a brief usage message, but you can get a more
helpful one by passing the `-h` flag.

---

## Building

Building `ndstrim` is a straightforward process that can be done using `cargo`. Ensure you have
the Rust toolchain installed first.

For a debug build, run:

```bash
cargo b
```

For a release build, which produces an optimized and stripped binary with Thin LTO, run:

```bash
cargo b --release
```

The resulting executable will be located in `target/release/ndstrim`.

---

## Detection as malware

On Windows, it might happen that Defender quarantines the prebuilt .exe as a malware. Likewise,
some VirusTotal engines may flag the binary, even if sandbox analysis shows that the file is clean.

This is a false positive, most likely triggered by the use of UPX to minify the binary's size.
If you don't trust the binary, however, you can always review the source and build `ndstrim` on
your system by following the instructions above.

---

## Credits

This program is based on an adaptation of the trimming algorithm included in [GodMode9][1].

It is a fork of [Nemris/ndstrim][2], which remains the upstream project.

---

## License

This program is licensed under the terms of the [MIT][3] license.

See [LICENSE.txt][4] for further info.


[1]:https://github.com/d0k3/GodMode9
[2]:https://github.com/Nemris/ndstrim
[3]:https://choosealicense.com/licenses/mit/
[4]:./LICENSE.txt
