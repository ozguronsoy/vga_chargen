library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity vgachargen is
    generic(
        G_VGA_CLR_WIDTH      : integer;
        G_DATAMEM_INITF      : string; 
        G_MAX_MEM_DEPTH      : integer;
        G_FONT16x16_FILE     : string;
        G_FONT32x32_FILE     : string;
        G_FONT64x64_FILE     : string
    );
    port (
        PX_CLK_I    : in std_logic;
        RST_I       : in std_logic;
        FONT_SEL_I  : in std_logic_vector(1 downto 0); --00 1x16, 01 32x32, 10 64x64
        RES_SEL_I   : in std_logic_vector(2 downto 0);
        VGA_R_O     : out std_logic_vector(G_VGA_CLR_WIDTH-1 downto 0);
        VGA_G_O     : out std_logic_vector(G_VGA_CLR_WIDTH-1 downto 0);
        VGA_B_O     : out std_logic_vector(G_VGA_CLR_WIDTH-1 downto 0);
        VGA_HSYNC_O : out std_logic;
        VGA_VSYNC_O : out std_logic
    );
end entity;

architecture rtl of vgachargen is

    -- Pipe 1->2 Signals
    signal sp12_visible   : std_logic := '0';
    signal sp12_vga_hsync : std_logic := '0';
    signal sp12_vga_vsync : std_logic := '0';
    signal sp12_ptr_px_x  : unsigned(5 downto 0);
    signal sp12_ptr_px_y  : unsigned(5 downto 0);
    signal sp12_char_ptr  : unsigned(13 downto 0);

    -- Pipe 2->3 Signals
    signal sp23_ptr_px_x  : unsigned(5 downto 0);
    signal sp23_ptr_px_y  : unsigned(5 downto 0);
    signal sp23_ascii_dat : std_logic_vector(6 downto 0) := (others => '0');
    signal sp23_visible   : std_logic := '0';
    signal sp23_vga_hsync : std_logic := '0';
    signal sp23_vga_vsync : std_logic := '0';
    signal sp23_font_col  : std_logic_vector(2 downto 0) := (others => '0');
    signal sp23_bkgr_col  : std_logic_vector(2 downto 0) := (others => '0');
    -- Pipe 3->4 Signals
    signal sp34_px_dat    : std_logic := '0';
    signal sp34_visible   : std_logic := '0';
    signal sp34_vga_hsync : std_logic := '0';
    signal sp34_vga_vsync : std_logic := '0';
    signal sp34_font_col  : std_logic_vector(2 downto 0) := (others => '0');
    signal sp34_bkgr_col  : std_logic_vector(2 downto 0) := (others => '0');

    -- Output Signals
    signal s_vga_r        : std_logic := '0';
    signal s_vga_g        : std_logic := '0';
    signal s_vga_b        : std_logic := '0';
    signal s_vga_hsync    : std_logic := '0';
    signal s_vga_vsync    : std_logic := '0';
    
begin

    -- PIPE1 : VGA Signal Generator
    vgasigen_inst : work.vgasigen
        port map(
            PX_CLK_I     => PX_CLK_I,
            RST_I        => RST_I,
            RES_SEL_I    => RES_SEL_I,
            FONT_SEL_I   => FONT_SEL_I,
            VISIBLE_O    => sp12_visible,
            VGA_HSYNC_O  => sp12_vga_hsync,
            VGA_VSYNC_O  => sp12_vga_vsync,
            CHAR_PTR_O   => sp12_char_ptr,
            PTR_PX_X_O   => sp12_ptr_px_x,
            PTR_PX_Y_O   => sp12_ptr_px_y
        );


    -- PIPE 2 : Data Memory
    datamem_inst : work.datamem
    generic map(
        G_DATAMEM_INITF => G_DATAMEM_INITF,
        G_MAX_MEM_DEPTH => G_MAX_MEM_DEPTH
    )
    port map(
        -- In
        PX_CLK_I    => PX_CLK_I,
        CHAR_PTR_I  => sp12_char_ptr,
        -- Out
        ASCII_DAT_O => sp23_ascii_dat,
        FONT_COL_O  => sp23_font_col,
        BKGR_COL_O  => sp23_bkgr_col,
        -- Pipe
        VISIBLE_I   => sp12_visible,  
        PTR_PX_X_I  => sp12_ptr_px_x, 
        PTR_PX_Y_I  => sp12_ptr_px_y, 
        VGA_VSYNC_I => sp12_vga_vsync,
        VGA_HSYNC_I => sp12_vga_hsync,

        VISIBLE_O   => sp23_visible,
        PTR_PX_X_O  => sp23_ptr_px_x,
        PTR_PX_Y_O  => sp23_ptr_px_y,
        VGA_VSYNC_O => sp23_vga_vsync,
        VGA_HSYNC_O => sp23_vga_hsync
    );

    -- PIPE 3 : Font Memory
    fontmem_inst : work.fontmem
    generic map(
        G_FONT16x16_FILE => G_FONT16x16_FILE, 
        G_FONT32x32_FILE => G_FONT32x32_FILE,
        G_FONT64x64_FILE => G_FONT64x64_FILE
    )
    port map(
        -- IN
        PX_CLK_I    => PX_CLK_I,
        RST_I       => RST_I,
        FONT_SEL_I  => FONT_SEL_I,
        ASCII_DAT_I => sp23_ascii_dat,
        PTR_PX_X_I  => sp23_ptr_px_x,
        PTR_PX_Y_I  => sp23_ptr_px_y,
        -- OUT
        PX_DAT_O    => sp34_px_dat,
        -- PIPE
        VISIBLE_I   => sp23_visible,
        FONT_COL_I  => sp23_font_col,
        BKGR_COL_I  => sp23_bkgr_col,
        VGA_HSYNC_I => sp23_vga_hsync,
        VGA_VSYNC_I => sp23_vga_vsync,
        VISIBLE_O   => sp34_visible,
        FONT_COL_O  => sp34_font_col,
        BKGR_COL_O  => sp34_bkgr_col,
        VGA_HSYNC_O => sp34_vga_hsync,
        VGA_VSYNC_O => sp34_vga_vsync
    );

    -- PIPE 4 : Colormaker
    colormaker_inst : work.colormaker
        port map(
            -- IN
            PX_CLK_I    => PX_CLK_I,
            VISIBLE_I   => sp34_visible,
            PX_DAT_I    => sp34_px_dat,
            FONT_CLR_I  => sp34_font_col,
            BKGR_CLR_I  => sp34_bkgr_col,
            VGA_HSYNC_I => sp34_vga_hsync,
            VGA_VSYNC_I => sp34_vga_vsync,
            -- OUT
            VGA_R_O     => s_vga_r,
            VGA_G_O     => s_vga_g,
            VGA_B_O     => s_vga_b,
            VGA_HSYNC_O => s_vga_hsync,
            VGA_VSYNC_O => s_vga_vsync
        );

    VGA_R_O     <= (others => s_vga_r);
    VGA_G_O     <= (others => s_vga_g);
    VGA_B_O     <= (others => s_vga_b);
    VGA_HSYNC_O <= s_vga_hsync;
    VGA_VSYNC_O <= s_vga_vsync;

end architecture;