library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity signal_generator is
    generic(
        c_hactv    : integer := 1280;
        c_hftph    : integer := 110;
        c_hsync    : integer := 40;
        c_hbkph    : integer := 220;
        c_vactv    : integer := 720;
        c_vftph    : integer := 5;
        c_vsync    : integer := 5;
        c_vbkph    : integer := 20;
        c_polarity : string  := "positive";

        -- Font Counter Generics (fontcounter.vhd'den)
        c_bit_w    : integer := 8;
        c_bit_d    : integer := 8;
        c_char_w   : integer := 160;
        -- c_char_d kullanilmiyor gibi gorunuyor ama logic tutarliligi icin biraktim
        c_char_d   : integer := 90;
        c_ptr_max  : integer := 14400
    );
    port(
        clk_i         : in  std_logic;
        i_rst         : in  std_logic;

        -- Senkronizasyon Çıkışları (Gecikmesi eşitlenmiş)
        o_hsync       : out std_logic;
        o_vsync       : out std_logic;
        o_visible     : out std_logic;

        -- Bellek Adres Çıkışları
        o_bit_wptr    : out integer range 0 to c_bit_w-1; -- char bitmap width
        o_bit_dptr    : out integer range 0 to c_bit_d-1; -- char bitmap depth
        o_char_ptr    : out integer range 0 to c_ptr_max-1 -- char pointer
    );
end entity;

architecture rtl of signal_generator is

    constant c_hmax : integer := c_hactv + c_hftph + c_hsync + c_hbkph;
    constant c_vmax : integer := c_vactv + c_vftph + c_vsync + c_vbkph;

    constant c_hs_start : integer := c_hactv + c_hftph;
    constant c_hs_end   : integer := c_hactv + c_hftph + c_hsync;
    constant c_vs_start : integer := c_vactv + c_vftph;
    constant c_vs_end   : integer := c_vactv + c_vftph + c_vsync;

    function get_idle_state(pol : string) return std_logic is
    begin
        if pol = "positive" then return '0'; else return '1'; end if;
    end function;

    function get_active_state(pol : string) return std_logic is
    begin
        if pol = "positive" then return '1'; else return '0'; end if;
    end function;

    constant c_idle_val   : std_logic := get_idle_state(c_polarity);
    constant c_active_val : std_logic := get_active_state(c_polarity);

    signal s_hcntr   : integer range 0 to c_hmax-1 := 0;
    signal s_vcntr   : integer range 0 to c_vmax-1 := 0;
    signal s_hsync_raw   : std_logic := c_idle_val;
    signal s_vsync_raw   : std_logic := c_idle_val;
    signal s_visible_raw : std_logic := '0';
    signal s_visible_prev : std_logic := '0'; -- Kenar tespiti için

    signal s_bit_wptr  : integer range 0 to c_bit_w-1  := 0;
    signal s_bit_wptr2 : integer range 0 to c_bit_w-1  := 0;
    signal s_bit_dptr  : integer range 0 to c_bit_d-1  := 0;
    signal s_char_wptr : integer range 0 to c_char_w-1 := 0;
    signal s_char_ptr  : integer range 0 to c_ptr_max-1 := 0;

begin

    P_VGA_TIMING : process (clk_i) is
    begin
        if rising_edge(clk_i) then
            if i_rst = '1' then
                s_hcntr       <= 0;
                s_vcntr       <= 0;
                s_hsync_raw   <= c_idle_val;
                s_vsync_raw   <= c_idle_val;
                s_visible_raw <= '0';
            else
                -- Yatay Sayaç
                if s_hcntr < c_hmax - 1 then
                    s_hcntr <= s_hcntr + 1;
                else
                    s_hcntr <= 0;
                    -- Dikey Sayaç
                    if s_vcntr < c_vmax - 1 then
                        s_vcntr <= s_vcntr + 1;
                    else
                        s_vcntr <= 0;
                    end if;
                end if;

                -- HSYNC Generation
                if (s_hcntr >= c_hs_start) and (s_hcntr < c_hs_end) then
                    s_hsync_raw <= c_active_val;
                else
                    s_hsync_raw <= c_idle_val;
                end if;

                -- VSYNC Generation
                if (s_vcntr >= c_vs_start) and (s_vcntr < c_vs_end) then
                    s_vsync_raw <= c_active_val;
                else
                    s_vsync_raw <= c_idle_val;
                end if;

                -- Visible Area Generation
                if (s_hcntr < c_hactv) and (s_vcntr < c_vactv) then
                    s_visible_raw <= '1';
                else
                    s_visible_raw <= '0';
                end if;
            end if;
        end if;
    end process;

    P_FONT_COUNTERS : process (clk_i) is
    begin
        if rising_edge(clk_i) then
            if i_rst = '1' then
                 s_bit_wptr  <= 0;
                 s_bit_dptr  <= 0;
                 s_char_wptr <= 0;
                 s_char_ptr  <= 0;
                 s_visible_prev <= '0';
            else
                s_visible_prev <= s_visible_raw;

                -- Aktif Görüntü Alanı
                if s_visible_raw = '1' then
                    if s_bit_wptr = c_bit_w-1 then
                        s_bit_wptr <= 0;
                        if s_char_wptr < c_char_w-1 then
                            s_char_wptr <= s_char_wptr + 1;
                            s_char_ptr  <= s_char_ptr + 1;
                        end if;
                    else
                        s_bit_wptr <= s_bit_wptr + 1;
                    end if;

                -- Satır Sonu (Falling Edge of Visible) [cite: 12]
                -- Bu mantık bir sonraki satıra geçiş hazırlığıdır.
                elsif (s_visible_prev = '1' and s_visible_raw = '0') then

                    s_char_wptr <= 0;

                    if s_bit_dptr = c_bit_d-1 then
                        s_bit_dptr <= 0;
                        if s_char_ptr = c_ptr_max-1 then
                            s_char_ptr <= 0;
                        else
                            s_char_ptr <= s_char_ptr + 1;
                        end if;
                    else
                        s_bit_dptr <= s_bit_dptr + 1;
                        -- Satır sonunda char pointer'ı satır başındaki karaktere geri çek
                        -- (Dikeyde aynı karakterin alt bitlerini çizmek için)
                        if s_char_ptr >= (c_char_w - 1) then
                            s_char_ptr <= s_char_ptr - (c_char_w-1);
                        else
                            s_char_ptr <= 0;
                        end if;
                    end if;
                end if;
            end if;
        end if;
    end process;

    -------------------------------------------------------------------------
    -- Process 3: Output Synchronization (Pipeline Delay)
    -- ÖNEMLİ: Font adresleri clk rising edge'de hesaplandığı için
    -- 'raw' sync sinyallerine göre 1 clock gecikmelidir.
    -- Bu yüzden Sync ve Visible sinyallerini de 1 clock geciktirerek dışarı veriyoruz.
    -------------------------------------------------------------------------
    P_OUTPUT_SYNC : process (clk_i) is
    begin
        if rising_edge(clk_i) then
            if i_rst = '1' then
                o_hsync   <= c_idle_val;
                o_vsync   <= c_idle_val;
                o_visible <= '0';
                s_bit_wptr2 <= 0;
            else
                s_bit_wptr2 <= s_bit_wptr;
                o_hsync   <= s_hsync_raw;
                o_vsync   <= s_vsync_raw;
                o_visible <= s_visible_raw;
            end if;
        end if;
    end process;

    -- Adres çıkışlarını ata [cite: 20]
    o_bit_wptr  <= s_bit_wptr2;
    o_bit_dptr  <= s_bit_dptr;
    o_char_ptr  <= s_char_ptr;

end architecture;
