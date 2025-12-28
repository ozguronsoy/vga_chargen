-- VGA Chargen : Clock Selector Module for Different Resolutions
-- Different Clock Inputs are 


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library UNISIM;
use UNISIM.VComponents.all;

entity clockmaker is
    Port(
        SYSCLK_I  : in std_logic;
        RST_I     : in std_logic;
        CLK_SEL_I : in std_logic_vector(2 downto 0);
        PX_CLK_O  : out std_logic;
        READY_O   : out std_logic 
    );
end entity;

architecture rtl of clockmaker is
    
    -- Vivado OOT Module.
    component clock_wizard is
        port(
            sysclk_i : in std_logic;
            rst_i    : in std_logic;
            clk25_o  : out std_logic;
            clk40_o  : out std_logic;
            clk74_o  : out std_logic;
            clk108_o : out std_logic;
            clk148_o : out std_logic;
            locked_o : out std_logic
        );
    end component;

    -- Signals
    signal s_px_clk     : std_logic := '0';
    signal s_ready      : std_logic := '0';
    signal s_pll_locked : std_logic := '0';

    signal s_clk_25     : std_logic := '0';
    signal s_clk_40     : std_logic := '0';
    signal s_clk_74     : std_logic := '0';
    signal s_clk_108    : std_logic := '0';
    signal s_clk_148    : std_logic := '0';

    signal mux1_out     : std_logic := '0';
    signal mux2_out     : std_logic := '0';
    signal mux3_out     : std_logic := '0';

    signal clk_sel_s    : std_logic_vector(2 downto 0) := (others => '0');
    signal clk_sel_ps_s : std_logic_vector(2 downto 0) := (others => '0');

begin

    clk_wizard_inst : clock_wizard
    port map(
        sysclk_i => sysclk_i,
        rst_i    => rst_i,
        clk25_o  => s_clk_25, 
        clk40_o  => s_clk_40, 
        clk74_o  => s_clk_74, 
        clk108_o => s_clk_108, 
        clk148_o => s_clk_148, 
        locked_o => s_pll_locked
    );

    BUFGMUX_inst1 : BUFGMUX
    port map(
        O  => mux1_out,
        I0 => s_clk_25,
        I1 => s_clk_40,
        S  => clk_sel_i(0)
    );

    BUFGMUX_inst2 : BUFGMUX
    port map(
        O  => mux2_out,
        I0 => s_clk_74,
        I1 => s_clk_108,
        S  => clk_sel_i(0)
    );

    BUFGMUX_inst3 : BUFGMUX
    port map(
        O  => mux3_out,
        I0 => mux1_out,
        I1 => mux2_out,
        S  => clk_sel_i(1)
    );
    BUFGMUX_inst4 : BUFGMUX
    port map(
        O  => s_px_clk,
        I0 => mux3_out,
        I1 => s_clk_148,
        S  => clk_sel_i(2)
    );

    PX_CLK_O <= s_px_clk;
    READY_O  <= s_pll_locked;

end architecture;