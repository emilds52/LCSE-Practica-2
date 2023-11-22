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
    
      Reset <= '0', '1' after 5*T_CLK;
      
      p_clk : PROCESS
      BEGIN
         clk <= '1', '0' after T_CLK/2;
         wait for T_CLK;
      END PROCESS;
      
      Databus <= Databus_tb when u_instruction /= op_oeacc else (others=> 'Z');
      
      SEND_STUFF : process
      begin
      --Carga de registros
        Databus_tb <= x"AA";
        wait for 4*T_CLK;
        u_instruction <= op_oeacc;
        wait for 4*T_CLK;
        u_instruction <= op_ldacc;
        wait for 4*T_CLK;
        u_instruction <= op_lda;
        wait for 4*T_CLK;
        u_instruction <= op_oeacc;
        wait for 4*T_CLK;
        Databus_tb <= x"55";
        wait for 4*T_CLK;
        u_instruction <= op_ldb;
        wait for 4*T_CLK;
        Databus_tb <= x"88";
        wait for 4*T_CLK;
        u_instruction <= op_ldacc;
        wait for 4*T_CLK;
        Databus_tb <= x"11";
        wait for 4*T_CLK;
        u_instruction <= op_ldid;
        wait for 4*T_CLK;
        Databus_tb <= (others => 'Z');
        --Operaciones
        u_instruction <= op_shiftl;
        wait for 4*T_CLK;
        u_instruction <= op_shiftr;
        wait for 4*T_CLK;
        u_instruction <= op_oeacc;
        wait for 4*T_CLK;
        u_instruction <= op_add;
        wait for 4*T_CLK;
        u_instruction <= op_sub;
        wait for 4*T_CLK;
        u_instruction <= op_and;
        wait for 4*T_CLK;
        u_instruction <= op_or;
        wait for 4*T_CLK;
        u_instruction <= op_xor;
        wait for 4*T_CLK;
        u_instruction <= op_cmpe;
        wait for 4*T_CLK;
        u_instruction <= op_cmpl;
        wait for 4*T_CLK;
        u_instruction <= op_cmpg;
        wait for 4*T_CLK;
        u_instruction <= op_xor;
        wait for 4*T_CLK;
        u_instruction <= op_cmpe;
        wait for 4*T_CLK;
        u_instruction <= op_cmpl;
        wait for 4*T_CLK;  
        
        --ASCII  
        u_instruction <= op_ascii2bin;
        wait for 4*T_CLK;
        Databus_tb <= x"39";
        wait for 4*T_CLK;
        Databus_tb <= x"09";
        wait for 4*T_CLK;
        u_instruction <= op_bin2ascii;
        wait for 4*T_CLK;
        Databus_tb <= x"0A";
        wait for 4*T_CLK;
        
        Databus_tb <= (others => 'Z');
        --mv
        u_instruction <= op_mvacc2id;
        wait for 4*T_CLK;
        u_instruction <= op_mvacc2a;
        wait for 4*T_CLK;
        u_instruction <= op_mvacc2b;
        wait for 4*T_CLK;
        wait;
      end process;
      
      
  
  end architecture;