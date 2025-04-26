-- File: uart_tx.vhd
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- UART transmitter with manual data input via switches and start via button.
-- Set 8-bit data on SW[7:0], press BTN0 to load and send.

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
    constant BAUD_TICK_COUNT : integer := CLOCK_FREQ / BAUD_RATE;  -- ? 868

    type state_type is (IDLE, START, DATA, STOP);
    signal state         : state_type := IDLE;
    signal baud_counter  : integer range 0 to BAUD_TICK_COUNT := 0;
    signal bit_index     : integer range 0 to 7 := 0;
    signal shift_reg     : std_logic_vector(7 downto 0) := (others => '0');
    signal tx_reg        : std_logic := '1';
    signal start_prev    : std_logic := '0';
begin
    tx <= tx_reg;

    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                state        <= IDLE;
                baud_counter <= 0;
                bit_index    <= 0;
                shift_reg    <= (others => '0');
                tx_reg       <= '1';
                start_prev   <= '0';

            else
                -- detect rising edge of start_btn
                start_prev <= start_btn;

                case state is
                    when IDLE =>
                        tx_reg <= '1';
                        -- on button press, load data and start
                        if (start_btn = '1' and start_prev = '0') then
                            shift_reg    <= data_in;
                            baud_counter <= 0;
                            bit_index    <= 0;
                            tx_reg       <= '0';  -- start bit
                            state        <= DATA;
                        end if;

                    when DATA =>
                        -- send data bits LSB first
                        if baud_counter = BAUD_TICK_COUNT-1 then
                            baud_counter <= 0;
                            if bit_index < 7 then
                                bit_index <= bit_index + 1;
                                tx_reg    <= shift_reg(bit_index);
                            else
                                -- all data bits done, go to STOP
                                state     <= STOP;
                                tx_reg    <= '1';  -- stop bit
                                bit_index <= 0;
                            end if;
                        else
                            baud_counter <= baud_counter + 1;
                        end if;

                    when STOP =>
                        -- hold stop bit for one bit period
                        if baud_counter = BAUD_TICK_COUNT-1 then
                            baud_counter <= 0;
                            state        <= IDLE;
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

-- Constraints example (Basys3 rev C):
-- Map tx to USB-UART RXD (FPGA pin A18)
-- set_property PACKAGE_PIN A18 [get_ports tx]
-- set_property IOSTANDARD LVCMOS33 [get_ports tx]
-- Map switches SW7..SW0 (FPGA pins C4,D4,C3,D3,C2,D2,C1,D1)
-- set_property PACKAGE_PIN C4  [get_ports {data_in(7)}]
-- set_property PACKAGE_PIN D4  [get_ports {data_in(6)}]
-- set_property PACKAGE_PIN C3  [get_ports {data_in(5)}]
-- set_property PACKAGE_PIN D3  [get_ports {data_in(4)}]
-- set_property PACKAGE_PIN C2  [get_ports {data_in(3)}]
-- set_property PACKAGE_PIN D2  [get_ports {data_in(2)}]
-- set_property PACKAGE_PIN C1  [get_ports {data_in(1)}]
-- set_property PACKAGE_PIN D1  [get_ports {data_in(0)}]
-- Map start button BTN0 to start_btn
-- set_property PACKAGE_PIN W4  [get_ports start_btn]
-- set_property IOSTANDARD LVCMOS33 [get_ports {start_btn, reset}]
-- Map BTN1 to reset
-- set_property PACKAGE_PIN U18 [get_ports reset]
