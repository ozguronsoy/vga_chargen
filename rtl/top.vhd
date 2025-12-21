library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top is
    port(
        clk_i       : in std_logic;
        rst_i       : in std_logic;
        vga_hsync_o : out std_logic;
        vga_vsync_o : out std_logic;
        vga_r_o     : out std_logic;
        vga_g_o     : out std_logic;
        vga_b_o     : out std_logic
    );
end entity;

architecture rtl of top is

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
        i_div_clk : in  std_logic; 
        i_rst     : in  std_logic; 
        o_hsync   : out std_logic; 
        o_vsync   : out std_logic; 
        o_visible : out std_logic;
        o_bof     : out std_logic
    );
end component;

component datamem is
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
end component;



component colormaker is
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
end component;


begin

    

end architecture;