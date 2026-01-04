import argparse
from PIL import Image, ImageDraw, ImageFont
import sys
import os

# Settings
TARGET_SIZE = (64, 64)
FONT_SIZE   = 56

def ttf2mem(input_font, output_file, is_verbose):
    char_width, char_height = TARGET_SIZE

    # Info
    print(f"--- Font2Bit ---")
    print(f"Input: {input_font}")
    print(f"Output: {output_file}")
    print(f"Verbose: {is_verbose}")
    print(f"----------------")

    # Load Font
    try:
        font_path = input_font
        if not os.path.exists(font_path) and os.path.exists(font_path + ".ttf"):
            font_path += ".ttf"

        if os.path.exists(font_path):
            font = ImageFont.truetype(font_path, FONT_SIZE)
        else:
            print(f"WARN: Using default font.")
            font = ImageFont.load_default()
    except Exception as e:
        print(f"Font Error: {e}")
        sys.exit(1)

    try:
        with open(output_file, 'w') as f:
            if is_verbose:
                f.write(f"// Generated from {input_font}\n")
                f.write("// Format: Binary\n")

            line_count = 0

            # 0-31: Non-printable (Empty)
            for char_code in range(0, 32):
                if is_verbose:
                    f.write(f"// Code: {char_code}\n")

                for y in range(char_height):
                    f.write(f"{0:0{char_width}b}\n")
                    line_count += 1

            # 32-127: Printable Chars
            for char_code in range(32, 128):
                char = chr(char_code)

                if is_verbose:
                    safe_char = char if char.isprintable() and char != ' ' else f"Code {char_code}"
                    f.write(f"// Char: {safe_char}\n")

                img = Image.new('1', TARGET_SIZE, color=0)
                draw = ImageDraw.Draw(img)

                # Center char
                text_w = draw.textlength(char, font=font)
                x_pos = (char_width - text_w) / 2
                y_pos = -1

                draw.text((x_pos, y_pos), char, font=font, fill=1)

                # Scan pixels
                for y in range(char_height):
                    byte_value = 0
                    for x in range(char_width):
                        pixel = img.getpixel((x, y))
                        if pixel:
                            byte_value |= (1 << (char_width - 1 - x))

                    # Write bits
                    f.write(f"{byte_value:0{char_width}b}\n")
                    line_count += 1

        print(f"Done. Total lines: {line_count}")

    except Exception as e:
        print(f"Write Error: {e}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("-i", "--input", required=True, help="Input font (.ttf)")
    parser.add_argument("-o", "--output", default="font_rom.mem", help="Output file")
    parser.add_argument("-v", "--verbose", action="store_true", help="Add comments to file")

    args = parser.parse_args()

    ttf2mem(args.input, args.output, args.verbose)