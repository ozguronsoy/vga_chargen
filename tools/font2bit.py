from PIL import Image, ImageDraw, ImageFont
import sys

IN_FILE     = "Monospace" 
TARGET_SIZE = (8, 8)      
FONT_SIZE   = 8           
OUT_FILE    = "font_rom.coe"

def ttf2mem(font_path, target_size, font_size, filename):
    char_width, char_height = target_size
    output_data = []

    try:
        font = ImageFont.truetype(font_path + ".ttf", font_size)
    except IOError:
        print(f"Hata: {font_path}.ttf dosyası bulunamadı!")
        sys.exit()


    for char_code in range(0, 32):
        for y in range(char_height):
            output_data.append(f"{0:0{char_width}b}")

    for char_code in range(32, 127):
        char = chr(char_code)
        img = Image.new('1', target_size, color=0)
        draw = ImageDraw.Draw(img)
        draw.text((0, 0), char, font=font, fill=1)

        for y in range(char_height):
            byte_value = 0
            for x in range(char_width):
                pixel = img.getpixel((x, y))
                if pixel == 1:
                    byte_value |= (1 << (char_width - 1 - x))

            output_data.append(f"{byte_value:0{char_width}b}")
            
    try:
        with open(filename, 'w') as f:
            f.write("memory_initialization_radix=2;\n")
            f.write("memory_initialization_vector=\n")

            for i in range(len(output_data)):
                if i == len(output_data) - 1:
                    f.write(f"{output_data[i]};")
                else:
                    f.write(f"{output_data[i]},\n")
                    
        print(f"\nBaşarıyla kaydedildi (Binary): {filename}")
        print(f"Toplam Satır Sayısı: {len(output_data)} (Beklenen: 127 * {char_height})")
        
    except Exception as e:
        print(f"Dosya yazma hatası: {e}")

if __name__ == "__main__":
    ttf2mem(IN_FILE, TARGET_SIZE, FONT_SIZE, OUT_FILE)