library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vgasigen is
    port(
        PX_CLK_I            : in  std_logic;
        RST_I               : in  std_logic;
        RES_SEL_I           : in  std_logic_vector(2 downto 0);
        FONT_SEL_I          : in  std_logic_vector(1 downto 0);

        VISIBLE_O           : out std_logic;
        VGA_HSYNC_O         : out std_logic;
        VGA_VSYNC_O         : out std_logic;       
        CHAR_PTR_O          : out unsigned(13 downto 0);
        
        PTR_PX_X_O          : out unsigned(5 downto 0);
        PTR_PX_Y_O          : out unsigned(5 downto 0)
    );
end entity;

architecture rtl of vgasigen is

    -- Timing sinyalleri
    signal r_h_end_active : integer range 0 to 4095;
    signal r_h_beg_sync   : integer range 0 to 512;
    signal r_h_end_sync   : integer range 0 to 512;
    signal r_h_total      : integer range 0 to 512;

    signal r_v_end_active : integer range 0 to 4095;
    signal r_v_beg_sync   : integer range 0 to 512;
    signal r_v_end_sync   : integer range 0 to 512;
    signal r_v_total      : integer range 0 to 512;
    
    signal r_pol          : std_logic;

    -- Font Konfigürasyon
    signal r_shift_amt     : integer range 0 to 6;
    signal r_chars_per_row : integer range 0 to 255;

    -- Sayaçlar
    signal cnt_h : integer range 0 to 4095 := 0;
    signal cnt_v : integer range 0 to 4095 := 0;

    -- Pipeline Aşamaları (SYNC Sinyalleri için)
    -- Stage 0: Ham Hesaplama
    signal s_hsync_s0, s_vsync_s0, s_visible_s0 : std_logic;
    -- Stage 1: Gecikme 1 (Index hesabı sırasında)
    signal s_hsync_s1, s_vsync_s1, s_visible_s1 : std_logic;
    -- Stage 2: Gecikme 2 (Çarpma işlemi sırasında)
    signal s_hsync_s2, s_vsync_s2, s_visible_s2 : std_logic;

    -- Adres Hesaplama Sinyalleri
    signal s_ptr_px_x      : unsigned(5 downto 0); 
    signal s_ptr_px_x_d1   : unsigned(5 downto 0); -- Pipeline için gecikmiş versiyon
    signal s_ptr_px_x_d2   : unsigned(5 downto 0); -- Çıkışa gidecek tam senkron versiyon
    
    signal s_ptr_px_y      : unsigned(5 downto 0);
    signal s_ptr_px_y_d1   : unsigned(5 downto 0);
    signal s_ptr_px_y_d2   : unsigned(5 downto 0);

    signal s_ptr_ch_x      : unsigned(7 downto 0); 
    signal s_ptr_ch_x_d1   : unsigned(7 downto 0); -- Toplama işlemi için bekletilen X indeksi

    signal s_ptr_ch_y      : unsigned(7 downto 0); 
    
    signal s_multvalue     : unsigned(15 downto 0);
    signal s_charmem_ptr   : unsigned(13 downto 0);

begin

    -- CONFIGURATION PROCESS
    -- Latch oluşmaması için varsayılan değerler en başta atanır.
    process(RES_SEL_I, FONT_SEL_I)
        variable v_ha, v_hfp, v_hs, v_hbp : integer;
        variable v_va, v_vfp, v_vs, v_vbp : integer;
        variable v_pol : std_logic;
        variable v_shift : integer;
    begin
        -- Varsayılan (640x480)
        v_ha := 640; v_hfp := 16; v_hs := 96; v_hbp := 48;
        v_va := 480; v_vfp := 10; v_vs := 2;  v_vbp := 33;
        v_pol := '0';

        case RES_SEL_I is
            when "001" => -- 800x600
                v_ha := 800;  v_hfp := 40;  v_hs := 128; v_hbp := 88;
                v_va := 600;  v_vfp := 1;   v_vs := 4;   v_vbp := 23;
                v_pol := '1';
            when "010" => -- 1280x720
                v_ha := 1280; v_hfp := 110; v_hs := 40;  v_hbp := 220;
                v_va := 720;  v_vfp := 5;   v_vs := 5;   v_vbp := 20;
                v_pol := '1';
            when "011" => -- 1600x900
                v_ha := 1600; v_hfp := 24;  v_hs := 80;  v_hbp := 96;
                v_va := 900;  v_vfp := 1;   v_vs := 3;   v_vbp := 96;
                v_pol := '1';
            when "100" => -- 1920x1080
                v_ha := 1920; v_hfp := 88;  v_hs := 44;  v_hbp := 148;
                v_va := 1080; v_vfp := 4;   v_vs := 5;   v_vbp := 36;
                v_pol := '1';
            when others => null;
        end case;

        if FONT_SEL_I = "01" then v_shift := 5;
        elsif FONT_SEL_I = "10" then v_shift := 6;
        else v_shift := 4; end if;
        
        r_shift_amt <= v_shift;

        if v_shift = 4 then r_chars_per_row <= v_ha / 16;
        elsif v_shift = 5 then r_chars_per_row <= v_ha / 32;
        else r_chars_per_row <= v_ha / 64; end if;

        r_h_end_active <= v_ha; r_h_beg_sync <= v_ha + v_hfp; r_h_end_sync <= v_ha + v_hfp + v_hs; r_h_total <= v_ha + v_hfp + v_hs + v_hbp;
        r_v_end_active <= v_va; r_v_beg_sync <= v_va + v_vfp; r_v_end_sync <= v_va + v_vfp + v_vs; r_v_total <= v_va + v_vfp + v_vs + v_vbp;
        r_pol <= v_pol;
    end process;

    -- MAIN PIPELINED PROCESS
    -- Hedef: Adres hesaplaması (Çarpma + Toplama) 2-3 saat darbesi sürer.
    -- HSYNC ve VSYNC sinyallerini de aynı miktarda geciktirip çıkışa vermeliyiz.
    process (PX_CLK_I) 
        variable v_mask : unsigned(11 downto 0);
    begin
        if rising_edge(PX_CLK_I) then
            if RST_I = '1' then
                cnt_h <= 0; cnt_v <= 0;
                s_hsync_s0 <= '0'; s_vsync_s0 <= '0'; s_visible_s0 <= '0';
                s_multvalue <= (others=>'0');
                s_charmem_ptr <= (others=>'0');
            else
                -- 1. Counter (Sayac)
                if cnt_h < r_h_total - 1 then
                    cnt_h <= cnt_h + 1;
                else
                    cnt_h <= 0;
                    if cnt_v < r_v_total - 1 then cnt_v <= cnt_v + 1; else cnt_v <= 0; end if;
                end if;

                -- 2. Stage 0: Ham Sync Üretimi (Sayaca anında tepki verir)
                if (cnt_h >= r_h_beg_sync) and (cnt_h < r_h_end_sync) then s_hsync_s0 <= r_pol; else s_hsync_s0 <= not r_pol; end if;
                if (cnt_v >= r_v_beg_sync) and (cnt_v < r_v_end_sync) then s_vsync_s0 <= r_pol; else s_vsync_s0 <= not r_pol; end if;
                if (cnt_h < r_h_end_active) and (cnt_v < r_v_end_active) then s_visible_s0 <= '1'; else s_visible_s0 <= '0'; end if;

                -- 3. Stage 1: Pointer Hesaplama (Index)
                -- Hangi karakterdeyiz (Sütun/Satır indeksi)
                s_ptr_ch_x <= resize(shift_right(to_unsigned(cnt_h, 12), r_shift_amt), s_ptr_ch_x'length);
                s_ptr_ch_y <= resize(shift_right(to_unsigned(cnt_v, 12), r_shift_amt), s_ptr_ch_y'length);
            
                -- Karakterin içindeki hangi piksel?
                v_mask := shift_left(to_unsigned(1, 12), r_shift_amt) - 1;
                s_ptr_px_x <= resize(to_unsigned(cnt_h, 12) and v_mask, s_ptr_px_x'length);
                s_ptr_px_y <= resize(to_unsigned(cnt_v, 12) and v_mask, s_ptr_px_y'length);

                -- Sync sinyallerini taşı (Gecikme 1)
                s_hsync_s1 <= s_hsync_s0; s_vsync_s1 <= s_vsync_s0; s_visible_s1 <= s_visible_s0;

                -- 4. Stage 2: Çarpma İşlemi (Lineer Adres Hazırlığı)
                -- Adres = (Y_Indeks * Genişlik) + X_Indeks
                s_multvalue   <= s_ptr_ch_y * to_unsigned(r_chars_per_row, 8);
                s_ptr_ch_x_d1 <= s_ptr_ch_x; -- Toplama için X indeksini bir tur bekletiyoruz
                
                s_ptr_px_x_d1 <= s_ptr_px_x; -- Pixel pointerları da bekletiyoruz
                s_ptr_px_y_d1 <= s_ptr_px_y;

                -- Sync sinyallerini taşı (Gecikme 2)
                s_hsync_s2 <= s_hsync_s1; s_vsync_s2 <= s_vsync_s1; s_visible_s2 <= s_visible_s1;

                -- 5. Stage 3: Son Toplama ve Çıkış Registerlama
                -- BURADAKİ DÜZELTME ÖNEMLİ: multvalue ile pixel pointer'ı değil, Karakter X indeksini topluyoruz.
                s_charmem_ptr <= resize(s_multvalue + s_ptr_ch_x_d1, s_charmem_ptr'length);
                
                -- Pixel pointerları son kez kaydır (Adres ile aynı faza gelsin)
                s_ptr_px_x_d2 <= s_ptr_px_x_d1;
                s_ptr_px_y_d2 <= s_ptr_px_y_d1;

                -- Sync sinyalleri artık Adres ile tamamen eşleşti. Çıkışa veriyoruz.
                VGA_HSYNC_O <= s_hsync_s2;
                VGA_VSYNC_O <= s_vsync_s2;
                VISIBLE_O   <= s_visible_s2;
            end if;
        end if;
    end process;

    -- Çıkış Atamaları
    CHAR_PTR_O  <= s_charmem_ptr;
    PTR_PX_X_O  <= s_ptr_px_x_d2;
    PTR_PX_Y_O  <= s_ptr_px_y_d2;

end architecture;