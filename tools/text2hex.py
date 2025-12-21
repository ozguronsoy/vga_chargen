# usage python text2mem.py -i example_text.txt
# usage python text2mem.py -i example_text.txt -o charmem.mem -random
# usage python text2mem.py -i example_text.txt -value 101101

import argparse
import random
import sys
import os

# Ayarlar
COLS = 80   # Sütun Genişliği
ROWS = 60   # Satır Sayısı

def main():
    parser = argparse.ArgumentParser(prog='text2mem')
    parser.add_argument('-i', required=True, help='Input File')
    parser.add_argument('-o', default='charmem.mem', help='Output File (.mem)')
    parser.add_argument('-random', action='store_true', help='Random value for colors')
    parser.add_argument('-value', default='000111', help='Defined color value bg(3) font(3)')

    args = parser.parse_args()

    # Dosya kontrolü
    if not os.path.exists(args.i):
        print(f"[ERROR]: cannot find {args.i}.")
        sys.exit(1)

    # 1. Adım: Bellek tamponunu (Buffer) tamamen boşluklarla doldurarak başlat
    # Böylece yazmadığımız her yer otomatik olarak boşluk (empty fill) olur.
    mem_buffer = [[' ' for _ in range(COLS)] for _ in range(ROWS)]

    # Dosyayı tek bir string akışı olarak oku
    with open(args.i, 'r', encoding='utf-8') as f:
        text_data = f.read()

    cursor_x = 0
    cursor_y = 0

    # 2. Adım: Karakterleri işle (Cursor Mantığı)
    for char in text_data:
        # Eğer hafıza dolduysa dur
        if cursor_y >= ROWS:
            break

        if char == '\n':
            # Eğer NEWLINE geldiyse:
            # Satırın geri kalanını elle doldurmaya gerek yok,
            # çünkü buffer zaten ' ' (space) ile başlatıldı.
            # Direkt alt satıra geç ve başa al.
            cursor_y += 1
            cursor_x = 0
            continue

        if char == '\r':
            # Windows satır sonlarını (\r\n) bozmamak için \r'yi yoksay
            continue

        # Normal karakter yazma işlemi
        if cursor_x < COLS:
            mem_buffer[cursor_y][cursor_x] = char
            cursor_x += 1
        else:
            # Eğer satır sonuna (80. karakter) geldiysek ve kelime bitmediyse,
            # bir alt satıra geçip oraya yazmaya devam et (Word Wrap benzeri)
            cursor_y += 1
            cursor_x = 0
            if cursor_y < ROWS: # Taşma kontrolü
                mem_buffer[cursor_y][cursor_x] = char
                cursor_x += 1

    # 3. Adım: Buffer'ı istenen formata (.mem) çevir
    results = []

    for r in range(ROWS):
        for c in range(COLS):
            char = mem_buffer[r][c]

            # 7-bit ASCII dönüşümü
            ascii_7 = format(ord(char) & 0x7F, '07b')

            # Renk öneki (6 bit)
            if args.random:
                prefix = "".join(random.choice("01") for _ in range(6))
            else:
                prefix = args.value

            # Listeye ekle (Prefix + ASCII)
            results.append(prefix + ascii_7)

    # MEM dosyası oluşturma
    try:
        with open(args.o, 'w') as f:
            f.write("\n".join(results))
        print(f"Created {args.o} successfully. (Total lines: {len(results)})")
    except IOError as e:
        print(f"[ERROR]: Could not write to file: {e}")

if __name__ == "__main__":
    main()
