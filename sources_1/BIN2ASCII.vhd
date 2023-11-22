library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity BIN2ASCII is
port (
  A : in std_logic_vector(7 downto 0);
  Q : out std_logic_vector(7 downto 0);
  E : out std_logic
);
end BIN2ASCII;

architecture A of BIN2ASCII is
signal Q_temp : std_logic_vector(Q'range);
begin
  with A select
    Q_temp <=
      x"30" when x"00",
      x"31" when x"01",
      x"32" when x"02",
      x"33" when x"03",
      x"34" when x"04",
      x"35" when x"05",
      x"36" when x"06",
      x"37" when x"07",
      x"38" when x"08",
      x"39" when x"09",
      x"FF" when others;
      
  Q <= Q_temp;
  E <= '1' when Q_temp = x"FF" else '0';
end architecture;