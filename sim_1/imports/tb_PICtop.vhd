
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
  
      i_write_en  : in  std_logic;                            -- Signals needed to access directly to the RAM (read/write)
      i_oe        : in  std_logic;                            -- Signals needed to access directly to the RAM (read/write)
      i_address   : in  std_logic_vector(7 downto 0);          -- Signals needed to access directly to the RAM (read/write)
      databus     : inout std_logic_vector(7 downto 0);       -- Signals needed to access directly to the RAM (read/write)
      i_send      : in  std_logic;                            -- Indicates the DMA to send the RAM positions 4 y 5 (CPU response)
  
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

  signal i_write_en : std_logic := '0';
  signal i_oe       : std_logic := '1';
  signal i_address  : std_logic_vector(7 downto 0) := (others => '0');
  signal databus    : std_logic_vector(7 downto 0);
  signal i_send     : std_logic := '0';

  signal RS232_RX   : std_logic := '1';
  signal RS232_TX   : std_logic;
  signal switches   : std_logic_vector(7 downto 0);
  signal Temp_L     : std_logic_vector(6 downto 0);
  signal Temp_H     : std_logic_vector(6 downto 0);

  -- tb signals
  signal databus_tb : std_logic_vector(7 downto 0);

begin  -- TestBench

  UUT: PICtop
    port map (
      Reset      => Reset,
      Clk        => Clk,
      i_write_en => i_write_en,
      i_oe       => i_oe,
      i_address  => i_address,
      databus    => databus,
      i_send     => i_send,
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
     Transmit(RS232_RX, X"49");
     wait for 40 us;
     Transmit(RS232_RX, X"34");
     wait for 40 us;
     Transmit(RS232_RX, X"31");
     wait for 1 us;
     wait until rising_edge(clk);
     i_address  <= x"04";
     i_write_en <= '1';
     databus_tb <= x"55";
     wait until rising_edge(clk);
     i_address  <= x"05";
     databus_tb <= x"AA";
     wait until rising_edge(clk);
     i_write_en <= '0';
     i_send     <= '1';
     wait until rising_edge(clk);
     i_send     <= '0';
     wait;
  end process SEND_STUFF;

-- Continuous assignation

  Databus <= Databus_tb when i_write_en='1' else (others=> 'Z');

end TestBench;

