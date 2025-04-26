library IEEE;
use IEEE.std_logic_1164.all;

entity uart_rx is
    Port (
        clk        : in  std_logic;
        reset      : in  std_logic;
        rx         : in  std_logic;
        data_out   : out std_logic_vector(7 downto 0);
        done       : out std_logic
    );
end uart_rx;

architecture Behavioral of uart_rx is
    constant CLOCK_FREQ      : integer := 100000000;  -- Basys 3 clock
    constant BAUD_RATE       : integer := 115200; --baud rate
    constant BAUD_TICK_COUNT : integer := CLOCK_FREQ / BAUD_RATE;  -- ≈868

    type state_type is (IDLE, START, DATA, STOP);
    signal state      : state_type := IDLE;
    signal baud_count : integer := 0;
    signal bit_index  : integer := 0;
    signal rx_shift   : std_logic_vector(7 downto 0) := (others => '0');
    signal done_reg   : std_logic := '0';
begin
    done <= done_reg;

    process(clk)
    begin
        if rising_edge(clk) then
            done_reg <= '0';  -- Default done signal to 0 each clock
            if reset = '1' then
                state <= IDLE;
                baud_count <= 0;
                bit_index <= 0;
                rx_shift <= (others => '0');
                done_reg <= '0';
            else
                case state is
                    when IDLE =>
                        if rx = '0' then
                            state <= START;
                            baud_count <= 0;
                        end if;

                        when START =>
                        if baud_count = BAUD_TICK_COUNT / 2 then
                            if rx = '0' then  -- Confirm it's still a start bit
                                baud_count <= 0;
                                bit_index <= 0;
                                state <= DATA;
                            else
                                -- False start, go back to IDLE
                                state <= IDLE;
                            end if;
                        else
                            baud_count <= baud_count + 1;
                        end if;
                    
                    when DATA =>
                        if baud_count = BAUD_TICK_COUNT then
                            baud_count <= 0;
                            rx_shift(bit_index) <= rx;
                            if bit_index = 7 then
                                state <= STOP;
                            else
                                bit_index <= bit_index + 1;
                            end if;
                        else
                            baud_count <= baud_count + 1;
                        end if;

                    when STOP =>
                        if baud_count = BAUD_TICK_COUNT then
                            baud_count <= 0;
                            data_out <= rx_shift;
                            done_reg <= '1';
                            state <= IDLE;
                        else
                            baud_count <= baud_count + 1;
                        end if;
                end case;
            end if;
        end if;
    end process;
end Behavioral;
