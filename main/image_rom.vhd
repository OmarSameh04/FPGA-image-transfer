library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
-- File I/O libs
library STD;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;


entity image_rom is
    Port (
      clk      : in  STD_LOGIC;
      addr     : in  STD_LOGIC_VECTOR(13 downto 0);
      data_out : out STD_LOGIC_VECTOR(7 downto 0)
    );
end image_rom;

architecture Behavioral of image_rom is
  type rom_type is array (0 to 16383) of STD_LOGIC_VECTOR(7 downto 0);
  signal ROM : rom_type := (others => (others => '0'));
begin

  -- Simulation-only ROM loader (excluded from synthesis)
-- synthesis translate_off
rom_load_proc: process
  file img_file   : text open read_mode is "image.mem";
  variable line_c : line;
  variable temp   : std_logic_vector(7 downto 0);
begin
  for i in 0 to 16383 loop
    if not endfile(img_file) then
      readline(img_file, line_c);      -- Read a line
      hread(line_c, temp);             -- Read hex value
      ROM(i) <= temp;                  -- Store in ROM
    else
      ROM(i) <= (others => '0');
    end if;
  end loop;
  wait;
end process rom_load_proc;
-- synthesis translate_on


  -- Synchronous read
  sync_read_proc: process(clk)
  begin
    if rising_edge(clk) then
      data_out <= ROM(to_integer(unsigned(addr)));
    end if;
  end process sync_read_proc;
end Behavioral;
