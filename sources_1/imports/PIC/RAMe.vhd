
LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;

library util;
USE util.PIC_pkg.all;

ENTITY RAMe IS
PORT (
   Clk      : in    std_logic;
   Reset    : in    std_logic;
   write_en : in    std_logic;
   oe       : in    std_logic;
   address  : in    std_logic_vector(7 downto 0);
   databus  : inout std_logic_vector(7 downto 0);
   Switches : out   std_logic_vector(7 downto 0);
   Temp_H   : out   std_logic_vector(6 downto 0);
   Temp_L   : out   std_logic_vector(6 downto 0)
   );
END RAMe;

ARCHITECTURE behavior OF RAMe IS

  signal CS_RAMe: std_logic;
  SIGNAL contents_ram : array8_ram(63 downto 0);
  constant reset_values : array8_ram(63 downto 0) := (16#31# => std_logic_vector(to_unsigned(16#22#, 8)),others=>(others=>'0'));

BEGIN

CS_RAMe <= '1' when (address(7) or address(6))= '0' else '0';

-------------------------------------------------------------------------
-- Memoria de prop�sito general
-------------------------------------------------------------------------
p_ram : process (clk)  -- no reset
begin
  if Reset = '0' then
    contents_ram <= reset_values;
  elsif clk'event and clk = '1' then
    if write_en = '1' and CS_RAMe = '1' then
      contents_ram(to_integer(unsigned(address))) <= databus;
    end if;
  end if;
end process;

databus <= contents_ram(to_integer(unsigned(address))) when oe = '0' and CS_RAMe = '1' else (others => 'Z');
-------------------------------------------------------------------------

-------------------------------------------------------------------------
-- Decodificador de BCD a 7 segmentos
-------------------------------------------------------------------------
with contents_ram(16#31#)(7 downto 4) select
Temp_H <=
   "0111111" when "0000",  -- 0
   "0000110" when "0001",  -- 1
   "1011011" when "0010",  -- 2
   "1001111" when "0011",  -- 3
   "1100110" when "0100",  -- 4
   "1101101" when "0101",  -- 5
   "1111101" when "0110",  -- 6
   "0000111" when "0111",  -- 7
   "1111111" when "1000",  -- 8
   "1101111" when "1001",  -- 9
   "1111001" when others;  -- E (error)

with contents_ram(16#31#)(3 downto 0) select
Temp_L <=
   "0111111" when "0000",  -- 0
   "0000110" when "0001",  -- 1
   "1011011" when "0010",  -- 2
   "1001111" when "0011",  -- 3
   "1100110" when "0100",  -- 4
   "1101101" when "0101",  -- 5
   "1111101" when "0110",  -- 6
   "0000111" when "0111",  -- 7
   "1111111" when "1000",  -- 8
   "1101111" when "1001",  -- 9
   "1111001" when others;  -- E (error)
-------------------------------------------------------------------------

Switches_loop : for i in 0 to 7 generate
  Switches(i) <= contents_ram(16#10# + i)(0);
end generate Switches_loop;

END behavior;

