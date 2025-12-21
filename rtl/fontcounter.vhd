
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fontcounter is
    generic(
        c_bit_w   : integer := 8;
        c_bit_d   : integer := 8;
        c_char_w  : integer := 160;
        c_char_d  : integer := 90;
        c_ptr_max : integer := 14400
    );
    port(
        clk_i         : in std_logic ;
        vga_visible_i : in std_logic ;
        o_bit_wptr    : out integer range 0 to c_bit_w-1  ;
        o_bit_dptr    : out integer range 0 to c_bit_d-1  ;
        o_char_wptr   : out integer range 0 to c_char_w-1 ;
        o_char_ptr    : out integer range 0 to c_ptr_max-1
    );
end entity;

architecture rtl of data_mem is

    -- Sinyaller
    signal s_bit_wptr  : integer range 0 to c_bit_w-1  := 0;
    signal s_bit_dptr  : integer range 0 to c_bit_d-1  := 0;
    signal s_char_wptr : integer range 0 to c_char_w-1 := 0;
    signal s_char_ptr  : integer range 0 to c_ptr_max-1 := 0;
    
    signal s_vga_visible_prev : std_logic := '0';

begin

    process (clk_i) is begin
        if rising_edge(clk_i) then
            
            s_vga_visible_prev <= vga_visible_i;

            if vga_visible_i = '1' then
                if s_bit_wptr = c_bit_w-1 then
                    s_bit_wptr <= 0;
                    if s_char_wptr < c_char_w-1 then
                        s_char_wptr <= s_char_wptr + 1;
                        s_char_ptr  <= s_char_ptr + 1;
                    end if;
                else
                    s_bit_wptr <= s_bit_wptr + 1;
                end if;

            elsif (s_vga_visible_prev = '1' and vga_visible_i = '0') then
                
                s_char_wptr <= 0;
                
                if s_bit_dptr = c_bit_d-1 then
                    s_bit_dptr <= 0;
                    
                    if s_char_ptr = c_ptr_max-1 then 
                        s_char_ptr <= 0; 
                    else
                        s_char_ptr <= s_char_ptr + 1;
                    end if;
                else
                    s_bit_dptr <= s_bit_dptr + 1;
                    
                    if s_char_ptr >= (c_char_w - 1) then
                        s_char_ptr <= s_char_ptr - (c_char_w - 1);
                    else
                        s_char_ptr <= 0; 
                    end if;
                end if;
            end if;
            
        end if;
    end process;

    o_bit_wptr  <= s_bit_wptr;
    o_bit_dptr  <= s_bit_dptr;
    o_char_wptr <= s_char_wptr;
    o_char_ptr  <= s_char_ptr;

end architecture;