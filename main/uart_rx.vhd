-- File: uart_rx.vhd
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity uart_rx is
    generic (
        CLKS_PER_BIT : integer := 868    -- 100e6/115200
    );
    port (
        i_Clock     : in  std_logic;                 -- system clock
        i_Rx_Serial : in  std_logic;                 -- serial data in
        o_Rx_Byte   : out std_logic_vector(7 downto 0); -- received byte
        o_Rx_DV     : out std_logic                  -- data valid pulse
    );
end entity uart_rx;

architecture Behavioral of uart_rx is
    type state_type is (IDLE, START, DATA, STOP);
    signal state      : state_type := IDLE;
    signal clk_cnt    : integer range 0 to CLKS_PER_BIT := 0;
    signal bit_index  : integer range 0 to 7 := 0;
    signal rx_shift   : std_logic_vector(7 downto 0) := (others => '0');
begin
    process(i_Clock)
    begin
        if rising_edge(i_Clock) then
            case state is
                when IDLE =>
                    o_Rx_DV <= '0';
                    clk_cnt <= 0;
                    bit_index <= 0;
                    if i_Rx_Serial = '0' then  -- start bit detected
                        state <= START;
                    end if;

                when START =>
                    if clk_cnt = CLKS_PER_BIT/2 - 1 then
                        clk_cnt <= 0;
                        state <= DATA;
                    else
                        clk_cnt <= clk_cnt + 1;
                    end if;

                when DATA =>
                    if clk_cnt < CLKS_PER_BIT-1 then
                        clk_cnt <= clk_cnt + 1;
                    else
                        clk_cnt <= 0;
                        rx_shift(bit_index) <= i_Rx_Serial;
                        if bit_index < 7 then
                            bit_index <= bit_index + 1;
                        else
                            state <= STOP;
                        end if;
                    end if;

                when STOP =>
                    if clk_cnt < CLKS_PER_BIT-1 then
                        clk_cnt <= clk_cnt + 1;
                    else
                        o_Rx_Byte <= rx_shift;
                        o_Rx_DV <= '1';
                        clk_cnt <= 0;
                        state <= IDLE;
                    end if;
            end case;
        end if;
    end process;
end architecture Behavioral;