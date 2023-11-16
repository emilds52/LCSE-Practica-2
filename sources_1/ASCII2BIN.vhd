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
      x"00" when "00110000",
      x"01" when "00110001",
      x"02" when "00110010",
      x"03" when "00110011",
      x"04" when "00110100",
      x"05" when "00110101",
      x"06" when "00110110",
      x"07" when "00110111",
      x"08" when "00111000",
      x"09" when "00111001",
      x"FF" when others;
  
  E <= '1' when Q_temp = x"FF" else '0';
      
end architecture;