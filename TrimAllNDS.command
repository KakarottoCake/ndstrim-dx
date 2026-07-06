#!/usr/bin/env python3
import os
import sys
import struct
import shutil

def crc16(data: bytes) -> int:
    crc = 0xFFFF
    for byte in data:
        crc ^= byte
        for _ in range(8):
            carry = (crc & 1) > 0
            crc >>= 1
            if carry:
                crc ^= 0xA001
    return crc

def trim_nds_file(filepath: str, inplace: bool) -> bool:
    try:
        with open(filepath, "rb") as f:
            # Read first 532 bytes of the header to parse all necessary fields
            header_data = f.read(532)
            if len(header_data) < 352:
                print(f"'{os.path.basename(filepath)}': Invalid header (too short)")
                return False

            # Verify logo and header CRC
            logo = header_data[192:348]
            if crc16(logo) != 0xCF56:
                print(f"'{os.path.basename(filepath)}': Invalid Nintendo logo checksum")
                return False

            header_crc = struct.unpack("<H", header_data[350:352])[0]
            computed_header_crc = crc16(header_data[:350])
            if header_crc != computed_header_crc:
                print(f"'{os.path.basename(filepath)}': Invalid header checksum")
                return False

            # Read unitcode to determine if it is NTR-only or TWL (DSi)
            unitcode = header_data[18]
            is_ntr_only = (unitcode == 0x00)

            # Get file size
            f.seek(0, os.SEEK_END)
            file_size = f.tell()

            if is_ntr_only:
                trimmed_size = struct.unpack("<I", header_data[128:132])[0]
                # Check for RSA certificate (Download Play support) at the end of the NTR rom size
                if file_size > trimmed_size:
                    f.seek(trimmed_size)
                    cert_magic = f.read(2)
                    if cert_magic == b"ac":
                        trimmed_size += 0x88
            else:
                if len(header_data) < 532:
                    print(f"'{os.path.basename(filepath)}': Invalid DSi header (too short)")
                    return False
                trimmed_size = struct.unpack("<I", header_data[528:532])[0]

            if file_size <= trimmed_size:
                print(f"'{os.path.basename(filepath)}': Already trimmed")
                return False

            # Perform trimming
            filename = os.path.basename(filepath)
            if inplace:
                f.close()
                with open(filepath, "r+b") as wf:
                    wf.truncate(trimmed_size)
                print(f"'{filename}': Trimmed in-place. Size reduced from {file_size} to {trimmed_size} bytes.")
            else:
                # Create a new file with the extension '.trim.nds'
                base, _ = os.path.splitext(filepath)
                dest_path = base + ".trim.nds"
                dest_filename = os.path.basename(dest_path)
                
                f.seek(0)
                with open(dest_path, "wb") as wf:
                    shutil.copyfileobj(f, wf, length=1024*1024)
                
                # Truncate the copy
                with open(dest_path, "r+b") as wf:
                    wf.truncate(trimmed_size)
                
                print(f"'{filename}' -> '{dest_filename}': Size reduced from {file_size} to {trimmed_size} bytes.")
            return True

    except Exception as e:
        print(f"Error processing '{os.path.basename(filepath)}': {e}")
        return False

def main():
    # Set the working directory to the directory containing this script
    script_dir = os.path.dirname(os.path.realpath(sys.argv[0]))
    os.chdir(script_dir)

    print("==================================================")
    print("           Nintendo DS ROM Trimmer               ")
    print("==================================================")
    print(f"Scanning directory: {script_dir}\n")

    # Find all .nds files except already trimmed output copies (*.trim.nds)
    nds_files = [f for f in os.listdir(".") if f.lower().endswith(".nds") and not f.lower().endswith(".trim.nds")]

    if not nds_files:
        print("No .nds files found in the directory.")
        input("\nPress Enter to exit...")
        return

    print("Found files:")
    for idx, f in enumerate(nds_files, 1):
        print(f"  {idx}. {f}")
    
    print("\nHow would you like to trim these files?")
    print("  1. Create trimmed copies (keeps original files, creates *.trim.nds) [Default]")
    print("  2. Trim in-place (overwrites original files - irreversible!)")
    
    choice = input("\nChoose option (1 or 2): ").strip()
    inplace = (choice == "2")

    print("\nStarting trimming process...")
    print("--------------------------------------------------")
    
    success_count = 0
    for filepath in nds_files:
        if trim_nds_file(filepath, inplace):
            success_count += 1

    print("--------------------------------------------------")
    print(f"Finished! Successfully trimmed {success_count} of {len(nds_files)} files.")
    input("\nPress Enter to exit...")

if __name__ == "__main__":
    main()
