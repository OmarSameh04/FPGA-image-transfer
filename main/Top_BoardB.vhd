----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 27.04.2025 22:14:30
-- Design Name: 
-- Module Name: Top_BoardB - Behavioral
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


-- Board B: PMOD JB ? generic uart_rx ? generic uart_tx ? PC
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity top_boardB is
    port(
        clk      : in  std_logic;                    -- 100 MHz system clock
        reset    : in  std_logic;                    -- active-high reset (BTN1)
        jb_rx    : in  std_logic;                    -- PMOD JB2 (Board A ? FPGA)
        ftdi_tx  : out std_logic                     -- USB-UART RXD (FPGA ? PC)
    );
end entity top_boardB;

architecture Behavioral of top_boardB is
    constant CLKS_PER_BIT : integer := 868;        -- 100e6/115200
    signal rx_byteB       : std_logic_vector(7 downto 0);
    signal rx_dvB         : std_logic;
begin
    -- Generic UART RX from PMOD JB
    U_RX: entity work.uart_rx
        generic map(CLKS_PER_BIT => CLKS_PER_BIT)
        port map(
            i_Clock     => clk,
            i_Rx_Serial => jb_rx,
            o_Rx_Byte   => rx_byteB,
            o_Rx_DV     => rx_dvB
        );

    -- Generic UART TX to PC
    U_TX: entity work.uart_tx
        generic map(CLKS_PER_BIT => CLKS_PER_BIT)
        port map(
            i_Clock     => clk,
            i_Tx_DV     => rx_dvB,
            i_Tx_Byte   => rx_byteB,
            o_Tx_Serial => ftdi_tx,
            o_Tx_Active => open,
            o_Tx_Done   => open
        );
end architecture Behavioral;
