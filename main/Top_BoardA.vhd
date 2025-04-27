----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 27.04.2025 22:12:52
-- Design Name: 
-- Module Name: Top_BoardA - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


-- Board A: PC ? generic uart_rx ? generic uart_tx ? PMOD JA
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity top_boardA is
    port(
        clk      : in  std_logic;                    -- 100 MHz system clock
        reset    : in  std_logic;                    -- active-high reset (BTN1)
        ftdi_rx  : in  std_logic;                    -- USB-UART TXD (PC ? FPGA)
        ja_tx    : out std_logic                     -- PMOD JA1 (FPGA ? Board B)
    );
end entity top_boardA;

architecture Behavioral of top_boardA is
    constant CLKS_PER_BIT : integer := 868;        -- 100e6/115200
    signal rx_byte        : std_logic_vector(7 downto 0);
    signal rx_dv          : std_logic;
begin
    -- Generic UART RX from PC
    U_RX: entity work.uart_rx
        generic map(CLKS_PER_BIT => CLKS_PER_BIT)
        port map(
            i_Clock     => clk,
            i_Rx_Serial => ftdi_rx,
            o_Rx_Byte   => rx_byte,
            o_Rx_DV     => rx_dv
        );

    -- Generic UART TX to PMOD JA
    U_TX: entity work.uart_tx
        generic map(CLKS_PER_BIT => CLKS_PER_BIT)
        port map(
            i_Clock     => clk,
            i_Tx_DV     => rx_dv,
            i_Tx_Byte   => rx_byte,
            o_Tx_Serial => ja_tx,
            o_Tx_Active => open,
            o_Tx_Done   => open
        );
end architecture Behavioral;