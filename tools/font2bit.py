import argparse
from PIL import Image, ImageDraw, ImageFont
import sys
import os

# Ayarlar
TARGET_SIZE = (8, 8)
FONT_SIZE   = 8

def ttf2mem(input_font, output_file, is_verbose):
    char_width, char_height = TARGET_SIZE

    # Başlangıç Bilgisi (Debug için)
    mode_str = "AÇIK (Dosyaya yorumlar eklenecek)" if is_verbose else "KAPALI (Sadece 0 ve 1 yazılacak)"
    print(f"--- Font2Bit Başlatıldı ---")
    print(f"Giriş: {input_font}")
    print(f"Çıkış: {output_file}")
    print(f"Verbose Modu (-v): {mode_str}")
    print(f"---------------------------")

    # Font Yükleme
    try:
        font_path = input_font
        if not os.path.exists(font_path) and os.path.exists(font_path + ".ttf"):
            font_path += ".ttf"

        if os.path.exists(font_path):
            font = ImageFont.truetype(font_path, FONT_SIZE)
        else:
            print(f"UYARI: Font bulunamadı, varsayılan yükleniyor.")
            font = ImageFont.load_default()
    except Exception as e:
        print(f"Font Hatası: {e}")
        sys.exit(1)

    try:
        with open(output_file, 'w') as f:
            # HEADER: Sadece verbose ise yaz
            if is_verbose:
                f.write(f"// Font ROM Data - Generated from {input_font}\n")
                f.write("// Format: Binary ($readmemb)\n")

            line_count = 0

            # ---------------------------------------------------------
            # 0-31 Arası (Boş Karakterler)
            # ---------------------------------------------------------
            for char_code in range(0, 32):
                # YORUM: Sadece verbose ise yaz
                if is_verbose:
                    f.write(f"// Code: {char_code}\n")

                for y in range(char_height):
                    f.write(f"{0:0{char_width}b}\n")
                    line_count += 1

            # ---------------------------------------------------------
            # 32-127 Arası (Çizilebilir Karakterler)
            # ---------------------------------------------------------
            for char_code in range(32, 128):
                char = chr(char_code)

                # YORUM: Sadece verbose ise yaz
                if is_verbose:
                    safe_char = char if char.isprintable() and char != ' ' else f"Code {char_code}"
                    f.write(f"// Char: {safe_char}\n")

                img = Image.new('1', TARGET_SIZE, color=0)
                draw = ImageDraw.Draw(img)

                # Ortalama Hesabı
                text_w = draw.textlength(char, font=font)
                x_pos = (char_width - text_w) / 2
                y_pos = -1

                draw.text((x_pos, y_pos), char, font=font, fill=1)

                for y in range(char_height):
                    byte_value = 0
                    for x in range(char_width):
                        pixel = img.getpixel((x, y))
                        if pixel:
                            byte_value |= (1 << (char_width - 1 - x))

                    # VERİ: Her zaman yaz
                    f.write(f"{byte_value:0{char_width}b}\n")
                    line_count += 1

        print(f"TAMAMLANDI. Toplam Satır: {line_count}")

    except Exception as e:
        print(f"Dosya Yazma Hatası: {e}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("-i", "--input", required=True, help="Font dosyası (.ttf)")
    parser.add_argument("-o", "--output", default="font_rom.mem", help="Çıkış dosyası")

    # action="store_true" demek: Eğer -v yazarsan True olur, yazmazsan False (default) olur.
    parser.add_argument("-v", "--verbose", action="store_true", help="Yorum satırlarını ekle")

    args = parser.parse_args()

    ttf2mem(args.input, args.output, args.verbose)
