library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package types_pkg is
  type compressed_array_t is array (0 to 16383) of std_logic_vector(15 downto 0);
end package;

package body types_pkg is
end package body;
