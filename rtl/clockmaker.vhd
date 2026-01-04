library ieee;
use ieee.std_logic_1164.all;

library UNISIM;
use UNISIM.VComponents.all;

entity clockmaker is
    Port(
        SYSCLK_I  : in std_logic;
        RST_I     : in std_logic;
        CLK_SEL_I : in std_logic_vector(1 downto 0); -- 3-bit switch
        PX_CLK_O  : out std_logic; -- Global buffered output
        READY_O   : out std_logic 
    );
end entity;

architecture rtl of clockmaker is

    -- Updated component to match your new IP
    component clocking_wizard is
        port(
            clk_out1 : out std_logic;
            clk_out2 : out std_logic;
            clk_out3 : out std_logic;
            clk_out4 : out std_logic;
            reset    : in  std_logic;
            locked   : out std_logic;
            clk_in1  : in  std_logic
        );
    end component;

    -- Raw signals (Must be unbuffered from IP)
    signal s_clk1_raw, s_clk2_raw : std_logic;
    signal s_clk3_raw, s_clk4_raw : std_logic;
    
    signal s_clk_muxed  : std_logic; -- Intermediate wire
    signal s_pll_locked : std_logic;

begin

    -- Instance of the new IP
    inst_clk_wiz : clocking_wizard
    port map(
        clk_in1  => SYSCLK_I,
        reset    => RST_I,
        clk_out1 => s_clk1_raw, -- 25.175 MHz (Example)
        clk_out2 => s_clk2_raw, -- 40 MHz
        clk_out3 => s_clk3_raw, -- 54 MHz
        clk_out4 => s_clk4_raw, -- 74.25 MHz
        locked   => s_pll_locked
    );

    -- Combinational Mux Logic (LUT based)
    -- Using the lower 2 bits of the switch to select 4 clocks
    process(CLK_SEL_I, s_clk1_raw, s_clk2_raw, s_clk3_raw, s_clk4_raw) 
    begin
        case CLK_SEL_I(1 downto 0) is
            when "00"   => s_clk_muxed <= s_clk1_raw;
            when "01"   => s_clk_muxed <= s_clk2_raw;
            when "10"   => s_clk_muxed <= s_clk3_raw;
            when "11"   => s_clk_muxed <= s_clk4_raw;
            when others => s_clk_muxed <= s_clk1_raw; -- Default
        end case;
    end process;

    -- Final Global Buffer
    -- Drives the selected clock to the global tree
    BUFG_inst : BUFG
    port map(
        O => PX_CLK_O,   
        I => s_clk_muxed 
    );

    READY_O <= s_pll_locked;

end architecture;