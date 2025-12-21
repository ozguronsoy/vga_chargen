
-- NOTE: Warning! This module uses multiplier DSP. (Multiply and add)
-- NOTE: Warning! 3 Series do not include fused-multiply-add. so you need to make in pipelined structure!
-- NOTE: This implementation is for 7 series fused-multiply-add hardwares.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity asciilut is
    port(
        clk_i       : in std_logic;
        rst_i       : in std_logic;
        ascii_dat_i : in std_logic_vector(6 downto 0);
        ascii_col_i : in integer range 0 to 7;
        ascii_raw_i : in integer range 0 to 7;
        px_dat_o    : out std_logic
    );
end entity;

architecture rtl of asciilut is
    constant c_ascii_table_max : integer := 100;
    constant c_ascii_bitmap_depth : integer := 8;

    type t_asciilut is array (0 to 8*c_ascii_table_max-1) of std_logic_vector(7 downto 0);
    signal s_asciilut : t_asciilut := (others => (others => '0')); -- write data into here

    signal s_ascii_table_ptr : integer range 0 to 8*c_ascii_table_max-1 := 0;
    signal s_ascii_bitmap_depth : integer := 8;

    signal s_read_data : std_logic_vector(7 downto 0) := (others => '0');

    signal s_px_dat : std_logic := '0';

begin

    P_SEQ_PROC : process (clk_i) is begin
        if rising_edge(clk_i) then
            -- Fused-multiply-add
            -- NOTE : Supporting in 7 series DSP's. 1 FFs.
            s_ascii_table_ptr <= (ascii_dat_i * s_ascii_bitmap_depth) + ascii_raw_i;
            -- FF2
            s_read_data <= s_asciilut(s_ascii_table_ptr);
            -- FF3
            s_px_dat <= s_read_data(ascii_col_i);

        end if;
    end process;

    px_dat_o <= s_px_dat;

end architecture;