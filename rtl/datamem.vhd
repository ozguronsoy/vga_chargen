library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;             
use ieee.std_logic_textio.all; 

entity datamem is
    generic(
        c_depth     : integer := 14400;         
        c_width     : integer := 13;            
        c_init_f    : string  := "init_datamem.mem" 
    );
    port(
        clk_i       : in std_logic;
        char_ptr_i  : in integer range 0 to c_depth-1; 
        ascii_dat_o : out std_logic_vector(6 downto 0);
        font_col_o  : out std_logic_vector(2 downto 0);
        bkgr_col_o  : out std_logic_vector(2 downto 0)
    );
end entity;

architecture rtl of datamem is

    type t_ram is array (0 to c_depth-1) of std_logic_vector(c_width-1 downto 0);

    impure function InitRamFromFile (FileName : in string) return t_ram is
        file RamFile : text open read_mode is FileName;
        variable RamFileLine : line;
        variable RAM : t_ram;
        variable temp_vec : std_logic_vector(c_width-1 downto 0);
    begin
        for i in 0 to c_depth-1 loop
            if not endfile(RamFile) then
                readline(RamFile, RamFileLine);
                read(RamFileLine, temp_vec);
                RAM(i) := temp_vec;
            else
                RAM(i) := (others => '0'); -- If the file ends, fill with 0.
            end if;
        end loop;
        return RAM;
    end function;

    signal s_ram : t_ram := InitRamFromFile(c_init_f);
    
    signal s_data_out : std_logic_vector(c_width-1 downto 0);

begin

    process (clk_i) is begin
        if rising_edge(clk_i) then
                s_data_out <= s_ram(char_ptr_i);
        end if;
    end process;

    bkgr_col_o  <= s_data_out(12 downto 10);
    font_col_o  <= s_data_out(9 downto 7);
    ascii_dat_o <= s_data_out(6 downto 0);

end architecture;