# ndstrim

`ndstrim` is a simple utility to trim the excess padding space from Nintendo DS and DSi ROMs, reducing their file size without affecting gameplay. 

It preserves the RSA certificates at the end of NTR-only ROMs to ensure features like **Download Play** continue to work properly.

---

## 🚀 Easy macOS Usage (Double-Click)

If you are on macOS (M1/M2/M3 Apple Silicon or Intel), you can trim your files with a simple double-click:

1. Place **[TrimAllNDS.command](TrimAllNDS.command)** in the directory containing your `.nds` files.
2. Double-click **[TrimAllNDS.command](TrimAllNDS.command)**.
3. Choose whether you'd like to:
   - Create trimmed copies (`.trim.nds` files, keeping original files safe)
   - Trim files in-place (overwrites original files)

---

## 🛠️ CLI Usage (Rust Binary)

If you prefer building and running from the command line:

### Build
Ensure you have the Rust toolchain installed, then run:
```bash
cargo build --release
```
The optimized executable will be located in `target/release/ndstrim`.

### Commands
- **Standard (create `.trim.nds` copy)**:
  ```bash
  ndstrim game1.nds game2.nds
  ```
- **In-place (irreversibly trim original file)**:
  ```bash
  ndstrim -i game.nds
  ```
- **Simulation (check how much size would be reduced without making changes)**:
  ```bash
  ndstrim -s game.nds
  ```

---

## License

This project is licensed under the MIT License. See [LICENSE.txt](LICENSE.txt) for details.
