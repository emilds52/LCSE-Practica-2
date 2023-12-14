
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

package utility is
type speed_t is (quarter, half, normal, doble);
type nbits_t is (fivebits,sixbits,sevenbits,eightbits);
type array_of_std4_t is array (natural range <>) of std_logic_vector(3 downto 0);--0 a 9
end package;
 
package body utility is

end package body utility;
