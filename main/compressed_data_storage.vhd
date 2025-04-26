library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.types_pkg.all;

entity compressed_data_storage is
  Port (
    clk              : in  STD_LOGIC;
    reset            : in  STD_LOGIC;
    write_enable     : in  STD_LOGIC;
    data_in          : in  STD_LOGIC_VECTOR(7 downto 0);
    run_length_in    : in  STD_LOGIC_VECTOR(7 downto 0);
    end_of_input     : in  STD_LOGIC;  -- ADD THIS LINE
    compressed_mem   : out compressed_array_t;
    write_pointer    : out integer range 0 to 16383;
    compression_done : out STD_LOGIC
  );
end compressed_data_storage;

architecture Behavioral of compressed_data_storage is
  signal mem      : compressed_array_t := (others => (others => '0'));
  signal wp       : integer range 0 to 16383 := 0;
  signal done_int : std_logic := '0';
  signal sim_time : integer range 0 to 1000 := 0;  -- Time counter for simulation
begin
  process(clk, reset)
begin
  if reset = '1' then
    wp       <= 0;
    done_int <= '0';
  elsif rising_edge(clk) then
    if write_enable = '1' then
      mem(wp) <= data_in & run_length_in;
      wp      <= wp + 1;
    -- NEW: Set done when end_of_input and no more writes
    elsif (end_of_input = '1') and (wp > 0) then
      done_int <= '1';
    end if;
  end if;
end process;

  compressed_mem   <= mem;
  write_pointer    <= wp;
  compression_done <= done_int;
end Behavioral;
