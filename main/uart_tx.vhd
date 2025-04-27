-- File: uart_tx.vhd
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- UART transmitter to send switch bits as ASCII '0'/'1'.
-- Set SW7..SW0, press BTN0 to send binary string SW7..SW0.

entity uart_tx is
    port(
        clk       : in  std_logic;                     -- 100 MHz system clock
        reset     : in  std_logic;                     -- active-high reset (BTN1)
        start_btn : in  std_logic;                     -- start transmission (BTN0)
        data_in   : in  std_logic_vector(7 downto 0);  -- bits to send (SW7..SW0)
        tx        : out std_logic                      -- UART serial output (idle high)
    );
end entity uart_tx;

architecture Behavioral of uart_tx is
    constant CLOCK_FREQ      : integer := 100_000_000;
    constant BAUD_RATE       : integer := 115200;
    constant TICKS_PER_BIT   : integer := CLOCK_FREQ / BAUD_RATE;  -- ? 868

    type state_type is (IDLE, START, DATA, STOP);
    signal state         : state_type := IDLE;
    signal baud_counter  : integer range 0 to TICKS_PER_BIT := 0;
    signal bit_index     : integer range 0 to 7 := 0;              -- for shift_reg bits
    signal data_index    : integer range 0 to 7 := 0;              -- which switch bit
    signal shift_reg     : std_logic_vector(7 downto 0) := (others => '0');
    signal start_prev    : std_logic := '0';
    signal tx_reg        : std_logic := '1';
begin
    tx <= tx_reg;

    process(clk)
    begin
        if rising_edge(clk) then
            start_prev <= start_btn;
            if reset = '1' then
                -- reset all
                state        <= IDLE;
                baud_counter <= 0;
                bit_index    <= 0;
                data_index   <= 0;
                shift_reg    <= (others => '0');
                tx_reg       <= '1';
            else
                case state is
                    when IDLE =>
                        tx_reg <= '1';  -- idle
                        -- on rising edge of start_btn: load first bit
                        if (start_btn = '1' and start_prev = '0') then
                            data_index <= 7;
                            -- load ASCII '0' or '1'
                            if data_in(7) = '1' then
                                shift_reg <= x"31";  -- '1'
                            else
                                shift_reg <= x"30";  -- '0'
                            end if;
                            baud_counter <= 0;
                            bit_index    <= 0;
                            state        <= START;
                        end if;

                    when START =>
                        tx_reg <= '0';  -- start bit
                        if baud_counter = TICKS_PER_BIT - 1 then
                            baud_counter <= 0;
                            state        <= DATA;
                        else
                            baud_counter <= baud_counter + 1;
                        end if;

                    when DATA =>
                        tx_reg <= shift_reg(bit_index);
                        if baud_counter = TICKS_PER_BIT - 1 then
                            baud_counter <= 0;
                            if bit_index = 7 then
                                state <= STOP;
                            else
                                bit_index <= bit_index + 1;
                            end if;
                        else
                            baud_counter <= baud_counter + 1;
                        end if;

                    when STOP =>
                        tx_reg <= '1';  -- stop bit
                        if baud_counter = TICKS_PER_BIT - 1 then
                            baud_counter <= 0;
                            -- prepare next bit or finish
                            if data_index > 0 then
                                data_index <= data_index - 1;
                                bit_index  <= 0;
                                -- load next ASCII char
                                if data_in(data_index-1) = '1' then
                                    shift_reg <= x"31";
                                else
                                    shift_reg <= x"30";
                                end if;
                                state <= START;
                            else
                                state <= IDLE;
                            end if;
                        else
                            baud_counter <= baud_counter + 1;
                        end if;

                    when others =>
                        state <= IDLE;
                end case;
            end if;
        end if;
    end process;
end architecture Behavioral;

-- Constraints (Basys3 rev C):
-- set_property PACKAGE_PIN A18 [get_ports tx]
-- set_property IOSTANDARD LVCMOS33 [get_ports tx]
-- set_property PACKAGE_PIN C4  [get_ports {data_in(7)}]
-- set_property PACKAGE_PIN D4  [get_ports {data_in(6)}]
-- set_property PACKAGE_PIN C3  [get_ports {data_in(5)}]
-- set_property PACKAGE_PIN D3  [get_ports {data_in(4)}]
-- set_property PACKAGE_PIN C2  [get_ports {data_in(3)}]
-- set_property PACKAGE_PIN D2  [get_ports {data_in(2)}]
-- set_property PACKAGE_PIN C1  [get_ports {data_in(1)}]
-- set_property PACKAGE_PIN D1  [get_ports {data_in(0)}]
-- set_property PACKAGE_PIN W4  [get_ports start_btn]
-- set_property PACKAGE_PIN U18 [get_ports reset]
-- set_property IOSTANDARD LVCMOS33 [get_ports {start_btn, reset}]

