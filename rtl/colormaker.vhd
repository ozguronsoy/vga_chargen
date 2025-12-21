library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity colormaker is
    port (
        clk_i      : in  std_logic;
        visible_i  : in  std_logic;
        px_font_i  : in  std_logic;
        font_clr_i : in  std_logic_vector(2 downto 0);
        bkgr_clr_i : in  std_logic_vector(2 downto 0);
        vga_r_o    : out std_logic;
        vga_g_o    : out std_logic;
        vga_b_o    : out std_logic
    );
end entity;

architecture rtl of colormaker is begin

    P_SEQ_PROC : process (clk_i) is begin
        if rising_edge(clk_i) then
            if visible_i = '1' then
                if px_font_i = '1' then
                    vga_r_o <= font_clr_i(2);
                    vga_g_o <= font_clr_i(1);
                    vga_b_o <= font_clr_i(0);
                else
                    vga_r_o <= bkgr_clr_i(2);
                    vga_g_o <= bkgr_clr_i(1);
                    vga_b_o <= bkgr_clr_i(0);                
                end if;
            else
                vga_r_o <= '0';
                vga_g_o <= '0';
                vga_b_o <= '0';
            end if;
        end if;
    end process;
    
end architecture;