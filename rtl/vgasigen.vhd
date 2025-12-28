library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vgasigen is
    port(
        PX_CLK_I            : in  std_logic;
        RST_I               : in  std_logic;
        RES_SEL_I           : in  std_logic_vector(2 downto 0); -- 000:640x480, 001:800x600, 010:720p, 011:900p, 100:1080p
        FONT_SEL_I          : in  std_logic_vector(1 downto 0); -- 00: 16x16, 01: 32x32, 10: 64x64

        -- Çıkışlar
        VISIBLE_O           : out std_logic;
        VGA_HSYNC_O         : out std_logic;
        VGA_VSYNC_O         : out std_logic;       
        CHAR_PTR_O          : out unsigned(13 downto 0);
        
        -- Karakter içi piksel konumu (0-63 arası)
        PTR_PX_X_O          : out unsigned(5 downto 0);
        PTR_PX_Y_O          : out unsigned(5 downto 0)
    );
end entity;

architecture rtl of vgasigen is

    -- LOJİK SİNYALLERİ
    signal r_h_end_active : integer range 0 to 4095;
    signal r_h_beg_sync   : integer range 0 to 4095;
    signal r_h_end_sync   : integer range 0 to 4095;
    signal r_h_total      : integer range 0 to 4095;

    signal r_v_end_active : integer range 0 to 4095;
    signal r_v_beg_sync   : integer range 0 to 4095;
    signal r_v_end_sync   : integer range 0 to 4095;
    signal r_v_total      : integer range 0 to 4095;
    
    signal r_pol          : std_logic;

    -- Font Lojik Sinyalleri (Process tarafından hesaplanıp Register'a atılacak)
    signal r_shift_amt     : integer range 0 to 6;    -- 4, 5 veya 6 (2^4=16, 2^5=32...)
    signal r_chars_per_row : integer range 0 to 255;  -- Bir satıra sığan karakter sayısı

    -- Sayaçlar
    signal cnt_h : integer range 0 to 4095 := 0;
    signal cnt_v : integer range 0 to 4095 := 0;

    -- Çıkış Registerları
    signal s_hsync, s_vsync, s_visible : std_logic := '0';

    -- Pointer sinyalleri
    signal s_ptr_px_x    : unsigned(5 downto 0); 
    signal s_ptr_px_y    : unsigned(5 downto 0);
    signal s_ptr_ch_x    : unsigned(7 downto 0); 
    signal s_ptr_ch_y    : unsigned(7 downto 0); -- Dikeyde de karakter sayısı
    
    -- Hesaplanan lineer adres
    signal s_charmem_ptr : unsigned(13 downto 0);

begin

    -- TIMING & CONFIGURATION PROCESS
    -- Hem çözünürlük ayarlarını hem de seçilen fonta göre satır başı karakter sayısını ayarlar.
    process(RES_SEL_I, FONT_SEL_I)
        variable v_ha, v_hfp, v_hs, v_hbp : integer;
        variable v_va, v_vfp, v_vs, v_vbp : integer;
        variable v_pol : std_logic;
        variable v_shift : integer;
    begin
        -- 1. ADIM: Çözünürlük Parametrelerini Belirle
        -- Varsayılan (640x480)
        v_ha := 640; v_hfp := 16; v_hs := 96; v_hbp := 48;
        v_va := 480; v_vfp := 10; v_vs := 2;  v_vbp := 33;
        v_pol := '0';

        case RES_SEL_I is
            when "000" => -- 640x480
                v_ha := 640;  v_hfp := 16;  v_hs := 96;  v_hbp := 48;
                v_va := 480;  v_vfp := 10;  v_vs := 2;   v_vbp := 33;
                v_pol := '0';
            when "001" => -- 800x600
                v_ha := 800;  v_hfp := 40;  v_hs := 128; v_hbp := 88;
                v_va := 600;  v_vfp := 1;   v_vs := 4;   v_vbp := 23;
                v_pol := '1';
            when "010" => -- 1280x720 (720p)
                v_ha := 1280; v_hfp := 110; v_hs := 40;  v_hbp := 220;
                v_va := 720;  v_vfp := 5;   v_vs := 5;   v_vbp := 20;
                v_pol := '1';
            when "011" => -- 1600x900
                v_ha := 1600; v_hfp := 24;  v_hs := 80;  v_hbp := 96;
                v_va := 900;  v_vfp := 1;   v_vs := 3;   v_vbp := 96;
                v_pol := '1';
            when "100" => -- 1920x1080 (1080p)
                v_ha := 1920; v_hfp := 88;  v_hs := 44;  v_hbp := 148;
                v_va := 1080; v_vfp := 4;   v_vs := 5;   v_vbp := 36;
                v_pol := '1';
            when others => null;
        end case;

        -- 2. ADIM: Font Parametrelerini ve Shift Miktarını Belirle
        -- FONT_SEL_I -> 00:16px (2^4), 01:32px (2^5), 10:64px (2^6)
        if FONT_SEL_I = "01" then
            v_shift := 5; -- 32px
        elsif FONT_SEL_I = "10" then
            v_shift := 6; -- 64px
        else
            v_shift := 4; -- 16px (Varsayılan ve "00")
        end if;
        
        r_shift_amt <= v_shift;

        -- 3. ADIM: Chars Per Row Hesapla
        -- Donanımsal bölme işleminden kaçınmak için bunu constant variable ile yapıyoruz.
        -- Synthesis tool, v_ha ve v_shift sabit olduğu için buraya bir Divider koymaz,
        -- sabit bir değer atar (LUT optimization).
        if v_shift = 4 then
            r_chars_per_row <= v_ha / 16;
        elsif v_shift = 5 then
            r_chars_per_row <= v_ha / 32;
        else -- 6
            r_chars_per_row <= v_ha / 64;
        end if;

        -- Timing Limits
        r_h_end_active <= v_ha;
        r_h_beg_sync   <= v_ha + v_hfp;
        r_h_end_sync   <= v_ha + v_hfp + v_hs;
        r_h_total      <= v_ha + v_hfp + v_hs + v_hbp;

        r_v_end_active <= v_va;
        r_v_beg_sync   <= v_va + v_vfp;
        r_v_end_sync   <= v_va + v_vfp + v_vs;
        r_v_total      <= v_va + v_vfp + v_vs + v_vbp;
        
        r_pol <= v_pol;

    end process;

    -- COUNTER PROCESS (Değişmedi)
    process (PX_CLK_I) begin
        if rising_edge(PX_CLK_I) then
            if RST_I = '1' then
                cnt_h <= 0;
                cnt_v <= 0;
                s_hsync <= '0'; s_vsync <= '0'; s_visible <= '0';
            else
                if cnt_h < r_h_total - 1 then
                    cnt_h <= cnt_h + 1;
                else
                    cnt_h <= 0;
                    if cnt_v < r_v_total - 1 then
                        cnt_v <= cnt_v + 1;
                    else
                        cnt_v <= 0;
                    end if;
                end if;

                if (cnt_h >= r_h_beg_sync) and (cnt_h < r_h_end_sync) then
                    s_hsync <= r_pol;
                else
                    s_hsync <= not r_pol;
                end if;

                if (cnt_v >= r_v_beg_sync) and (cnt_v < r_v_end_sync) then
                    s_vsync <= r_pol;
                else
                    s_vsync <= not r_pol;
                end if;

                if (cnt_h < r_h_end_active) and (cnt_v < r_v_end_active) then
                    s_visible <= '1';
                else
                    s_visible <= '0';
                end if;
            end if;
        end if;
    end process;

    -- POINTER CALCULATION PROCESS (Düzeltildi)
    process (PX_CLK_I) 
        variable v_mask : unsigned(11 downto 0);
    begin
        if rising_edge(PX_CLK_I) then
            if RST_I = '1' then
                s_ptr_ch_x <= (others => '0'); s_ptr_ch_y <= (others => '0');
                s_ptr_px_x <= (others => '0'); s_ptr_px_y <= (others => '0');
                s_charmem_ptr <= (others => '0');
            else
                -- 1. Koordinatları Grid Index'ine dönüştür (Integer division yerine Bit Shift)
                -- Hangi karakterdeyiz? (Örn: 100. piksel / 16 = 6. karakter)
                s_ptr_ch_x <= resize(shift_right(to_unsigned(cnt_h, 12), r_shift_amt), s_ptr_ch_x'length);
                s_ptr_ch_y <= resize(shift_right(to_unsigned(cnt_v, 12), r_shift_amt), s_ptr_ch_y'length);
            
                -- 2. Karakter içi piksel konumu (Modulo işlemi yerine Maskeleme)
                -- Örn: Shift=4 (16px) ise Mask=001111 (15). 
                -- shift_left(1, 4) = 16 (10000). 1 çıkartırsak 01111 olur.
                v_mask := shift_left(to_unsigned(1, 12), r_shift_amt) - 1;
                
                s_ptr_px_x <= resize(to_unsigned(cnt_h, 12) and v_mask, s_ptr_px_x'length);
                s_ptr_px_y <= resize(to_unsigned(cnt_v, 12) and v_mask, s_ptr_px_y'length);
            
                -- 3. Memory Pointer (Lineer Adres Hesaplama)
                -- Adres = (Satır_Indeksi * Satırdaki_Karakter_Sayısı) + Sütun_Indeksi
                -- Burada bir çarpma işlemi var ama FPGA DSP blokları bunu rahatça halleder.
                s_charmem_ptr <= resize(
                    (s_ptr_ch_y * to_unsigned(r_chars_per_row, 8)) + s_ptr_ch_x, 
                    s_charmem_ptr'length
                );
            end if;
        end if;
    end process;

    -- Çıkış Atamaları
    VGA_HSYNC_O <= s_hsync;
    VGA_VSYNC_O <= s_vsync; 
    VISIBLE_O   <= s_visible;
    PTR_PX_X_O  <= s_ptr_px_x;
    PTR_PX_Y_O  <= s_ptr_px_y;
    CHAR_PTR_O  <= s_charmem_ptr;

end architecture;