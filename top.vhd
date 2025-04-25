library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- File I/O libs
library STD;
use STD.TEXTIO.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;

-- Import shared types
use work.types_pkg.all;

entity top_module is
  Port (
    clk      : in  STD_LOGIC;
    reset    : in  STD_LOGIC;
    vgaRed   : out STD_LOGIC_VECTOR(3 downto 0);
    vgaGreen : out STD_LOGIC_VECTOR(3 downto 0);
    vgaBlue  : out STD_LOGIC_VECTOR(3 downto 0);
    Hsync    : out STD_LOGIC;
    Vsync    : out STD_LOGIC
  );
end top_module;

architecture Behavioral of top_module is
  -- VGA display signals
  signal pixel_x, pixel_y : std_logic_vector(9 downto 0);
  signal video_on         : std_logic;
  signal rgb_reg          : std_logic_vector(11 downto 0);
  signal pixel_data_disp  : std_logic_vector(7 downto 0);
  signal display_addr     : std_logic_vector(13 downto 0);

  -- Compression signals
  signal comp_addr        : integer range 0 to 16383 := 0;
  signal comp_rom_addr    : std_logic_vector(13 downto 0);
  signal pixel_data_comp  : std_logic_vector(7 downto 0);
  signal start_comp       : std_logic := '1';
  signal comp_data_out    : std_logic_vector(7 downto 0);
  signal comp_run_out     : std_logic_vector(7 downto 0);
  signal comp_valid       : std_logic;
  signal comp_done        : std_logic;

  -- Storage signals
  signal compressed_mem   : compressed_array_t;
  signal write_pointer    : integer range 0 to 16383;
  signal compression_done : std_logic;

  signal end_of_input    : std_logic := '0'; 
  signal start_comp_pulse: std_logic := '0'; 
  signal comp_enable     : std_logic := '0';



  -- File for simulation-only dump
  file out_file : text open write_mode is "compressed.mem";

  -- Component declarations
  component vga_controller
    Port (
      clk      : in  STD_LOGIC;
      Hsync    : out STD_LOGIC;
      Vsync    : out STD_LOGIC;
      video_on : out STD_LOGIC;
      pixel_x  : out STD_LOGIC_VECTOR(9 downto 0);
      pixel_y  : out STD_LOGIC_VECTOR(9 downto 0)
    );
  end component;

  component image_rom
    Port (
      clk      : in  STD_LOGIC;
      addr     : in  STD_LOGIC_VECTOR(13 downto 0);
      data_out : out STD_LOGIC_VECTOR(7 downto 0)
    );
  end component;

  component rle_compressor
  Port (
    clk            : in  STD_LOGIC;
    reset          : in  STD_LOGIC;
    start          : in  STD_LOGIC;
    end_of_input   : in  STD_LOGIC; -- ADD THIS LINE
    data_in        : in  STD_LOGIC_VECTOR(7 downto 0);
    data_out       : out STD_LOGIC_VECTOR(7 downto 0);
    run_length_out : out STD_LOGIC_VECTOR(7 downto 0);
    valid_out      : out STD_LOGIC;
    done           : out STD_LOGIC
  );
end component;

component compressed_data_storage
  Port (
    clk              : in  STD_LOGIC;
    reset            : in  STD_LOGIC;
    write_enable     : in  STD_LOGIC;
    data_in          : in  STD_LOGIC_VECTOR(7 downto 0);
    run_length_in    : in  STD_LOGIC_VECTOR(7 downto 0);
    end_of_input     : in  STD_LOGIC;  -- Add this line
    compressed_mem   : out compressed_array_t;
    write_pointer    : out integer range 0 to 16383;
    compression_done : out STD_LOGIC
  );
end component;

begin
  -- Compute addresses
  display_addr    <= std_logic_vector(to_unsigned(
                         to_integer(unsigned(pixel_y)) * 128 + 
                         to_integer(unsigned(pixel_x)), 14));
  comp_rom_addr   <= std_logic_vector(to_unsigned(comp_addr, 14));
  
  -- NEW: Address sequencer with end detection
  process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        comp_addr <= 0;
        end_of_input <= '0';
        comp_enable <= '0';
      else
        if comp_enable = '1' and comp_addr < 16383 then
          comp_addr <= comp_addr + 1;
        end if;
        
        if comp_addr = 16383 then
          end_of_input <= '1';
        end if;
      end if;
    end if;
  end process;
  
  -- NEW: Start compressor with single pulse
  process(clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        start_comp_pulse <= '0';
        comp_enable <= '1';
      else
        start_comp_pulse <= '0';
        if start_comp = '1' then
          start_comp_pulse <= '1';
          start_comp <= '0';
        end if;
      end if;
    end if;
  end process;
  
  

  -- VGA display instantiation
  VGA_CTRL : vga_controller
    port map (
      clk      => clk,
      Hsync    => Hsync,
      Vsync    => Vsync,
      video_on => video_on,
      pixel_x  => pixel_x,
      pixel_y  => pixel_y
    );

  -- Display ROM
  IMAGE_ROM_DISP : image_rom
    port map (
      clk      => clk,
      addr     => display_addr,
      data_out => pixel_data_disp
    );

  -- VGA color mapping
  process(clk)
  begin
    if rising_edge(clk) then
      if video_on = '1' then
        rgb_reg(11 downto 8) <= "0" & pixel_data_disp(7 downto 5);      -- pad to 4 bits
        rgb_reg(7 downto 4)  <= "0" & pixel_data_disp(4 downto 2);      -- pad to 4 bits
        rgb_reg(3 downto 0)  <= "00" & pixel_data_disp(1 downto 0);     -- pad to 4 bits
      else
        rgb_reg <= (others => '0');
      end if;
    end if;
  end process;

  vgaRed   <= rgb_reg(11 downto 8);
  vgaGreen <= rgb_reg(7 downto 4);
  vgaBlue  <= rgb_reg(3 downto 0);

  -- Compression ROM
  IMAGE_ROM_COMP : image_rom
    port map (
      clk      => clk,
      addr     => comp_rom_addr,
      data_out => pixel_data_comp
    );



  -- RLE Compressor instantiation
RLE_COMP : rle_compressor
port map (
  clk            => clk,                  -- Remove "in"
  reset          => reset,                -- Remove "in"
  start          => start_comp_pulse,     -- Remove "in"
  end_of_input   => end_of_input,         -- Remove "in"
  data_in        => pixel_data_comp,      -- Remove "in"
  data_out       => comp_data_out,        -- Remove "out"
  run_length_out => comp_run_out,         -- Remove "out"
  valid_out      => comp_valid,           -- Remove "out"
  done           => comp_done             -- Remove "out"
);

  -- Storage instantiation
STORAGE : compressed_data_storage
  port map (
    clk              => clk,
    reset            => reset,
    write_enable     => comp_valid,
    data_in          => comp_data_out,
    run_length_in    => comp_run_out,
    end_of_input     => end_of_input,  -- Connect the signal
    compressed_mem   => compressed_mem,
    write_pointer    => write_pointer,
    compression_done => compression_done
  );

  -- Simulation-only dump
-- synthesis translate_off
dump_process: process
  variable line_buf : line;
  variable word     : std_logic_vector(15 downto 0);
begin
  wait until rising_edge(clk);
  if compression_done = '1' then
    for i in 0 to write_pointer - 1 loop
      word := compressed_mem(i);
      write(line_buf, word);
      writeline(out_file, line_buf);
    end loop;
    wait;
  end if;
end process;
-- synthesis translate_on

end Behavioral;
