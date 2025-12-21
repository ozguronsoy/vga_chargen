library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-- Dosya okuma kütüphanelerini ekliyoruz
use std.textio.all;             
use ieee.std_logic_textio.all; 

entity asciilut is
    generic(
        -- Varsayılan font dosyası yolu (Gerekirse değiştirebilirsin)
        c_font_file : string := "font.mem" 
    );
    port(
        clk_i       : in std_logic;
        rst_i       : in std_logic;
        ascii_dat_i : in std_logic_vector(6 downto 0); -- Hangi harf?
        ascii_col_i : in integer range 0 to 7;         -- Hangi sütun?
        ascii_raw_i : in integer range 0 to 7;         -- Hangi satır?
        px_dat_o    : out std_logic
    );
end entity;

architecture rtl of asciilut is

    -- Bellek Boyut Ayarları
    constant c_ascii_table_max    : integer := 127;
    constant c_ascii_bitmap_depth : integer := 8; -- Her karakter 8 satır
    
    -- Toplam satır sayısı: 128 karakter * 8 satır = 1024 satır
    constant c_total_depth : integer := (c_ascii_table_max + 1) * c_ascii_bitmap_depth;
    
    -- Bellek Tipi (8 bit genişlik çünkü font 8x8)
    type t_asciilut is array (0 to c_total_depth - 1) of std_logic_vector(7 downto 0);

    -- :::::::::::::: DOSYA OKUMA FONKSİYONU ::::::::::::::
    impure function InitFontFromFile (FileName : in string) return t_asciilut is
        file RamFile : text open read_mode is FileName;
        variable RamFileLine : line;
        variable RAM : t_asciilut;
        variable temp_vec : std_logic_vector(7 downto 0);
    begin
        for i in 0 to c_total_depth - 1 loop
            if not endfile(RamFile) then
                readline(RamFile, RamFileLine);
                read(RamFileLine, temp_vec);
                RAM(i) := temp_vec;
            else
                -- Dosya biterse kalanları 0 doldur
                RAM(i) := (others => '0'); 
            end if;
        end loop;
        return RAM;
    end function;
    -- ::::::::::::::::::::::::::::::::::::::::::::::::::::

    -- Belleği dosyadan init et (Eskiden others => 0 idi)
    signal s_asciilut : t_asciilut := InitFontFromFile(c_font_file);

    signal s_ascii_table_ptr : integer range 0 to c_total_depth - 1 := 0;
    signal s_read_data : std_logic_vector(7 downto 0) := (others => '0');

begin

    P_SEQ_PROC : process (clk_i) is 
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                s_ascii_table_ptr <= 0;
            else
                -- FF1 : Pointer Hesabı
                -- (ASCII Kodu * 8) + İlgili Satır
                s_ascii_table_ptr <= (to_integer(unsigned(ascii_dat_i)) * c_ascii_bitmap_depth) + ascii_raw_i;
                
                -- FF2: Tablodan Oku (Bu satır tüm 8 biti verir: örn "00111100")
                s_read_data <= s_asciilut(s_ascii_table_ptr);
            end if;
        end if;
    end process;

    -- Çıkışa sadece istenen sütundaki biti ver (MUX yapısı)
    -- ascii_col_i 0 ise 0. biti, 7 ise 7. biti seçer.
    -- (Not: Font çizim yönüne göre 7-index veya index sıralaması değişebilir, 
    -- ekranda ters görürsen burayı "7 - ascii_col_i" yapabilirsin)
    px_dat_o <= s_read_data(ascii_col_i);

end architecture;