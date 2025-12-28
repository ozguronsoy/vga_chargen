library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity ps2kb is
    port(
        sys_clk_i : in std_logic;
        ps2_clk_i : in std_logic;
        data_i : in std_logic;

        -- indicates we fetched all bits of the key
        rx_ready_o : out std_logic;
        rx_o : out std_logic_vector(7 downto 0)
    );
end entity;

architecture rtl of ps2kb is

    signal ps2_clk_sync : std_logic_vector(1 downto 0) := "00";
    signal cntr : integer range 0 to 15 := 0;
    signal skip_cnt : integer range 0 to 7 := 0;
    signal parity : std_logic := '0';
    signal rx_ready : std_logic := '0';
    signal rx_data : std_logic_vector(7 downto 0) := x"00";

    -- ROM for mapping scan codes to ASCII

    type rom_type is array (0 to 255) of bit_vector(7 downto 0);
    
    impure function InitRomFromFile (RomFileName : in string) return rom_type is
        file RomFile : text open read_mode is RomFileName;
        variable RomFileLine : line;
        variable temp_bv : bit_vector(7 downto 0);
        variable rom : rom_type;
    begin
        for i in 0 to 255 loop
            readline(RomFile, RomFileLine);
            hread(RomFileLine, temp_bv);
            rom(i) := temp_bv;
        end loop;
        return rom;
    end function;

    -- Initialize the ROM signal
    signal ascii_map : rom_type := InitRomFromFile("kb_layout_tr_q.mem");

begin

    process(sys_clk_i) is begin

        if rising_edge(sys_clk_i) then

            ps2_clk_sync <= ps2_clk_sync(0) & ps2_clk_i;
            rx_ready_o <= rx_ready;
            rx_o <= rx_data;

            if rx_ready = '1' then
                rx_ready <= '0';
                parity <= '0';
            end if;

            if ps2_clk_sync = "10" then

                if (cntr = 0 and data_i = '0') or cntr /= 0 then
                    cntr <= cntr + 1;
                end if;

                case cntr is
                    when 1 to 8 => 
                        rx_data <= data_i & rx_data(7 downto 1);
                        if data_i = '1' then
                            -- the parity will be '1' when the number of ones in the data stream is and odd number, otherwise '0'.
                            -- e.g., for '01001000' parity will be '0'
                            parity <= not(parity);
                        end if;

                    when 9 =>
                        -- reuse the parity symbol to indicate the parity check has succeeded.
                        parity <= parity xor data_i;
                
                    when 10 =>
                        cntr <= 0;
                        if parity = '1' and data_i = '1' then
                        
                            if rx_data = x"F0" or rx_data = x"E0" then -- Release or Extended keys
                                skip_cnt <= 1;
                            elsif rx_data = x"E1" then
                                skip_cnt <= 2; -- Pause/Break
                            else
                                if skip_cnt = 0 then
                                    rx_ready <= '1';
                                    rx_data <= to_stdlogicvector(ascii_map(to_integer(unsigned(rx_data))));
                                else
                                    skip_cnt <= skip_cnt - 1;
                                end if;
                            end if;
                        
                        end if;

                    when others => null;
                end case;

            end if;

        end if;

    end process;

end architecture;