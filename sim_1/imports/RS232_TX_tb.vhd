----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 14.09.2023 17:51:20
-- Design Name: 
-- Module Name: RS232_TX_tb - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity RS232_TX_tb is
end RS232_TX_tb;

architecture Behavioral of RS232_TX_tb is
component RS232_TX is
    port (
      Clk   : in  std_logic;
      Reset : in  std_logic;
      Start : in  std_logic;
      Data  : in  std_logic_vector(7 downto 0);
      EOT   : out std_logic;
      TX    : out std_logic);
end component;

signal CLK:std_logic:='0';
signal RESET: std_logic:='0';
signal Start:std_logic:='0';
signal Data: std_logic_vector(7 downto 0):=(others=>'0');
signal EOT: std_logic:='0';
signal TX: std_logic:='0';


begin

uut: RS232_TX
port map(
CLK=>CLK,
RESET=>RESET,
STart=>STart,
Data=>DAta,
EOT=>EOT,
TX=>TX
);

process
begin
    Clk <= '0';
    wait for 10ns;
    Clk <= '1';
    wait for 10ns;
end process;

process
begin
wait for 35 ns;
RESET<='1';
Start<='0';
wait for 35 ns;
Start<='1';
wait for 300 us;
Data <= "10000011";
wait for 900 us;
--ENABLE<='1';
start<='0';
end process;

end Behavioral;
