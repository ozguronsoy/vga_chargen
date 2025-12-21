library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity combinedgenerator is
    port (
        clk   : in std_logic;
        reset : in std_logic;
        
    );
end entity;

architecture rtl of combinedgenerator is
    constant c_bit_w   : integer := 8;
    constant c_bit_d   : integer := 8;
    constant c_char_w  : integer := 160;
    constant c_char_d  : integer := 90;
    constant c_ptr_max : integer := 14400;


    component vgasigen is
        generic (
            c_hactv    : integer := 1280; 
            c_hftph    : integer := 110;  
            c_hsync    : integer := 40;   
            c_hbkph    : integer := 220;  
            c_vactv    : integer := 720;  
            c_vftph    : integer := 5;    
            c_vsync    : integer := 5;    
            c_vbkph    : integer := 20;   
            c_polarity : string  := "positive"
        );
        port(
            clk_i     : in  std_logic; 
            i_rst     : in  std_logic; 
            o_hsync   : out std_logic; 
            o_vsync   : out std_logic; 
            o_visible : out std_logic
        );
    end component;

    component fontcounter is
        generic(
            c_bit_w   : integer := 8;
            c_bit_d   : integer := 8;
            c_char_w  : integer := 160;
            c_char_d  : integer := 90;
            c_ptr_max : integer := 14400
        );
        port(
            clk_i         : in std_logic;
            vga_visible_i : in std_logic;
            o_bit_wptr    : out integer range 0 to c_bit_w-1 ;
            o_bit_dptr    : out integer range 0 to c_bit_d-1 ;
            o_char_wptr   : out integer range 0 to c_char_w-1;
            o_char_ptr    : out integer range 0 to c_ptr_max-1
        );
    end component;


    signal s_hsync     : std_logic := '0';
    signal s_vsync     : std_logic := '0';
    signal s_visible   : std_logic := '0';
    signal s_bit_wptr  : integer range 0 to c_bit_w-1 ;
    signal s_bit_dptr  : integer range 0 to c_bit_d-1 ;
    signal s_char_wptr : integer range 0 to c_char_w-1;
    signal s_char_ptr  : integer range 0 to c_ptr_max-1


begin



    

end architecture;