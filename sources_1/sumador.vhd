library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity sumador is
port (
  A           : in std_logic_vector(7 downto 0);
  B           : in std_logic_vector(7 downto 0);
  subtract_en : in std_logic;
  Q           : out std_logic_vector(7 downto 0);
  Co          : out std_logic;
  Z           : out std_logic
);
end sumador;

architecture structural of sumador is 

  component full_adder is
  port(
    A : in std_logic;
    B : in std_logic;
    Cin : in std_logic;
    Sum : out std_logic;
    Cout: out std_logic
  );
  end component;
  
  signal B_aux     : std_logic_vector(8 downto 0);
  signal A_aux     : std_logic_vector(8 downto 0);
  signal Carry_aux : std_logic_vector(9 downto 0);
  signal Q_aux     : std_logic_vector(8 downto 0);

begin
  A_aux <= '0' & A;
  B_aux <= '0' & B when subtract_en = '0' else ('1' & not B);
  Carry_aux(0) <= subtract_en;

  Full_adders_gen : for i in 0 to 8 generate
  begin
    FA_i_INST: Full_adder
      port map (
        A      => A_aux(i),
        B      => B_aux(i),
        Cin    => Carry_aux(i),
        Sum    => Q_aux(i),
        Cout   => Carry_aux(i+1) 
        );
  end generate;
  
  Co <= Q_aux(8);
  Z <= nor(Q_aux);
  Q <= Q_aux(7 downto 0);

end architecture;