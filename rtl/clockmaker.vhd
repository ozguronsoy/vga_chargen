library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library UNISIM;
use UNISIM.VComponents.all;

entity clockmaker is
    Port(
        SYSCLK_I  : in std_logic;
        RST_I     : in std_logic;
        CLK_SEL_I : in std_logic_vector(2 downto 0); -- Switch girişi
        PX_CLK_O  : out std_logic;
        READY_O   : out std_logic 
    );
end entity;

architecture rtl of clockmaker is

    component clk_wiz_0 is
        port(
            clk108_o : out std_logic;
            clk148_o : out std_logic;
            reset    : in  std_logic;
            locked   : out std_logic;
            sysclk_i : in  std_logic
        );
    end component;

    signal s_clk_108    : std_logic := '0';
    signal s_clk_148    : std_logic := '0';
    signal s_pll_locked : std_logic := '0';
    signal s_mux_sel    : std_logic := '0';

begin

    clk_wiz_inst : clk_wiz_0
    port map(
        sysclk_i => SYSCLK_I,
        reset    => RST_I,
        clk108_o => s_clk_108, 
        clk148_o => s_clk_148, 
        locked   => s_pll_locked
    );

    process(CLK_SEL_I) begin
        if CLK_SEL_I = "100" then
            s_mux_sel <= '1'; -- 148 MHz
        else
            s_mux_sel <= '0'; -- 108 MHz
        end if;
    end process;

    
    BUFGMUX_inst : BUFGMUX
    port map(
        O  => PX_CLK_O,
        I0 => s_clk_108,
        I1 => s_clk_148,
        S  => s_mux_sel
    );

    READY_O <= s_pll_locked;

end architecture;