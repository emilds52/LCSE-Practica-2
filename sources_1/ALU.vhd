library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library util;
USE util.PIC_pkg.all;

entity ALU is
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

  component sumador is
  port (
    A           : in std_logic_vector(7 downto 0);
    B           : in std_logic_vector(7 downto 0);
    subtract_en : in std_logic;
    Q           : out std_logic_vector(7 downto 0);
    Co          : out std_logic;
    Z           : out std_logic
  );
  end component;
  
  component ASCII2BIN is 
  port (
    A : in std_logic_vector(7 downto 0);
    Q : out std_logic_vector(7 downto 0);
    E : out std_logic
  );
  end component;

  component BIN2ASCII is
  port (
    A : in std_logic_vector(7 downto 0);
    Q : out std_logic_vector(7 downto 0);
    E : out std_logic
  );
  end component;
  
  -- --------------- REGISTROS ----------------

  -- Flags:
  signal FlagZ_reg : std_logic;
  signal FlagZ_tmp : std_logic;
  signal FlagC_reg : std_logic;
  signal FlagC_tmp : std_logic;
  signal FlagN_reg : std_logic;
  signal FlagN_tmp : std_logic;
  signal FlagE_reg : std_logic;
  signal FlagE_tmp : std_logic;
  -- Accumulador:
  signal ACC_reg : std_logic_vector(7 downto 0);
  signal ACC_tmp : std_logic_vector(7 downto 0);
  -- Index
  signal Index_reg : std_logic_vector(7 downto 0);
  signal Index_tmp : std_logic_vector(7 downto 0);
  -- A 
  signal A_reg : std_logic_vector(7 downto 0);
  signal A_tmp : std_logic_vector(7 downto 0);
  -- B
  signal B_reg : std_logic_vector(7 downto 0);
  signal B_tmp : std_logic_vector(7 downto 0);
  
  -- --------------- Señales Internas -----------------

  signal ACC_oe : std_logic;

  -- Sumador
  signal A_sum      : std_logic_vector(7 downto 0);
  signal B_sum      : std_logic_vector(7 downto 0);
  signal subtract_en : std_logic;
  signal Q_sum      : std_logic_vector(7 downto 0);
  signal Co_sum     : std_logic;
  signal Z_sum      : std_logic;

  -- ASCII to Binary
  signal A_A2B : std_logic_vector(7 downto 0);
  signal Q_A2B : std_logic_vector(7 downto 0);
  signal E_A2B : std_logic;
  
  -- Binary to ASCII 
  signal A_B2A : std_logic_vector(7 downto 0);
  signal Q_B2A : std_logic_vector(7 downto 0);
  signal E_B2A : std_logic;

begin

  u_Sumador : Sumador 
  port map(
    A           => A_sum,
    B           => B_sum,
    subtract_en => subtract_en,
    Q           => Q_sum,
    Co          => Co_sum,
    Z           => Z_sum
  );

  u_ASCII2BIN : ASCII2BIN
  port map(
    A => A_A2B,
    Q => Q_A2B,
    E => E_A2B
  );

  u_BIN2ASCII : BIN2ASCII
  port map(
    A => A_B2A,
    Q => Q_B2A,
    E => E_B2A
  );

  comb_core : process(all)
  begin
    -- Señales por defecto
    -- Registros
    FlagZ_tmp <= FlagZ_reg;
    FlagC_tmp <= FlagC_reg;
    FlagN_tmp <= FlagN_reg;
    FlagE_tmp <= FlagE_reg;
    ACC_tmp   <= ACC_reg;
    Index_tmp <= Index_reg;
    A_tmp     <= A_reg;
    B_tmp     <= B_reg;
    -- Señales internas
    ACC_oe     <= '0';
    A_sum      <= (others => '0');
    B_sum      <= (others => '0');
    subtract_en <= '0'; -- Sumar por defecto
    A_A2B      <= (others => '0');
    A_B2A      <= (others => '0');

    case( u_instruction ) is
    
      when nop =>
        -- ni ná de ná

      -- External value load
      when op_lda =>
        A_tmp <= Databus;

      when op_ldb => 
        B_tmp <= Databus;
      
      when op_ldacc =>
        ACC_tmp <= Databus;
      
      when op_ldid =>
        Index_tmp <= Databus;
      
      -- Internal load
      when op_mvacc2id =>
        Index_tmp <= ACC_reg;

      when op_mvacc2a =>
        A_tmp <= ACC_reg;

      when op_mvacc2b =>
        B_tmp <= ACC_reg;

      -- Arithmetic operations
      when op_add =>
        A_sum     <= A_reg;
        B_sum     <= B_reg;
        ACC_tmp   <= Q_sum;
        FlagZ_tmp <= Z_sum;
        FlagC_tmp <= Co_sum;

      when op_sub =>
        A_sum      <= A_reg;
        B_sum      <= B_reg;
        subtract_en <= '1'; -- Restar
        ACC_tmp    <= Q_sum;
        FlagZ_tmp  <= Z_sum;
        FlagC_tmp  <= Co_sum; -- TODO: Puede que haya que hacer más para detectar overflow
      
      when op_shiftl =>
        ACC_tmp <= ACC_reg(6 downto 0) & '0';

      when op_shiftr =>
        ACC_tmp <= '0' & ACC_reg(7 downto 1);

      -- Logic operations
      when op_and =>
        ACC_tmp <= A_reg and B_reg;
        FlagZ_tmp <= nor(ACC_tmp);

      when op_or =>
        ACC_tmp <= A_reg or B_reg;
        FlagZ_tmp <= nor(ACC_tmp);

      when op_xor =>
        ACC_tmp <= A_reg xor B_reg;
        FlagZ_tmp <= nor(ACC_tmp);

      -- Compare operations
      when op_cmpe =>
        FlagZ_tmp <= and(A_reg xnor B_reg); -- A_reg ?= B_reg

      when op_cmpl => -- FlagZ_tmp <= A_reg ?<= B_reg
        A_sum       <= A_reg;
        B_sum       <= B_reg;
        subtract_en <= '1'; -- Restar
        FlagZ_tmp   <= Co_sum;
            
      when op_cmpg => -- FlagZ_tmp <= A_reg ?>= B_reg
        A_sum       <= A_reg;
        B_sum       <= B_reg;
        subtract_en <= '1'; -- Restar
        FlagZ_tmp   <= (not Co_sum) and not Z_sum; -- Look for positive sign unless output was 0

      -- Conversion operations
      when op_ascii2bin =>
        A_A2B     <= A_reg;
        ACC_tmp   <= Q_A2B;
        FlagE_tmp <= E_A2B;
      
      when op_bin2ascii =>
        A_B2A     <= A_reg;
        ACC_tmp   <= Q_B2A;
        FlagE_tmp <= E_B2A;

      -- Output enable
      when op_oeacc =>
        ACC_oe <= '1';
    
      -- Others
      when others =>
        -- ERROR?
    
    end case ;
  end process;



  registers : process(clk, reset)
  begin
    if reset = '0' then
      FlagZ_reg <= '0';
      FlagC_reg <= '0';
      FlagN_reg <= '0';
      FlagE_reg <= '0';
      ACC_reg   <= (others => '0');
      Index_reg <= (others => '0');
      A_reg     <= (others => '0');
      B_reg     <= (others => '0');
    elsif rising_edge(clk) then
      FlagZ_reg <= FlagZ_tmp;
      FlagC_reg <= FlagC_tmp;
      FlagN_reg <= FlagN_tmp;
      FlagE_reg <= FlagE_tmp;
      ACC_reg   <= ACC_tmp;
      Index_reg <= Index_tmp;
      A_reg     <= A_tmp;
      B_reg     <= B_tmp;
    end if;
  end process;

  -- Asignación de salidas: 
  FlagZ <= FlagZ_reg;
  FlagC <= FlagC_reg;
  FlagN <= FlagN_reg;
  FlagE <= FlagE_reg;
  Index <= Index_reg;
  Databus <= ACC_reg when ACC_oe = '1' else (others => 'Z');

end architecture behavioral;