
LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;

library util;
USE util.PIC_pkg.all;

ENTITY ramg IS
PORT (
   Clk      : in    std_logic;
   write_en : in    std_logic;
   oe       : in    std_logic;
   address  : in    std_logic_vector(7 downto 0);
   databus  : inout std_logic_vector(7 downto 0));
END ramg;

ARCHITECTURE behavior OF ramg IS

  SIGNAL contents_ram : array8_ram(255 downto 64);
  signal CS_RAMg      : std_logic;

BEGIN

CS_RAMg <= '1' when (address(7) or address(6))='1' else '0';

-------------------------------------------------------------------------
-- Memoria de prop�sito general
-------------------------------------------------------------------------
p_ram : process (clk)  -- no reset
begin
  if clk'event and clk = '1' then
    if write_en = '1' and CS_RAMg = '1' then
      contents_ram(to_integer(unsigned(address))) <= databus;
    end if;
  end if;
end process;

databus <= contents_ram(to_integer(unsigned(address))) when oe = '1' and CS_RAMg = '1' else (others => 'Z');

END behavior;

