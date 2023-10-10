
library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std.all;
   
entity TB_nexys_RS232 is
end TB_nexys_RS232;

architecture Testbench of TB_nexys_RS232 is

  component nexys_RS232 is 
  port (
    
	-- Puertos PMOD de usuario (x4)
	JA 				: inout STD_LOGIC_VECTOR(2 downto 1);    
	
    --Interfaz USB-RS232
--    UART_TXD_IN     : in  STD_LOGIC;
--    UART_RXD_OUT    : out  STD_LOGIC;
--    UART_CTS        : in  STD_LOGIC;
--    UART_RTS        : in  STD_LOGIC;


---------------------------------------------------------------------------------------
	
	-- Displays 7 segmentos (x8)
    CA                 : out  STD_LOGIC;    
    CB                 : out  STD_LOGIC;    
    CC                 : out  STD_LOGIC;    
    CD                 : out  STD_LOGIC;    
    CE                 : out  STD_LOGIC;    
    CF                 : out  STD_LOGIC;    
    CG                 : out  STD_LOGIC;    
    DP                 : out  STD_LOGIC;    
    AN                 : out  STD_LOGIC_VECTOR(7 downto 0);    

-- Botones de usuario (x5)
    BTNC             : in  STD_LOGIC;    
    BTNU             : in  STD_LOGIC;    
--    BTNL             : in  STD_LOGIC;    
--    BTNR             : in  STD_LOGIC;    
--    BTND             : in  STD_LOGIC;    

-- Interruptores (x16)
    SW                 : in   STD_LOGIC_VECTOR(15 downto 0);    
-- LEDs (x16)
    LED                : out  STD_LOGIC_VECTOR(15 downto 0);   

-- Reloj de la FPGA
    CLK100MHZ        : in   STD_LOGIC

	 );    
   end component;
  
  signal Clk100MHz : std_logic;
  signal SW, LED : std_logic_vector(15 downto 0);

-- signals for UUT (RS_232top) 
    signal Clk, reset : std_logic;
    signal Data_in   : std_logic_vector(7 downto 0);  -- Parallel TX byte 
    signal Valid_D   : std_logic;   -- Handshake signal from guest, active low 
    signal Ack_in    : std_logic;   -- Data ack, low when it has been stored
    signal TX_RDY    : std_logic;   -- System ready to transmit
    signal TD        : std_logic;   -- RS232 Transmission line
	
    signal RD        : std_logic;   -- RS232 Reception line
    signal Data_out  : std_logic_vector(7 downto 0);  -- Parallel RX byte
    signal Data_read : std_logic;   -- Send RX data to guest 
    signal Full      : std_logic;   -- Internal RX memory full 
    signal Empty     : std_logic;  -- Internal RX memory empty
  
    signal CA, CB, CC, CD, CE, CF, CG, DP : std_logic;
    signal AN : std_logic_vector(7 downto 0);
    signal BTNC, BTNU : std_logic;
    signal JA : std_logic_vector(2 downto 1);
    
  
  constant Tclk: time := 10 ns;  -- Clock Period 
  constant Tclk2: time := 25 ns;  -- Clock Period 

begin

  -- Instantiation of "Unit Under Test" 
  Unit_nexys_RS232 :  nexys_RS232
    port map (
	JA => JA,

--    UART_TXD_IN => UART_TXD_IN,
--    UART_RXD_OUT => UART_RXD_OUT,
--    UART_CTS => UART_CTS,
--    UART_RTS => UART_R

    CA => CA,
    CB => CB,
    CC => CC,
    CD => CD,
    CE => CE,
    CF => CF,
    CG => CG,
    DP => DP,
    AN => AN,

    BTNC => BTNC,   
    BTNU => BTNU,   
--    BTNL => BTNL,   
--    BTNR => BTNR,   
--    BTND => BTND,   

      SW => SW,
      LED => LED,
      CLK100MHZ => CLK100MHZ );

-----------------------------------------------------------------

  -- Reset generation
  reset <= '1', '0' after 75 ns, '1' after 175 ns;


  CLK100MHz <= Clk;
  -- Clock generator
  p_clk : PROCESS
  BEGIN
     Clk <= '1';
     wait for Tclk/2;
     Clk <= '0';
     wait for Tclk/2;
  END PROCESS;


----------------------------------

-- Visualización de las señales de salida y estado del sistema
     Data_out <= LED(7 downto 0);
     Ack_in <= LED(10);
     TX_RDY <= LED(11);
     Full <= LED(13);
     Empty <= LED(14);

-- Señales de petición de envío y recepción de datos (entrada) 
     BTNC <= Valid_D;
     BTNU <= Data_read; 
  
-- realimentación lineas TD => RD  (necesita un cable entre los pines 1 y 2 del pmodJA)
     TD <= JA(1);   -- OUTPUT PORT
     JA(2) <= RD;   -- INPUT PORT

-- conexión de las lineas TD y RD PC mediante el puerto microUSB (puerto serie RS232)
--     TD <= UART_RXD_OUT;
--     UART_TXD_IN <= RD;

 
-- Estado de los Switches
  SW(15) <= reset;
  SW (14 downto 8) <= (others => '0');
  SW (7 downto 0) <= Data_in;

----------------------------------------------------------

  Data_in <= "11100010";

  -- RD <= TD;
  p_reset : PROCESS
  BEGIN
     Valid_D <= '1';     
     RD <= '1';     
     Data_read <= '0';

     wait for 2500 ns;     -- Wait for 20-MHz clock signal ready

     Valid_D <= '1', '0' after 110 ns,
                '1' after 400 ns;

--     wait for 500 ns;  Transmit (RD,x"79");
     RD <= '1',
           '0' after 500 ns,    -- StartBit
           '1' after 9150 ns,   -- LSb
           '0' after 17800 ns,
           '0' after 26450 ns,
           '1' after 35100 ns,
           '1' after 43750 ns,
           '1' after 52400 ns,
           '1' after 61050 ns,
           '0' after 69700 ns,  -- MSb
           '1' after 78350 ns,  -- Stopbit
           '1' after 87000 ns;

     Data_read <= '0','1'after 88000 ns;

     wait;
     
  END PROCESS;

end Testbench;

