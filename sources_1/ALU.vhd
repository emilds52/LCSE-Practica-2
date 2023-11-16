library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library util;
USE util.PIC_pkg.all;

entity ALU is
port (
  Reset : in std_logic; -- asynnchronous, active low
  Clk : in std_logic; -- Sys clock, 20MHz, rising_edge
  u_instruction : in alu_op; -- u-instructions from CPU
  FlagZ : out std_logic; -- Zero flag // Vale '1' si el resultado de la �ltima operaci�n fue cero o la �ltima comparaci�n fue verdadera
  FlagC : out std_logic; -- Carry flag // Bit de acarreo de la suma, vale '1' cuando la suma o la resta se desbordan
  FlagN : out std_logic; -- Nibble carry bit // Bit de acarreo de 'nibble', vale '1' cuando existe acarreo entre los 'nibbles' (medio byte)
  FlagE : out std_logic; -- Error flag // Error, vale '1' cuando se llega a alg�n resultado inesperado en la ALU
  Index_Reg : out std_logic_vector(7 downto 0); -- Index register
  Databus : inout std_logic_vector(7 downto 0) -- System Data bus
);
end ALU;

--En las comparaciones (CMPE, CMPL, CMPG) se var�a el bit de cero (Z), colocando un '1' si la
--comparaci�n fue verdadera y un '0' en caso contrario. Por otra parte, el bit E se coloca a '1' cuando
--se produce un error en las funciones de conversi�n ASCII2BIN y BIN2ASCII. Los flags C, N y E no
--se utilizan para nada en este germen del procesador, pero se implementan para facilitar su posterior
--incorporaci�n a las funciones del mismo.


--El formato binario de esta instrucci�n es simple. Los 4 bits m�s significativos est�n a 0 y despu�s
--tenemos 2 bits que indican el tipo de instrucci�n y el resto el c�digo de operaci�n. Haciendo uso de
--las constantes definidas en PIC_pkg.vhd, un ejemplo de instrucci�n de tipo 1 ser�a "0000" &
--TYPE_1 & ALU_ADD.


--ADD A + B Z, C, N
--SUB A - B Z, C, N
--SHIFTL Gira hacia la izquierda el contenido
--del acumulador, introduciendo un cero
--SHIFTR Gira hacia la izquierda el contenido
--del acumulador, introduciendo un cero
--AND 'and' l�gico entre A y B Z
--OR 'or' l�gico entre A y B Z
--XOR 'xor' l�gico entre A y B Z
--CMPE A = B Z
--CMPG A > B Z
--CMPL A < B Z
--ASCII2BIN Convierte A del formato ASCII al binario
--(para n�meros, devuelve FF si hay error)
--E
--BIN2ASCII Convierte A del binario al ASCII
--(para n�meros menores de 0x10,
--devuelve FF si hay error)
--E

architecture behavioral of ALU is

begin

process(clk, reset)
begin
  if reset = '1' then
  
  elsif rising_edge(clk) then
  
  end if;

end process;

end architecture behavioral;