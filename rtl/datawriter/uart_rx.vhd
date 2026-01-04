library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_rx is
    generic (
        G_SYSCLK_FREQ : integer := 100_000_000;
        G_BAUD_RATE   : integer := 115_200
    );
    port (
        SYSCLK_I   : in  std_logic;
        RST_I      : in  std_logic;
        UART_DAT_I : in  std_logic;
        DAT_REDY_O : out std_logic;
        UART_DAT_O : out std_logic_vector(7 downto 0)
    );
end entity uart_rx;

architecture rtl of uart_rx is

    constant c_clks_per_bit : integer := G_SYSCLK_FREQ / G_BAUD_RATE;

    -- State Machine
    type t_state is (st_IDLE, st_START, st_DATA, st_STOP);
    signal s_state : t_state := st_IDLE;

    signal s_baud_cnt   : integer range 0 to c_clks_per_bit - 1 := 0;
    signal s_bit_idx    : integer range 0 to 7 := 0;
    signal s_rx_shreg   : std_logic_vector(7 downto 0) := (others => '0');
    
    -- Sync uart input
    signal r_rx_sync    : std_logic_vector(1 downto 0) := (others => '1');
    signal s_rx_input   : std_logic;

begin

    -- Safe data input
    P_SEQ_SYNCProc : process(SYSCLK_I)
    begin
        if rising_edge(SYSCLK_I) then
            r_rx_sync <= r_rx_sync(0) & UART_DAT_I;
        end if;
    end process;

    s_rx_input <= r_rx_sync(1);

    -- Main Process
    P_SEQ_MAINProc : process(SYSCLK_I)
    begin
        if rising_edge(SYSCLK_I) then
            if RST_I = '1' then
                s_state     <= st_IDLE;
                s_baud_cnt  <= 0;
                s_bit_idx   <= 0;
                DAT_REDY_O  <= '0';
                s_rx_shreg  <= (others => '0');
                UART_DAT_O  <= (others => '0');
            else
                case s_state is
                    when st_IDLE =>
                        DAT_REDY_O <= '0';
                        s_baud_cnt <= 0;
                        s_bit_idx  <= 0;

                        if s_rx_input = '0' then
                            s_state <= st_START;
                        end if;

                    when st_START =>
                        if s_baud_cnt = (c_clks_per_bit / 2) - 1 then
                            if s_rx_input = '0' then
                                s_baud_cnt <= 0;
                                s_state    <= st_DATA;
                            else
                                s_state    <= st_IDLE;
                            end if;
                        else
                            s_baud_cnt <= s_baud_cnt + 1;
                        end if;

                    when st_DATA =>
                        if s_baud_cnt = c_clks_per_bit - 1 then
                            s_baud_cnt <= 0;
                            s_rx_shreg <= s_rx_input & s_rx_shreg(7 downto 1);
                            if s_bit_idx = 7 then
                                s_state <= st_STOP;
                            else
                                s_bit_idx <= s_bit_idx + 1;
                            end if;
                        else
                            s_baud_cnt <= s_baud_cnt + 1;
                        end if;

                    when st_STOP =>
                        if s_baud_cnt = c_clks_per_bit - 1 then
                            DAT_REDY_O <= '1';
                            UART_DAT_O <= s_rx_shreg;
                            s_state    <= st_IDLE;
                        else
                            s_baud_cnt <= s_baud_cnt + 1;
                        end if;

                    when others =>
                        s_state <= st_IDLE;

                end case;
            end if;
        end if;
    end process;

end architecture;