library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity top_wrapper is
    generic(
        G_SYSCLK_FREQ        : integer := 100_000_000;
        G_BAUD_RATE          : integer := 115_200;
        G_MEM_DEPTH          : integer := (1920/16)*(1080/16);        
        G_VGA_CLR_WIDTH      : integer := 4; -- (zed = 4, sp3e = 1)
        G_DATAMEM_INITF      : string  := "mem/datamem_init.mem";
        G_FONT16x16_FILE     : string  := "mem/font_roboto16x16.mem";
        G_FONT32x32_FILE     : string  := "mem/font_roboto32x32.mem";
        G_FONT64x64_FILE     : string  := "mem/font_roboto64x64.mem"
    );
    port(
        SYSCLK_I  : in std_logic;
        RST_I      : in std_logic;
        UART_RX_I  : in std_logic;
        FONT_SEL_I : in std_logic_vector(1 downto 0);
        RES_SEL_I  : in std_logic_vector(2 downto 0);

        VGA_R_O     : out std_logic_vector(G_VGA_CLR_WIDTH-1 downto 0);
        VGA_G_O     : out std_logic_vector(G_VGA_CLR_WIDTH-1 downto 0);
        VGA_B_O     : out std_logic_vector(G_VGA_CLR_WIDTH-1 downto 0);
        VGA_HSYNC_O : out std_logic;
        VGA_VSYNC_O : out std_logic
    );
    end entity;

architecture rtl of top_wrapper is
    
    signal s_px_clk          : std_logic := '0';
    signal s_cm_ready        : std_logic := '0';
    signal s_datawriter_busy : std_logic := '0';

    signal s_dmem_wren       : std_logic := '0';
    signal s_dmem_wrdat      : std_logic_vector(15 downto 0) := (others => '0');
    signal s_dmem_wradr      : unsigned(integer(ceil(log2(real(G_MEM_DEPTH))))-1 downto 0) := (others => '0');

begin

    clockmaker_inst : entity work.clockmaker
    port map(
        SYSCLK_I  => SYSCLK_I,
        RST_I     => RST_I,
        CLK_SEL_I => RES_SEL_I,
        PX_CLK_O  => s_px_clk,
        READY_O   => s_cm_ready
    );
    

    datawriter_inst : entity work.datawriter -- ADD PULLUP Signal to uart input. do not make floating.
    generic map(
        G_SYSCLK_FREQ => G_SYSCLK_FREQ,
        G_BAUD_RATE   => G_BAUD_RATE,
        G_MEM_DEPTH   => G_MEM_DEPTH
    )
    port map(
        SYSCLK_I      => SYSCLK_I, 
        RST_I         => RST_I, 
        UART_DAT_I    => UART_RX_I,
        MEM_DAT_O     => s_dmem_wrdat,
        MEM_ADR_O     => s_dmem_wradr,
        MEM_WREN_O    => s_dmem_wren,
        BUSY_O        => s_datawriter_busy
    );


    vga_chargen_inst : entity work.vgachargen
    generic map(
        G_VGA_CLR_WIDTH  => G_VGA_CLR_WIDTH,      
        G_DATAMEM_INITF  => G_DATAMEM_INITF,      
        G_MAX_MEM_DEPTH  => G_MEM_DEPTH, 
        G_FONT16x16_FILE => G_FONT16x16_FILE,     
        G_FONT32x32_FILE => G_FONT32x32_FILE,     
        G_FONT64x64_FILE => G_FONT64x64_FILE  
    )
    port map(
        PX_CLK_I         => s_px_clk,
        RST_I            => RST_I and not(s_cm_ready) and s_datawriter_busy,
        FONT_SEL_I       => FONT_SEL_I,
        RES_SEL_I        => RES_SEL_I,
        DMEM_DAT_I       => s_dmem_wrdat,
        DMEM_ADR_I       => s_dmem_wradr,
        DMEM_WREN_I      => s_dmem_wren,
        VGA_R_O          => VGA_R_O,     
        VGA_G_O          => VGA_G_O,     
        VGA_B_O          => VGA_B_O,     
        VGA_HSYNC_O      => VGA_HSYNC_O, 
        VGA_VSYNC_O      => VGA_VSYNC_O
    );

end architecture;

