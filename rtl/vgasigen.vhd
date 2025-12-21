library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vgasigen is
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
end entity;

architecture rtl of vgasigen is

    -- VGA Parameters for Hsync and Vsync signals.
    constant c_hmax : integer := c_hactv + c_hftph + c_hsync + c_hbkph;
    constant c_vmax : integer := c_vactv + c_vftph + c_vsync + c_vbkph;

    constant c_hs_start : integer := c_hactv + c_hftph;
    constant c_hs_end   : integer := c_hactv + c_hftph + c_hsync;
    constant c_vs_start : integer := c_vactv + c_vftph;
    constant c_vs_end   : integer := c_vactv + c_vftph + c_vsync;

    signal s_hcntr : integer range 0 to c_hmax-1 := 0;
    signal s_vcntr : integer range 0 to c_vmax-1 := 0;

    function get_idle_state(pol : string) return std_logic is
    begin
        if pol = "positive" then return '0'; else return '1'; end if;
    end function;
    
    function get_active_state(pol : string) return std_logic is
    begin
        if pol = "positive" then return '1'; else return '0'; end if;
    end function;

    constant c_idle_val   : std_logic := get_idle_state(c_polarity);
    constant c_active_val : std_logic := get_active_state(c_polarity);

    -- Internal Signals
    signal s_hsync   : std_logic := c_idle_val;
    signal s_vsync   : std_logic := c_idle_val;
    signal s_visible : std_logic := '0';
    signal s_bof     : std_logic := '0';

begin

    P_VGA_TIMING : process (clk_i) is
    begin
        if rising_edge(clk_i) then
            if i_rst = '1' then
                s_hcntr   <= 0;
                s_vcntr   <= 0;
                s_hsync   <= c_idle_val;
                s_vsync   <= c_idle_val;
                s_visible <= '0';
                s_bof     <= '0';
            else
                
                if s_hcntr < c_hmax - 1 then
                    s_hcntr <= s_hcntr + 1;
                else
                    s_hcntr <= 0;
                    if s_vcntr < c_vmax - 1 then
                        s_vcntr <= s_vcntr + 1;
                    else
                        s_vcntr <= 0;
                    end if;
                end if;
                
                -- FF1
                if (s_hcntr >= c_hs_start) and (s_hcntr < c_hs_end) then
                    s_hsync <= c_active_val;
                else
                    s_hsync <= c_idle_val;
                end if;

                if (s_vcntr >= c_vs_start) and (s_vcntr < c_vs_end) then
                    s_vsync <= c_active_val;
                else
                    s_vsync <= c_idle_val;
                end if;


                if (s_hcntr < c_hactv) and (s_vcntr < c_vactv) then
                    s_visible <= '1';
                else
                    s_visible <= '0';
                end if;

            end if;
        end if;
    end process;

    o_hsync   <= s_hsync;
    o_vsync   <= s_vsync;
    o_visible <= s_visible;

end architecture;