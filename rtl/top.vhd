library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_top is
    generic(
        G_VGA_CLR_WIDTH      : integer := 4; -- (zed = 4, sp3e = 1)
        G_DATAMEM_INITF      : string  := "mem/datamem_init.mem";
        G_FONT16x16_FILE     : string  := "mem/font_roboto16x16.mem";
        G_FONT32x32_FILE     : string  := "mem/font_roboto32x32.mem";
        G_FONT64x64_FILE     : string  := "mem/font_roboto64x64.mem"
    );
    port(
        SYS_CLK_I : in std_logic;
        RST_I     : in std_logic;
        FONT_SEL_I : in std_logic_vector(1 downto 0);
        RES_SEL_I  : in std_logic_vector(2 downto 0);

        VGA_R_O     : out std_logic_vector(G_VGA_CLR_WIDTH-1 downto 0);
        VGA_G_O     : out std_logic_vector(G_VGA_CLR_WIDTH-1 downto 0);
        VGA_B_O     : out std_logic_vector(G_VGA_CLR_WIDTH-1 downto 0);
        VGA_HSYNC_O : out std_logic;
        VGA_VSYNC_O : out std_logic
    );
    end entity;

architecture rtl of vga_top is
    
    constant C_MAX_MEM_DEPTH : integer := 1920*1080/(16*16); -- 1920x1080, 16x16 font.

    signal s_px_clk   : std_logic := '0';
    signal s_cm_ready : std_logic := '0';
    signal s_cg_reset : std_logic := '1';

begin

    clockmaker_inst : work.clockmaker
    port map(
        SYSCLK_I  => SYS_CLK_I,
        RST_I     => RST_I,
        CLK_SEL_I => RES_SEL_I,
        PX_CLK_O  => s_px_clk,
        READY_O   => s_cm_ready
    );
    
    s_cg_reset <= RST_I and not(s_cm_ready);


    vga_chargen_inst : work.vga_chargen
    generic map(
        G_VGA_CLR_WIDTH      => G_VGA_CLR_WIDTH,      
        G_DATAMEM_INITF      => G_DATAMEM_INITF,      
        G_MAX_MEM_DEPTH      => C_MAX_MEM_DEPTH, 
        G_FONT16x16_FILE     => G_FONT16x16_FILE,     
        G_FONT32x32_FILE     => G_FONT32x32_FILE,     
        G_FONT64x64_FILE     => G_FONT64x64_FILE  
    )
    port map(
        PX_CLK_I             => s_px_clk,
        RST_I                => s_cg_reset,
        FONT_SEL_I           => FONT_SEL_I,
        RES_SEL_I            => RES_SEL_I,
        VGA_R_O              => VGA_R_O,     
        VGA_G_O              => VGA_G_O,     
        VGA_B_O              => VGA_B_O,     
        VGA_HSYNC_O          => VGA_HSYNC_O, 
        VGA_VSYNC_O          => VGA_VSYNC_O
    );

end architecture;

