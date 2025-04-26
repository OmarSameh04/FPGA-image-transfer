library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity rle_compressor is
  Port (
    clk            : in  STD_LOGIC;
    reset          : in  STD_LOGIC;
    start          : in  STD_LOGIC;
    end_of_input   : in  STD_LOGIC; -- NEW: Added port
    data_in        : in  STD_LOGIC_VECTOR(7 downto 0);
    data_out       : out STD_LOGIC_VECTOR(7 downto 0);
    run_length_out : out STD_LOGIC_VECTOR(7 downto 0);
    valid_out      : out STD_LOGIC;
    done           : out STD_LOGIC
  );
end rle_compressor;

architecture Behavioral of rle_compressor is
  signal current_pixel : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
  signal run_length    : integer range 0 to 255 := 0;
  signal state         : STD_LOGIC_VECTOR(1 downto 0) := "00";
  signal done_int      : STD_LOGIC := '0';
begin
  done <= done_int;

  process(clk, reset)
  begin
    if reset = '1' then
      current_pixel   <= (others => '0');
      run_length      <= 0;
      state           <= "00";
      valid_out       <= '0';
      data_out        <= (others => '0');
      run_length_out  <= (others => '0');
      done_int        <= '0';
    elsif rising_edge(clk) then
      valid_out  <= '0';
      done_int   <= '0';

      case state is
        when "00" =>  -- IDLE
          if start = '1' then
            current_pixel <= data_in;
            run_length    <= 1;
            state         <= "01";
          end if;

        when "01" =>  -- COMPRESSING
          if end_of_input = '1' then -- NEW: Transition on end_of_input
            state <= "10";
          elsif data_in = current_pixel and run_length < 255 then
            run_length <= run_length + 1;
          else
            data_out       <= current_pixel;
            run_length_out <= std_logic_vector(to_unsigned(run_length,8));
            valid_out      <= '1';
            current_pixel  <= data_in;
            run_length     <= 1;
          end if;

        when "10" =>  -- FINALIZE
          data_out       <= current_pixel;
          run_length_out <= std_logic_vector(to_unsigned(run_length,8));
          valid_out      <= '1';
          done_int       <= '1';
          state          <= "00";

        when others =>
          state <= "00";
      end case;
    end if;
  end process;
end Behavioral;