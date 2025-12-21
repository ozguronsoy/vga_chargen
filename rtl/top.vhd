library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_top is
    port (
        clk_i       : in  std_logic; -- 100 MHz Sistem Saati
        rst_i       : in  std_logic; -- Reset Tuşu
        
        -- VGA Fiziksel Çıkışları (4-Bit Vektör - ZedBoard/Basys3 Uyumlu)
        vga_hsync_o : out std_logic;
        vga_vsync_o : out std_logic;
        vga_r_o     : out std_logic_vector(3 downto 0);
        vga_g_o     : out std_logic_vector(3 downto 0);
        vga_b_o     : out std_logic_vector(3 downto 0)
    );
end entity;

architecture rtl of vga_top is

    -- Clock Wizard (IP Core yoksa simülasyon/basit sentez için bu component kullanılır)
    component clk_wiz_0 is
        port (
            clk_out1 : out std_logic; -- 25.175 MHz
            reset    : in  std_logic;
            locked   : out std_logic;
            clk_in1  : in  std_logic
        );
    end component;

    signal s_clk_pixel : std_logic;
    signal s_locked    : std_logic;
    signal s_rst_sys   : std_logic;

    -- Stage 0: Signal Generator (Adres Üretimi)
    signal s_hsync_0    : std_logic;
    signal s_vsync_0    : std_logic;
    signal s_visible_0  : std_logic;
    signal s_bit_dptr_0 : integer range 0 to 7;
    signal s_char_ptr_0 : integer range 0 to 4799;
    -- [FIX 1] Stage 0 için sütun (width) pointer sinyali eklendi
    signal s_bit_wptr_0 : integer range 0 to 7; 

    -- Stage 1: Data Memory Çıkışı (Karakter Kodu)
    signal s_ascii_code_1 : std_logic_vector(6 downto 0);
    signal s_font_col_1   : std_logic_vector(2 downto 0);
    signal s_bkgr_col_1   : std_logic_vector(2 downto 0);
    signal r_bit_dptr_1   : integer range 0 to 7;
    -- [FIX 2] Stage 1 pipeline için sütun pointer
    signal r_bit_wptr_1   : integer range 0 to 7;

    -- Stage 2: Ascii LUT Çıkışı (Piksel Verisi)
    signal s_pixel_data_2 : std_logic;
    signal r_font_col_2   : std_logic_vector(2 downto 0);
    signal r_bkgr_col_2   : std_logic_vector(2 downto 0);
    signal r_visible_2    : std_logic; -- Pipe hattından gelen visible
    -- [FIX 3] Stage 2 pipeline (LUT Mux girişi) için sütun pointer
    signal r_bit_wptr_2   : integer range 0 to 7;

    -- Stage 3: Colormaker Çıkışı (Renkler)
    signal s_red_1bit   : std_logic;
    signal s_green_1bit : std_logic;
    signal s_blue_1bit  : std_logic;

    -- Pipeline Sync Sinyalleri (3 Kademeli Gecikme)
    signal r_hsync_pipe : std_logic_vector(3 downto 1);
    signal r_vsync_pipe : std_logic_vector(3 downto 1);
    signal r_vis_pipe   : std_logic_vector(2 downto 1);

begin

    -- 1. CLOCK ÜRETİMİ
    u_clk_wiz : clk_wiz_0
    port map (
        clk_out1 => s_clk_pixel,
        reset    => rst_i, 
        locked   => s_locked,
        clk_in1  => clk_i
    );
    
    -- IP Core kilitlenene kadar sistemi resetle
    s_rst_sys <= (not s_locked) or rst_i;

    -- 2. SIGNAL GENERATOR (Stage 0)
    u_sig_gen : entity work.signal_generator
    generic map(
        c_hactv    => 640,
        c_hftph    => 16,
        c_hsync    => 96,
        c_hbkph    => 48,
        c_vactv    => 480,
        c_vftph    => 10,
        c_vsync    => 2,
        c_vbkph    => 33,
        c_polarity => "negative",
        c_bit_w    => 8,
        c_bit_d    => 8,
        c_char_w   => 80,   -- 640 / 8 = 80 Karakter
        c_ptr_max  => 4800  -- 80 * 60 = 4800 Karakter
    )
    port map(
        clk_i      => s_clk_pixel,
        i_rst      => s_rst_sys,
        o_hsync    => s_hsync_0,
        o_vsync    => s_vsync_0,
        o_visible  => s_visible_0,
        o_bit_wptr => s_bit_wptr_0, -- [FIX 4] 'open' yerine sinyal bağlandı [cite: 96]
        o_bit_dptr => s_bit_dptr_0,
        o_char_ptr => s_char_ptr_0
    );

    -- 3. DATA MEMORY (Stage 0 -> Stage 1)
    u_datamem : entity work.datamem
    generic map(
        c_depth  => 4800,
        c_width  => 13,
        c_init_f => "wozniak.mem"
    )
    port map(
        clk_i       => s_clk_pixel,
        char_ptr_i  => s_char_ptr_0,
        ascii_dat_o => s_ascii_code_1, -- Data T1'de hazır
        font_col_o  => s_font_col_1,
        bkgr_col_o  => s_bkgr_col_1
    );

    -- 4. ASCII LUT (Stage 1 -> Stage 2)
    -- Address (row/char) Stage 1'de girer. Data Stage 2'de çıkar.
    -- Bit seçimi (Mux) çıkışta yapıldığı için, sütün bilgisi Stage 2 zamanında verilmeli.
    u_asciilut : entity work.asciilut
    port map(
        clk_i       => s_clk_pixel,
        rst_i       => s_rst_sys,
        ascii_dat_i => s_ascii_code_1,
        
        -- [FIX 5] Sabit 0 yerine Stage 2 pointer'ı bağlandı.
        -- '7 - ptr' yaparak harflerin aynalanmasını (mirroring) engelliyoruz.
        ascii_col_i => 7 - r_bit_wptr_2, 
        
        ascii_raw_i => r_bit_dptr_1, -- Satır adresi Stage 1'de latch edilir
        px_dat_o    => s_pixel_data_2 
    );

    -- 5. PIPELINE REGISTERLARI
    process (s_clk_pixel)
    begin
        if rising_edge(s_clk_pixel) then
            if s_rst_sys = '1' then
                r_hsync_pipe <= (others => '0');
                r_vsync_pipe <= (others => '0');
                r_bit_dptr_1 <= 0;
                r_bit_wptr_1 <= 0;
                r_bit_wptr_2 <= 0;
                r_font_col_2 <= (others => '0');
                r_bkgr_col_2 <= (others => '0');
                r_vis_pipe   <= (others => '0');
            else
                -- ::::: ADRES / DATA PIPELINE :::::
                
                -- Stage 0 -> Stage 1 (DataMem Okuma Gecikmesi)
                r_bit_dptr_1 <= s_bit_dptr_0;
                r_bit_wptr_1 <= s_bit_wptr_0; -- [FIX 6] Wptr taşınıyor

                -- Stage 1 -> Stage 2 (LUT Okuma Gecikmesi)
                r_font_col_2 <= s_font_col_1;
                r_bkgr_col_2 <= s_bkgr_col_1;
                r_bit_wptr_2 <= r_bit_wptr_1; -- [FIX 7] Wptr Stage 2'ye taşınıyor (Mux için)

                -- ::::: SYNC SINYALLERI PIPELINE :::::
                
                -- Stage 0 -> Stage 1
                r_hsync_pipe(1) <= s_hsync_0;
                r_vsync_pipe(1) <= s_vsync_0;
                
                -- Stage 1 -> Stage 2
                r_hsync_pipe(2) <= r_hsync_pipe(1);
                r_vsync_pipe(2) <= r_vsync_pipe(1);
                
                -- Stage 2 -> Stage 3 (Colormaker Çıkış Hizalaması)
                r_hsync_pipe(3) <= r_hsync_pipe(2);
                r_vsync_pipe(3) <= r_vsync_pipe(2);
                
                -- Visible Sinyali Pipeline (T0 -> T1 -> T2)
                -- Colormaker T2'de visible alıp T3'te renk verir.
                r_vis_pipe(1) <= s_visible_0;
                r_vis_pipe(2) <= r_vis_pipe(1);
                
            end if;
        end if;
    end process;

    -- 6. COLORMAKER (Stage 2 -> Stage 3)
    -- Girişleri T2 zamanında alır, çıkışı T3 zamanında verir (Registered Output).
    u_colormaker : entity work.colormaker
    port map(
        clk_i      => s_clk_pixel,
        visible_i  => r_vis_pipe(2),   -- Stage 2'den gelen visible
        px_font_i  => s_pixel_data_2,  -- Stage 2'den gelen piksel
        font_clr_i => r_font_col_2,    -- Stage 2'den gelen renk
        bkgr_clr_i => r_bkgr_col_2,    -- Stage 2'den gelen renk
        vga_r_o    => s_red_1bit,      -- Stage 3 (Çıkış)
        vga_g_o    => s_green_1bit,
        vga_b_o    => s_blue_1bit
    );

    -- 7. ÇIKIŞ ATAMALARI
    -- Tüm sinyaller Stage 3 zamanında dışarı verilir.
    vga_hsync_o <= r_hsync_pipe(3);
    vga_vsync_o <= r_vsync_pipe(3);
    
    -- Tek bitlik renkleri 4 bite kopyala (Zedboard/Basys3 için)
    vga_r_o <= (others => s_red_1bit);
    vga_g_o <= (others => s_green_1bit);
    vga_b_o <= (others => s_blue_1bit);

end architecture;