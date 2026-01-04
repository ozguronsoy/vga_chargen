library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

entity fontmem is
    generic(
        G_FONT16x16_FILE : string;
        G_FONT32x32_FILE : string;
        G_FONT64x64_FILE : string
    );
    port(
        -- Inputs
        PX_CLK_I    : in std_logic;
        RST_I       : in std_logic;
        FONT_SEL_I  : in std_logic_vector(1 downto 0);
        ASCII_DAT_I : in std_logic_vector(6 downto 0);
        PTR_PX_X_I  : in unsigned(5 downto 0);
        PTR_PX_Y_I  : in unsigned(5 downto 0);
        
        -- Outputs
        PX_DAT_O    : out std_logic;
        
        -- Pipeline Signals
        VISIBLE_I   : in  std_logic;
        FONT_COL_I  : in  std_logic_vector(2 downto 0);
        BKGR_COL_I  : in  std_logic_vector(2 downto 0);
        VGA_HSYNC_I : in  std_logic;
        VGA_VSYNC_I : in  std_logic;
        VISIBLE_O   : out std_logic;
        FONT_COL_O  : out std_logic_vector(2 downto 0);
        BKGR_COL_O  : out std_logic_vector(2 downto 0);
        VGA_HSYNC_O : out std_logic;
        VGA_VSYNC_O : out std_logic
    );
end entity;

architecture rtl of fontmem is

    -- Type declerations
    type t_mem_16 is array (natural range <>) of std_logic_vector(15 downto 0);
    type t_mem_32 is array (natural range <>) of std_logic_vector(31 downto 0);
    type t_mem_64 is array (natural range <>) of std_logic_vector(63 downto 0);

    -- Impure function for every type
    
    -- 16x16 Font Loader
    impure function InitFont16 (FileName : in string; Depth : integer) return t_mem_16 is
        file RamFile : text open read_mode is FileName;
        variable RamFileLine : line;
        variable RAM : t_mem_16(0 to Depth - 1);
        variable temp_vec : std_logic_vector(15 downto 0);
    begin
        for i in 0 to Depth - 1 loop
            if not endfile(RamFile) then
                readline(RamFile, RamFileLine);
                read(RamFileLine, temp_vec);
                RAM(i) := temp_vec;
            else
                RAM(i) := (others => '0');
            end if;
        end loop;
        return RAM;
    end function;

    -- 32x32 Font Loader
    impure function InitFont32 (FileName : in string; Depth : integer) return t_mem_32 is
        file RamFile : text open read_mode is FileName;
        variable RamFileLine : line;
        variable RAM : t_mem_32(0 to Depth - 1);
        variable temp_vec : std_logic_vector(31 downto 0);
    begin
        for i in 0 to Depth - 1 loop
            if not endfile(RamFile) then
                readline(RamFile, RamFileLine);
                read(RamFileLine, temp_vec);
                RAM(i) := temp_vec;
            else
                RAM(i) := (others => '0');
            end if;
        end loop;
        return RAM;
    end function;

    -- 64x64 Font Loader
    impure function InitFont64 (FileName : in string; Depth : integer) return t_mem_64 is
        file RamFile : text open read_mode is FileName;
        variable RamFileLine : line;
        variable RAM : t_mem_64(0 to Depth - 1);
        variable temp_vec : std_logic_vector(63 downto 0);
    begin
        for i in 0 to Depth - 1 loop
            if not endfile(RamFile) then
                readline(RamFile, RamFileLine);
                read(RamFileLine, temp_vec);
                RAM(i) := temp_vec;
            else
                RAM(i) := (others => '0');
            end if;
        end loop;
        return RAM;
    end function;

    -- Memory Declerations
    signal s_font_mem16x16 : t_mem_16(0 to 128*16-1) := InitFont16(G_FONT16x16_FILE, 128*16);
    signal s_font_mem32x32 : t_mem_32(0 to 128*32-1) := InitFont32(G_FONT32x32_FILE, 128*32);
    signal s_font_mem64x64 : t_mem_64(0 to 128*64-1) := InitFont64(G_FONT64x64_FILE, 128*64);

    -- Force to make as block ram
    attribute rom_style : string;
    attribute rom_style of s_font_mem16x16 : signal is "block";
    attribute rom_style of s_font_mem32x32 : signal is "block";
    attribute rom_style of s_font_mem64x64 : signal is "block";
    
    
    signal s_fontmem16x16_ptr : integer range 0 to 128*16-1 := 0;
    signal s_fontmem32x32_ptr : integer range 0 to 128*32-1 := 0;
    signal s_fontmem64x64_ptr : integer range 0 to 128*64-1 := 0;

    signal s_read_data16x16   : std_logic_vector(15 downto 0) := (others => '0');
    signal s_read_data32x32   : std_logic_vector(31 downto 0) := (others => '0');
    signal s_read_data64x64   : std_logic_vector(63 downto 0) := (others => '0');

    -- Pipeline signals 
    signal s_pl_visible1      : std_logic;
    signal s_pl_vga_hsync1    : std_logic;
    signal s_pl_vga_vsync1    : std_logic;
    signal s_pl_font_col1     : std_logic_vector(2 downto 0);
    signal s_pl_bkgr_col1     : std_logic_vector(2 downto 0);

    signal s_pl_visible2      : std_logic;
    signal s_pl_vga_hsync2    : std_logic;
    signal s_pl_vga_vsync2    : std_logic;
    signal s_pl_font_col2     : std_logic_vector(2 downto 0);
    signal s_pl_bkgr_col2     : std_logic_vector(2 downto 0);

begin

    P_SEQ_PROC : process (PX_CLK_I) is 
    begin
        if rising_edge(PX_CLK_I) then
            -- FF1: Adress Calculation
            s_fontmem16x16_ptr <= to_integer(unsigned(ASCII_DAT_I) * 16) + to_integer(PTR_PX_Y_I(3 downto 0));
            s_fontmem32x32_ptr <= to_integer(unsigned(ASCII_DAT_I) * 32) + to_integer(PTR_PX_Y_I(4 downto 0));
            s_fontmem64x64_ptr <= to_integer(unsigned(ASCII_DAT_I) * 64) + to_integer(PTR_PX_Y_I(5 downto 0));
            
            -- FF2: Read Memory
            s_read_data16x16 <= s_font_mem16x16(s_fontmem16x16_ptr);
            s_read_data32x32 <= s_font_mem32x32(s_fontmem32x32_ptr);
            s_read_data64x64 <= s_font_mem64x64(s_fontmem64x64_ptr);
            
            -- FF3: Output Mux: 64x64 font is very large, there is a combinational wire drive latency.
            case FONT_SEL_I is
                when "00" =>
                    PX_DAT_O <= s_read_data16x16(15 - to_integer(PTR_PX_X_I(3 downto 0)));
                when "01" =>
                    PX_DAT_O <= s_read_data32x32(31 - to_integer(PTR_PX_X_I(4 downto 0)));
                when "10" => 
                    PX_DAT_O <= s_read_data64x64(63 - to_integer(PTR_PX_X_I(5 downto 0)));
                when others =>
                    PX_DAT_O <= '0';
            end case;
        end if;
    end process;

    -- Match Pipeline Signals
    P_PIPE_DELAY : process (PX_CLK_I) is 
    begin
        if rising_edge(PX_CLK_I) then
            s_pl_visible1   <= VISIBLE_I ;
            s_pl_vga_hsync1 <= VGA_HSYNC_I;
            s_pl_vga_vsync1 <= VGA_VSYNC_I;
            s_pl_font_col1  <= FONT_COL_I;
            s_pl_bkgr_col1  <= BKGR_COL_I;

            s_pl_visible2   <= s_pl_visible1;      
            s_pl_vga_hsync2 <= s_pl_vga_hsync1;  
            s_pl_vga_vsync2 <= s_pl_vga_vsync1;  
            s_pl_font_col2  <= s_pl_font_col1;    
            s_pl_bkgr_col2  <= s_pl_bkgr_col1;      
            
            VISIBLE_O   <= s_pl_visible2;
            VGA_HSYNC_O <= s_pl_vga_hsync2;
            VGA_VSYNC_O <= s_pl_vga_vsync2;
            FONT_COL_O  <= s_pl_font_col2;
            BKGR_COL_O  <= s_pl_bkgr_col2;
        end if;
    end process;

end architecture;