-- File: uart_tx.vhd
-- File: uart_tx.vhd
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity uart_tx is
    generic (
        CLKS_PER_BIT : integer := 868    -- 100e6/115200
    );
    port (
        i_Clock     : in  std_logic;                 -- system clock
        i_Tx_DV     : in  std_logic;                 -- data valid pulse
        i_Tx_Byte   : in  std_logic_vector(7 downto 0); -- byte to send
        o_Tx_Serial : out std_logic;                 -- serial data out
        o_Tx_Active : out std_logic;                 -- high while sending
        o_Tx_Done   : out std_logic                  -- done pulse
    );
end entity uart_tx;

architecture Behavioral of uart_tx is
    type state_type is (IDLE, START, DATA, STOP, CLEAN);
    signal state      : state_type := IDLE;
    signal clk_cnt    : integer range 0 to CLKS_PER_BIT := 0;
    signal bit_index  : integer range 0 to 7 := 0;
    signal tx_data    : std_logic_vector(7 downto 0) := (others => '0');
    signal tx_active  : std_logic := '0';
    signal tx_done    : std_logic := '0';
begin
    o_Tx_Active <= tx_active;
    o_Tx_Done   <= tx_done;

    process(i_Clock)
    begin
        if rising_edge(i_Clock) then
            tx_done <= '0';
            case state is
                when IDLE =>
                    o_Tx_Serial <= '1';
                    clk_cnt <= 0;
                    bit_index <= 0;
                    tx_active <= '0';
                    if i_Tx_DV = '1' then
                        tx_data <= i_Tx_Byte;
                        tx_active <= '1';
                        state <= START;
                    end if;

                when START =>
                    o_Tx_Serial <= '0';
                    if clk_cnt < CLKS_PER_BIT-1 then
                        clk_cnt <= clk_cnt + 1;
                    else
                        clk_cnt <= 0;
                        state <= DATA;
                    end if;

                when DATA =>
                    o_Tx_Serial <= tx_data(bit_index);
                    if clk_cnt < CLKS_PER_BIT-1 then
                        clk_cnt <= clk_cnt + 1;
                    else
                        clk_cnt <= 0;
                        if bit_index < 7 then
                            bit_index <= bit_index + 1;
                        else
                            state <= STOP;
                        end if;
                    end if;

                when STOP =>
                    o_Tx_Serial <= '1';
                    if clk_cnt < CLKS_PER_BIT-1 then
                        clk_cnt <= clk_cnt + 1;
                    else
                        clk_cnt <= 0;
                        tx_done <= '1';
                        tx_active <= '0';
                        state <= CLEAN;
                    end if;

                when CLEAN =>
                    state <= IDLE;
            end case;
        end if;
    end process;
end architecture Behavioral;