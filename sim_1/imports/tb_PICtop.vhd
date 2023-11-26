
LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;

library util;
USE util.PIC_pkg.all;
USE util.RS232_test.all;

entity PICtop_tb is
end PICtop_tb;

architecture TestBench of PICtop_tb is

  component PICtop
    port (
      Reset       : in  std_logic;           -- Asynchronous, active low
      Clk         : in  std_logic;           -- System clock, 20 MHz, rising_edge
  
      RS232_RX    : in  std_logic;           -- RS232 RX line
      RS232_TX    : out std_logic;           -- RS232 TX line
      switches    : out std_logic_vector(7 downto 0);   -- Switch status bargraph
      Temp_L      : out std_logic_vector(6 downto 0);   -- Display value for TL
      Temp_H      : out std_logic_vector(6 downto 0));  -- Display value for TH
  end component;

-----------------------------------------------------------------------------
-- Internal signals
-----------------------------------------------------------------------------
  signal Reset      : std_logic;
  signal Clk        : std_logic;

  signal RS232_RX   : std_logic := '1';
  signal RS232_TX   : std_logic;
  signal switches   : std_logic_vector(7 downto 0);
  signal Temp_L     : std_logic_vector(6 downto 0);
  signal Temp_H     : std_logic_vector(6 downto 0);

  constant wait_transmit : time := 1 us;
begin  -- TestBench

  UUT: PICtop
    port map (
      Reset      => Reset,
      Clk        => Clk,
      RS232_RX   => RS232_RX,
      RS232_TX   => RS232_TX,
      switches   => switches,
      Temp_L     => Temp_L,
      Temp_H     => Temp_H
    );

-----------------------------------------------------------------------------
-- Reset & clock generator
-----------------------------------------------------------------------------

  Reset <= '0', '1' after 75 ns;

  p_clk : PROCESS
  BEGIN
     clk <= '1', '0' after 25 ns;
     wait for 50 ns;
  END PROCESS;

-------------------------------------------------------------------------------
-- Sending some stuff through RS232 port
-------------------------------------------------------------------------------

  SEND_STUFF : process
  begin
    RS232_RX <= '1';
    wait for 40 us;
    
    --Escribir 18 en temperatura
    Transmit(RS232_RX, X"54");--T
    wait for wait_transmit;
    Transmit(RS232_RX, X"31"); --1
    wait for wait_transmit;
    Transmit(RS232_RX, X"38");--8
    wait for wait_transmit;
   
    --escribir 1 en switches
    for i in 48 to 55 loop
      Transmit(RS232_RX, X"49");--I
      wait for wait_transmit;
      Transmit(RS232_RX, std_logic_vector(to_unsigned(i,8)));--i
      wait for wait_transmit;
      Transmit(RS232_RX, X"31");--1
      wait for wait_transmit;
    end loop;
    
    --escribir 0 en switches
    for j in 0 to 7 loop
      Transmit(RS232_RX, X"49");--I
      wait for wait_transmit;
      Transmit(RS232_RX, std_logic_vector(to_unsigned(55 - j,8)));--j
      wait for wait_transmit;
      Transmit(RS232_RX, X"30");--0
      wait for wait_transmit;
    end loop;
    
    --Escribir 8 en actuador 1 --address 33
    Transmit(RS232_RX, X"41");--A
    wait for wait_transmit;
    Transmit(RS232_RX, X"31"); --1
    wait for wait_transmit;
    Transmit(RS232_RX, X"38");--8
    wait for wait_transmit;

    --Solicitar valor actuador 8
    Transmit(RS232_RX, X"53");--S
    wait for wait_transmit;
    Transmit(RS232_RX, X"41"); --A
    wait for wait_transmit;
    Transmit(RS232_RX, X"31");--8
    wait for wait_transmit;
    
    wait;
  end process SEND_STUFF;

end TestBench;

