-- In this module we need to apply rising edge detector because uart module has different clock domain.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity datawriter is
    generic(
        G_SYSCLK_FREQ : integer := 100_000_000;
        G_BAUD_RATE   : integer := 115_200;
        G_MEM_DEPTH   : integer := (1920/16)*(1080/16)
    );
    port(
        -- Top Signals
        SYSCLK_I   : in  std_logic;
        RST_I      : in  std_logic;
        UART_DAT_I : in  std_logic;
        -- To DataMem
        MEM_DAT_O  : out std_logic_vector(15 downto 0);
        MEM_ADR_O  : out unsigned(integer(ceil(log2(real(G_MEM_DEPTH))))-1 downto 0);
        MEM_WREN_O : out std_logic;
        -- To ColorMaker
        BUSY_O     : out std_logic
    );
end entity;

architecture rtl of datawriter is

    constant c_addr_width : integer := integer(ceil(log2(real(G_MEM_DEPTH))));

    -- GluGlu signals.
    signal s_uart_valid    : std_logic := '0';
    signal s_uart_valid_p  : std_logic := '0';
    signal s_uart_valid_p2 : std_logic := '0';

    signal s_uart_data     : std_logic_vector(7 downto 0) := (others => '0');
   
    signal s_byte_toggle   : std_logic := '0';
    signal s_byte_toggle_p : std_logic := '0';

    signal s_mem_adr       : integer range 0 to G_MEM_DEPTH-1 := -1;
    signal s_writedata     : std_logic_vector(15 downto 0) := (others => '0');


begin

    uart_rx_inst : entity work.uart_rx
    generic map(
        G_SYSCLK_FREQ => G_SYSCLK_FREQ,
        G_BAUD_RATE   => G_BAUD_RATE
    )
    port map(
        SYSCLK_I    => SYSCLK_I,
        RST_I       => RST_I,
        UART_DAT_I  => UART_DAT_I,
        DAT_REDY_O  => s_uart_valid,
        UART_DAT_O  => s_uart_data
    );

    P_SEQ_PROC : process (SYSCLK_I) is begin
        if rising_edge(SYSCLK_I) then
            if RST_I = '1' then

                s_uart_valid    <= '0';
                s_uart_valid_p  <= '0';
                s_byte_toggle   <= '0';
                s_byte_toggle_p <= '0';
                s_mem_adr       <= -1 ;
                s_writedata     <= (others => '0');
                s_mem_dat       <= (others => '0');

            else

                s_uart_valid_p  <= s_uart_valid;
                s_byte_toggle_p <= s_byte_toggle;
                s_byte_toggle_p2 <= s_byte_toggle_p;
                
                -- Data Control (Input Handler).
                if s_uart_valid_p = '0' and s_uart_valid = '1' then
                    if s_byte_toggle = '0' then
                        s_writedata(15 downto 8) <= s_uart_data;
                        s_byte_toggle            <= '1';
                    else
                        s_writedata(7 downto 0)  <= s_uart_data;
                        s_byte_toggle            <= '0';
                    end if;
                end if;

                -- Write Sequence (Output Handler).
                if s_byte_toggle_p = '1' and s_byte_toggle = '0' then -- when 2 byte are registered,
                    s_mem_dat  <= s_writedata;
                    s_mem_adr  <= s_mem_adr + 1;
                    r_mem_wren <= '1';
                    r_busy     <= '1';
                elsif (s_mem_adr = G_MEM_DEPTH-1) and (s_byte_toggle_p2 & s_byte_toggle_p & s_byte_toggle = "000") then -- after 2 cycle of write seq and eol.
                    s_mem_dat  <= (others => '0');
                    s_mem_adr  <= -1;
                    r_busy     <= '0';
                else
                    s_mem_dat  <= (others => '0');
                    r_mem_wren <= '0';
                end if;

            end if;
        end if;
    end process;

    MEM_DAT_O  <= s_mem_dat;
    MEM_ADR_O  <= to_unsigned(s_mem_adr, MEM_ADR_O'length);
    MEM_WREN_O <= r_mem_wren;
    BUSY_O     <= r_busy;

end architecture;