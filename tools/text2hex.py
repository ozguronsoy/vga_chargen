# usage python text2mem.py -i example_text.txt
# usage python text2mem.py -i example_text.txt -o charmem.mem -random
# usage python text2mem.py -i example_text.txt -value 101101

import argparse
import random
import sys

def main():
    parser = argparse.ArgumentParser(prog='text2mem')
    parser.add_argument('-i', required=True, help='Input File')
    # Varsayılan çıkış ismini .mem yaptım
    parser.add_argument('-o', default='charmem.mem', help='Output File (.mem)')
    parser.add_argument('-random', action='store_true', help='Random value for colors')
    parser.add_argument('-value', default='000111', help='Defined color value bg(3) font(3)')
    
    args = parser.parse_args()

    try:
        with open(args.i, 'r', encoding='utf-8') as f:
            text = f.read()
    except FileNotFoundError:
        print(f"[ERROR]: cannot find {args.i}.")
        sys.exit(1)

    # 14400 karaktere tamamla veya kes. Eksik kısımlar boşluk (space) ile dolar.
    text = text[:14400].ljust(14400)
    
    results = []
    for char in text:
        # 7-bit ASCII dönüşümü
        ascii_7 = format(ord(char) & 0x7F, '07b')
        # Renk öneki (6 bit)
        prefix = "".join(random.choice("01") for _ in range(6)) if args.random else args.value
        
        # Listeye sadece saf binary string ekliyoruz (Virgül yok)
        results.append(prefix + ascii_7)

    # MEM dosyası oluşturma (VHDL Inference için)
    with open(args.o, 'w') as f:
        # Header (başlık) YOK.
        # Sadece satırları birleştirip yazıyoruz.
        f.write("\n".join(results))

    print(f"Created {args.o} successfully for VHDL inference.")

if __name__ == "__main__":
    main()