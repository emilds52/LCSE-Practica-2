----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07.09.2023 17:46:51
-- Design Name: 
-- Module Name: shiftregister_tb - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity shiftregister_tb is
end shiftregister_tb;

architecture Behavioral of shiftregister_tb is

component shiftregister is
port(
CLK: in std_logic;
RESET: in std_logic;
ENABLE: in std_logic;
D: in std_logic;

Q:out std_logic_vector(7 downto 0)
);
end component;

signal CLK:std_logic:='0';
signal RESET: std_logic:='0';
signal ENABLE:std_logic:='0';
signal D: std_logic:='0';

signal Q: std_logic_vector(7 downto 0):=(others=>'0');


begin

uut: shiftregister
port map(
CLK=>CLK,
RESET=>RESET,
ENABLE=>ENABLE,
D=>D,
Q=>Q
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
ENABLE<='1';
D<='1';
wait for 35 ns;
ENABLE<='1';
--wait for 0.1 ms;
--ENABLE<='1';
D<='0';
end process;

end Behavioral;
