LIBRARY IEEE;
USE IEEE.std_logic_1164.all;

entity sumador_tb is
end sumador_tb;

architecture TestBench of sumador_tb is

  component sumador is
    port(
    A : in std_logic_vector(7 downto 0);
    B : in std_logic_vector(7 downto 0);
    Ci : in std_logic;
    Q : out std_logic_vector(7 downto 0);
    Co: out std_logic;
    Z : out std_logic
    );
  end component;
  
  signal A    : std_logic_vector(7 downto 0):=(others=>'0');
  signal B      : std_logic_vector(7 downto 0):=(others=>'0');
  signal Ci   : std_logic:= '0';
  signal Q : std_logic_vector(7 downto 0):=(others=>'0');
  signal Co   : std_logic:= '0';
  signal Z  : std_logic:= '0';
  
  begin
 
  sumador_inst: sumador
    port map(
      A      => A,
      B    => B,
      Ci => Ci,
      Q => Q,
      Co     => Co,
      Z  => Z
    );  
    
      stimuli_process: process
      begin
-- Test case 1
          wait for 20 ns;
          A <= x"01";
          wait for 20 ns;
          B <= x"09";
          wait for 20 ns;
          Ci <= '1';
      
          -- Test case 2
          wait for 20 ns;
          A <= x"FF";
          wait for 20 ns;
          B <= x"FF";
          wait for 20 ns;
          Ci <= '0';
      
          -- Test case 3
          wait for 20 ns;
          A <= x"01";
          wait for 20 ns;
          B <= x"01";
          wait for 20 ns;
          Ci <= '0';
          
          wait;
      end process;
     
  
  end architecture;