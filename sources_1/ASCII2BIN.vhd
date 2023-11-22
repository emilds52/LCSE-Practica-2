library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ASCII2BIN is
port (
  A : in std_logic_vector(7 downto 0);
  Q : out std_logic_vector(7 downto 0);
  E : out std_logic
);
end ASCII2BIN;

architecture A of ASCII2BIN is
signal Q_temp : std_logic_vector(Q'range);
begin
  with A select
    Q_temp <=
      x"00" when x"30",
      x"01" when x"31",
      x"02" when x"32",
      x"03" when x"33",
      x"04" when x"34",
      x"05" when x"35",
      x"06" when x"36",
      x"07" when x"37",
      x"08" when x"38",
      x"09" when x"39",
      x"FF" when others;
  
  Q <= Q_temp;
  E <= '1' when Q_temp = x"FF" else '0';
      
end architecture;