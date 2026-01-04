-- VGA Char Generator Project
-- DONE
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;             
use ieee.std_logic_textio.all; 

-- ascii data hardcoded to 7.

entity datamem is
    generic(
        G_DATAMEM_INITF : string;
        G_MAX_MEM_DEPTH : integer
    );
    port(
        PX_CLK_I    : in std_logic;
        CHAR_PTR_I  : in  unsigned(13 downto 0);
        WREN_I      : in std_logic;
        WRDAT_I     : in std_logic_vector(15 downto 0);
        WRADR_I     : in unsigned(integer(ceil(log2(real(G_MAX_MEM_DEPTH))))-1 downto 0);
        -- OUTS
        ASCII_DAT_O : out std_logic_vector(6 downto 0);
        FONT_COL_O  : out std_logic_vector(2 downto 0);
        BKGR_COL_O  : out std_logic_vector(2 downto 0);
        -- PIPE
        VISIBLE_I   : in  std_logic;
        VGA_VSYNC_I : in  std_logic;
        VGA_HSYNC_I : in  std_logic;
        PTR_PX_X_I  : in  unsigned(5 downto 0);
        PTR_PX_Y_I  : in  unsigned(5 downto 0);
        VISIBLE_O   : out std_logic;
        VGA_VSYNC_O : out std_logic;
        VGA_HSYNC_O : out std_logic;
        PTR_PX_X_O  : out unsigned(5 downto 0);
        PTR_PX_Y_O  : out unsigned(5 downto 0)
    );
end entity;

architecture rtl of datamem is

    -- Memory type
    type t_ram is array (0 to G_MAX_MEM_DEPTH-1) of std_logic_vector(12 downto 0);

    -- :::::::::::::::::::::::::::::: WRITE INIT FILE TO MEMORY ::::::::::::::::::::::::::::::
    impure function InitRamFromFile (FileName : in string) return t_ram is
        file RamFile : text open read_mode is FileName;
        variable RamFileLine : line;
        variable RAM : t_ram;
        variable temp_vec : std_logic_vector(12 downto 0);
    begin 
        for i in 0 to G_MAX_MEM_DEPTH-1 loop
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
    signal s_ram : t_ram := InitRamFromFile(G_DATAMEM_INITF);
    -- :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
    
    -- Signals
    signal s_data_out : std_logic_vector(12 downto 0);

begin
    
    -- Main Logic
    process (PX_CLK_I) is begin
        if rising_edge(PX_CLK_I) then
            -- FF2
            s_data_out <= s_ram(to_integer(char_ptr_i));
        end if;
    end process;

    -- Outputs (comb.)
    -- Data Frame : [Background Color] [Font Color] [ASCII Data]
    BKGR_COL_O  <= s_data_out(12 downto 10);
    FONT_COL_O  <= s_data_out(9 downto 7);
    ASCII_DAT_O <= s_data_out(6 downto 0);


    -- PIPE LATENCY.
    process (PX_CLK_I) is begin
        if rising_edge(PX_CLK_I) then
            -- FF1
            VISIBLE_O   <= VISIBLE_I  ;
            VGA_VSYNC_O <= VGA_VSYNC_I;
            VGA_HSYNC_O <= VGA_HSYNC_I;
            PTR_PX_X_O  <= PTR_PX_X_I ;
            PTR_PX_Y_O  <= PTR_PX_Y_I ;
        end if;
    end process;

end architecture;