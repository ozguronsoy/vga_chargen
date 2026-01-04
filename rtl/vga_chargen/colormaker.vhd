library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity colormaker is
    port (
        PX_CLK_I    : in std_logic;
        VISIBLE_I   : in std_logic;
        PX_DAT_I    : in std_logic;
        FONT_CLR_I  : in std_logic_vector(2 downto 0);
        BKGR_CLR_I  : in std_logic_vector(2 downto 0);
        VGA_HSYNC_I : in std_logic;
        VGA_VSYNC_I : in std_logic;

        VGA_R_O     : out std_logic;
        VGA_G_O     : out std_logic;
        VGA_B_O     : out std_logic;
        VGA_HSYNC_O : out std_logic;
        VGA_VSYNC_O : out std_logic
    );
end entity;

architecture rtl of colormaker is

begin

    P_SEQ_PROC : process (PX_CLK_I) is begin
        if rising_edge(PX_CLK_I) then
            if VISIBLE_I = '1' then
                if PX_DAT_I = '1' then
                    VGA_R_O <= FONT_CLR_I(2);
                    VGA_G_O <= FONT_CLR_I(1);
                    VGA_B_O <= FONT_CLR_I(0);
                else
                    VGA_R_O <= BKGR_CLR_I(2);
                    VGA_G_O <= BKGR_CLR_I(1);
                    VGA_B_O <= BKGR_CLR_I(0);                
                end if;
            else
                VGA_R_O <= '0';
                VGA_G_O <= '0';
                VGA_B_O <= '0';
            end if;
        end if;
    end process;
    
    P_PIPE_DELAY : process (PX_CLK_I) is begin
        if rising_edge(PX_CLK_I) then
            VGA_HSYNC_O <= VGA_HSYNC_I;
            VGA_VSYNC_O <= VGA_VSYNC_I;
        end if;
    end process;

end architecture;