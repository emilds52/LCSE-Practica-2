library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_unsigned.all;

library util;
USE util.PIC_pkg.all;

entity sumador is
port (
  A : in std_logic_vector(7 downto 0);
  B : in std_logic_vector(7 downto 0);
  C : in std_logic;
  Q : out std_logic_vector(7 downto 0);
  Co: out std_logic;
  Z : out std_logic
);
end sumador;

architecture behavioral of sumador is 

signal A_uns : unsigned(A'range);
signal B_uns : unsigned(B'range);

signal Q_aux : std_logic_vector(Q'length + 1 downto 0);

begin
A_uns <= unsigned(A);
B_uns <= unsigned(B);

Q_aux <= std_logic_vector( A_uns + B_uns ) + C;
Q <= Q_aux(7 downto 0);
Co <= Q_aux(8);
Z <= not ( Q_aux(7) or Q_aux(6) or Q_aux(5) or Q_aux(4) or Q_aux(3) or Q_aux(2) or Q_aux(1) or Q_aux(0));


end architecture;