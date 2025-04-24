-- File: uart_tx.vhd
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_tx is
    generic (
        CLKS_PER_BIT : integer := 868  -- 100 MHz / 115200 ? 868
    );
    port (
        i_Clock     : in  std_logic;
        i_Tx_DV     : in  std_logic;               -- Assert for one cycle to send
        i_Tx_Byte   : in  std_logic_vector(7 downto 0);
        o_Tx_Active : out std_logic;               -- High while sending
        o_Tx_Serial : out std_logic := '1';        -- Idle high
        o_Tx_Done   : out std_logic                -- Pulses when byte done
    );
end entity;

architecture Behavioral of uart_tx is
    type state_type is (IDLE, START, DATA, STOP, CLEAN);
    signal state      : state_type := IDLE;
    signal clk_cnt    : integer range 0 to CLKS_PER_BIT := 0;
    signal bit_index  : integer range 0 to 7           := 0;
    signal tx_data    : std_logic_vector(7 downto 0)   := (others => '0');
    signal tx_active  : std_logic                     := '0';
    signal tx_done    : std_logic                     := '0';
begin
    o_Tx_Active <= tx_active;
    o_Tx_Done   <= tx_done;

    process(i_Clock)
    begin
        if rising_edge(i_Clock) then
            case state is
                when IDLE =>
                    o_Tx_Serial <= '1';
                    tx_done     <= '0';
                    clk_cnt     <= 0;
                    bit_index   <= 0;
                    if i_Tx_DV = '1' then
                        tx_data   <= i_Tx_Byte;
                        tx_active <= '1';
                        state     <= START;
                    end if;

                when START =>
                    o_Tx_Serial <= '0';
                    if clk_cnt < CLKS_PER_BIT-1 then
                        clk_cnt <= clk_cnt + 1;
                    else
                        clk_cnt <= 0;
                        state   <= DATA;
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
                            state     <= STOP;
                        end if;
                    end if;

                when STOP =>
                    o_Tx_Serial <= '1';
                    if clk_cnt < CLKS_PER_BIT-1 then
                        clk_cnt <= clk_cnt + 1;
                    else
                        clk_cnt    <= 0;
                        tx_done    <= '1';
                        tx_active  <= '0';
                        state      <= CLEAN;
                    end if;

                when CLEAN =>
                    tx_done <= '0';
                    state   <= IDLE;
            end case;
        end if;
    end process;
end architecture;

-- File: uart_rx.vhd
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_rx is
    generic (
        CLKS_PER_BIT : integer := 868
    );
    port(
        i_Clock    : in  std_logic;
        i_Rx_Serial: in  std_logic;
        o_Rx_Byte  : out std_logic_vector(7 downto 0) := (others => '0');
        o_Rx_DV    : out std_logic                   := '0'
    );
end entity;

architecture Behavioral of uart_rx is
    type state_type is (IDLE, START, DATA, STOP);
    signal state     : state_type := IDLE;
    signal clk_cnt   : integer range 0 to CLKS_PER_BIT := 0;
    signal bit_index : integer range 0 to 7           := 0;
    signal rx_shift  : std_logic_vector(7 downto 0)   := (others => '0');
begin
    process(i_Clock)
    begin
        if rising_edge(i_Clock) then
            case state is
                when IDLE =>
                    o_Rx_DV  <= '0';
                    clk_cnt  <= 0;
                    bit_index<= 0;
                    if i_Rx_Serial = '0' then           -- start bit detected
                        state <= START;
                    end if;

                when START =>
                    if clk_cnt = CLKS_PER_BIT/2-1 then
                        clk_cnt <= 0;
                        state   <= DATA;             -- sample at bit center
                    else
                        clk_cnt <= clk_cnt + 1;
                    end if;

                when DATA =>
                    if clk_cnt < CLKS_PER_BIT-1 then
                        clk_cnt <= clk_cnt + 1;
                    else
                        clk_cnt         <= 0;
                        rx_shift(bit_index) <= i_Rx_Serial;
                        if bit_index < 7 then
                            bit_index <= bit_index + 1;
                        else
                            state     <= STOP;
                        end if;
                    end if;

                when STOP =>
                    if clk_cnt < CLKS_PER_BIT-1 then
                        clk_cnt <= clk_cnt + 1;
                    else
                        o_Rx_Byte <= rx_shift;
                        o_Rx_DV   <= '1';
                        clk_cnt   <= 0;
                        state     <= IDLE;
                    end if;
            end case;
        end if;
    end process;
end architecture;

-- File: top_uart.vhd
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top_uart is
    port(
        clk   : in  std_logic;
        rst   : in  std_logic;
        rx_in : in  std_logic;                   -- PMOD Rx
        tx_out: out std_logic;                   -- PMOD Tx
        led   : out std_logic_vector(7 downto 0) -- display received byte
    );
end entity;

architecture Behavioral of top_uart is
    signal tx_busy, tx_done, rx_valid: std_logic;
    signal rx_byte, tx_byte           : std_logic_vector(7 downto 0) := (others => '0');
    signal tx_start                   : std_logic := '0';
begin
    U_RX: entity work.uart_rx
        generic map(CLKS_PER_BIT => 868)
        port map(
            i_Clock     => clk,
            i_Rx_Serial => rx_in,
            o_Rx_Byte   => rx_byte,
            o_Rx_DV     => rx_valid
        );

    U_TX: entity work.uart_tx
        generic map(CLKS_PER_BIT => 868)
        port map(
            i_Clock     => clk,
            i_Tx_DV     => tx_start,
            i_Tx_Byte   => tx_byte,
            o_Tx_Active => tx_busy,
            o_Tx_Serial => tx_out,
            o_Tx_Done   => tx_done
        );

    -- Echo received byte
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                tx_start <= '0';
            elsif rx_valid = '1' then
                tx_byte  <= rx_byte;
                tx_start <= '1';
            else
                tx_start <= '0';
            end if;
        end if;
    end process;

    led <= rx_byte;
end architecture;

