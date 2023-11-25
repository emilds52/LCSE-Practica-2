LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;

library util;
USE util.PIC_pkg.all;

entity ALU_tb is
end ALU_tb;

architecture TestBench of ALU_tb is

  component ALU is
   port (
    Reset : in std_logic; -- asynchronous, active low
    Clk : in std_logic; -- Sys clock, 20MHz, rising_edge
    u_instruction : in alu_op; -- u-instructions from CPU
    FlagZ : out std_logic; -- Zero flag // Vale '1' si el resultado de la �ltima operaci�n fue cero o la �ltima comparaci�n fue verdadera
    FlagC : out std_logic; -- Carry flag // Bit de acarreo de la suma, vale '1' cuando la suma o la resta se desbordan
    FlagN : out std_logic; -- Nibble carry bit // Bit de acarreo de 'nibble', vale '1' cuando existe acarreo entre los 'nibbles' (medio byte)
    FlagE : out std_logic; -- Error flag // Error, vale '1' cuando se llega a alg�n resultado inesperado en la ALU
    Index : out std_logic_vector(7 downto 0); -- Index register
    Databus : inout std_logic_vector(7 downto 0) -- System Data bus
  );
  end component;
  
  signal Reset         : std_logic := '0';
  signal Clk           : std_logic := '0';
  signal u_instruction : alu_op := nop;
  signal FlagZ         : std_logic := '0';
  signal FlagC         : std_logic := '0';
  signal FlagN         : std_logic := '0';
  signal FlagE         : std_logic := '0';
  signal Index         : std_logic_vector(7 downto 0):= (others=>'0');
  signal Databus, Databus_tb       : std_logic_vector(7 downto 0):= (others=>'0');
  
  constant T_CLK : time := 10 ns;
  begin
 
  alu_inst: alu
    port map(
      Clk      => Clk,
      Reset    => Reset,
      u_instruction => u_instruction,
      FlagZ => FlagZ,
      FlagC     => FlagC,
      FlagN  => FlagN,
      FlagE    => FlagE,
      Index   => Index,
      Databus => Databus
    );
  
    -----------------------------------------------------------------------------
    -- Reset & clock generator
    -----------------------------------------------------------------------------
    
      Reset <= '0', '1' after T_CLK;
      
      p_clk : PROCESS
      BEGIN
         clk <= '1', '0' after T_CLK/2;
         wait for T_CLK;
      END PROCESS;
      
      Databus <= Databus_tb when u_instruction /= op_oeacc else (others=> 'Z');
      
      --simulation time: 810 ns
      SEND_STUFF : process
      begin
        wait for 3*T_CLK;
      --Carga de registros
        Databus_tb <= x"AA";
        u_instruction <= op_ldacc;
        wait for T_CLK;
        Databus_tb <= x"98";
        u_instruction <= op_lda;
        wait for T_CLK;
        u_instruction <= op_ldb;
        Databus_tb <= x"55";
        wait for T_CLK;
        Databus_tb <= x"88";
        u_instruction <= op_ldacc;
        wait for T_CLK;
        Databus_tb <= x"11";
        u_instruction <= op_ldid;
        wait for T_CLK;

        --Operaciones
        
        --SHIFT x"11"
        u_instruction <= op_shiftl; --output: x"22"
        wait for T_CLK;
        u_instruction <= op_shiftr;--output: x"11"
        wait for T_CLK;
        
        Databus_tb <= "00110111";
        u_instruction <= op_lda;
        wait for T_CLK;
        Databus_tb <= "01110001";
        u_instruction <= op_ldb;
        wait for T_CLK;
        
        --Logic
        u_instruction <= op_and;--output: "00110001", x"31"
        wait for T_CLK;
        u_instruction <= op_or;--output: "01110111", x"77"
        wait for T_CLK;
        u_instruction <= op_xor;--output: "01000110", x"46"
        wait for T_CLK;
        
        Databus_tb <= "11100110";-- n: -26
        u_instruction <= op_lda;
        wait for T_CLK;
        Databus_tb <= "01001101";-- n: +77
        u_instruction <= op_ldb;
        wait for T_CLK;
        
        --Arithmetic
        u_instruction <= op_add;-- output: 51, x"33"
        wait for T_CLK;
        u_instruction <= op_sub;-- output: -103, x"99"
        wait for T_CLK;

        Databus_tb <= x"37";-- n: 55
        u_instruction <= op_lda;
        wait for T_CLK;
        Databus_tb <= x"19";-- n: 25
        u_instruction <= op_ldb;
        wait for T_CLK;
        
        --Arithmetic
        u_instruction <= op_add;-- output: 80, x"50"
        wait for T_CLK;
        u_instruction <= op_sub;-- output: 30, x"1E"
        wait for T_CLK;
        
        --Comparation (55, 25) CMPG
        u_instruction <= op_cmpe;
        wait for T_CLK;
        u_instruction <= op_cmpl;
        wait for T_CLK;
        u_instruction <= op_cmpg;
        wait for T_CLK;  
        
        Databus_tb <= x"18";-- n: 24
        u_instruction <= op_lda;
        wait for T_CLK;
        Databus_tb <= x"73";-- n: 115
        u_instruction <= op_ldb;
        wait for T_CLK;
        
        --Comparation (24, 115) CMPL
        u_instruction <= op_cmpe;
        wait for T_CLK;
        u_instruction <= op_cmpl;
        wait for T_CLK;
        u_instruction <= op_cmpg;
        wait for T_CLK; 
        
        Databus_tb <= x"23";-- n: 35
        u_instruction <= op_lda;
        wait for T_CLK;
        Databus_tb <= x"23";-- n: 35
        u_instruction <= op_ldb;
        wait for T_CLK;
        
        --Comparation (35, 35) CMPE
        u_instruction <= op_cmpe;
        wait for T_CLK;
        u_instruction <= op_cmpl;
        wait for T_CLK;
        u_instruction <= op_cmpg;
        wait for T_CLK; 

        --ASCII2BIN
        u_instruction <= op_ascii2bin;
        wait for T_CLK;
        Databus_tb <= x"00";
        u_instruction <= op_lda;
        wait for T_CLK;
        u_instruction <= op_ascii2bin;
        wait for T_CLK;
        u_instruction <= op_lda;
        Databus_tb <= x"31";
        wait for T_CLK;
        u_instruction <= op_ascii2bin;
        wait for T_CLK;
        u_instruction <= op_lda;
        Databus_tb <= x"32";
        wait for T_CLK;
        u_instruction <= op_ascii2bin;
        wait for T_CLK;
        u_instruction <= op_lda;
        Databus_tb <= x"33";
        wait for T_CLK;
        u_instruction <= op_ascii2bin;
        wait for T_CLK;
        u_instruction <= op_lda;
        Databus_tb <= x"34";
        wait for T_CLK;
        u_instruction <= op_ascii2bin;
        wait for T_CLK;
        u_instruction <= op_lda;
        Databus_tb <= x"35";
        wait for T_CLK;
        u_instruction <= op_ascii2bin;
        wait for T_CLK;
        u_instruction <= op_lda;
        Databus_tb <= x"36";
        wait for T_CLK;
        u_instruction <= op_ascii2bin;
        wait for T_CLK;
        u_instruction <= op_lda;
        Databus_tb <= x"37";
        wait for T_CLK;
        u_instruction <= op_ascii2bin;
        wait for T_CLK;
        u_instruction <= op_lda;
        Databus_tb <= x"38";
        wait for T_CLK;
        u_instruction <= op_ascii2bin;
        wait for T_CLK;
        u_instruction <= op_lda;
        Databus_tb <= x"39";
        wait for T_CLK;
        u_instruction <= op_ascii2bin;
        wait for T_CLK;
        
        --BIN2ASCII
        u_instruction <= op_bin2ascii;
        wait for T_CLK;
        Databus_tb <= x"00";
        u_instruction <= op_lda;
        wait for T_CLK;
        u_instruction <= op_bin2ascii;
        wait for T_CLK;
        u_instruction <= op_lda;
        Databus_tb <= x"01";
        wait for T_CLK;
        u_instruction <= op_bin2ascii;
        wait for T_CLK;
        u_instruction <= op_lda;
        Databus_tb <= x"02";
        wait for T_CLK;
        u_instruction <= op_bin2ascii;
        wait for T_CLK;
        u_instruction <= op_lda;
        Databus_tb <= x"03";
        wait for T_CLK;
        u_instruction <= op_bin2ascii;
        wait for T_CLK;
        u_instruction <= op_lda;
        Databus_tb <= x"04";
        wait for T_CLK;
        u_instruction <= op_bin2ascii;
        wait for T_CLK;
        u_instruction <= op_lda;
        Databus_tb <= x"05";
        wait for T_CLK;
        u_instruction <= op_bin2ascii;
        wait for T_CLK;
        u_instruction <= op_lda;
        Databus_tb <= x"06";
        wait for T_CLK;
        u_instruction <= op_bin2ascii;
        wait for T_CLK;
        u_instruction <= op_lda;
        Databus_tb <= x"07";
        wait for T_CLK;
        u_instruction <= op_bin2ascii;
        wait for T_CLK;
        u_instruction <= op_lda;
        Databus_tb <= x"08";
        wait for T_CLK;
        u_instruction <= op_bin2ascii;
        wait for T_CLK;
        u_instruction <= op_lda;
        Databus_tb <= x"09";
        wait for T_CLK;
        u_instruction <= op_bin2ascii;
        wait for T_CLK;

        --mv
        u_instruction <= op_mvacc2id;
        wait for T_CLK;
        u_instruction <= op_mvacc2a;
        wait for T_CLK;
        u_instruction <= op_mvacc2b;
        wait for T_CLK;
        wait;
      end process;
      
      
  
  end architecture;