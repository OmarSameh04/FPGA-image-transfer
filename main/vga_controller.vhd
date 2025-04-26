library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity vga_controller is
  Port (
    clk      : in  STD_LOGIC;
    Hsync    : out STD_LOGIC;
    Vsync    : out STD_LOGIC;
    video_on : out STD_LOGIC;
    pixel_x  : out STD_LOGIC_VECTOR(9 downto 0);
    pixel_y  : out STD_LOGIC_VECTOR(9 downto 0)
  );
end vga_controller;

architecture Behavioral of vga_controller is
  constant H_DISP  : integer := 640;
  constant H_FP    : integer := 16;
  constant H_PULSE : integer := 96;
  constant H_BP    : integer := 48;
  constant H_TOTAL : integer := 800;

  constant V_DISP  : integer := 480;
  constant V_FP    : integer := 10;
  constant V_PULSE : integer := 2;
  constant V_BP    : integer := 33;
  constant V_TOTAL : integer := 525;

  signal h_count : integer range 0 to H_TOTAL := 0;
  signal v_count : integer range 0 to V_TOTAL := 0;
begin
  process(clk)
  begin
    if rising_edge(clk) then
      if h_count = H_TOTAL-1 then
        h_count <= 0;
        if v_count = V_TOTAL-1 then
          v_count <= 0;
        else
          v_count <= v_count + 1;
        end if;
      else
        h_count <= h_count + 1;
      end if;
    end if;
  end process;

  Hsync    <= '0' when (h_count >= H_DISP + H_FP and h_count < H_DISP + H_FP + H_PULSE) else '1';
  Vsync    <= '0' when (v_count >= V_DISP + V_FP and v_count < V_DISP + V_FP + V_PULSE) else '1';
  video_on <= '1' when (h_count < H_DISP and v_count < V_DISP) else '0';

  pixel_x  <= std_logic_vector(to_unsigned(h_count, 10));
  pixel_y  <= std_logic_vector(to_unsigned(v_count, 10));
end Behavioral;
