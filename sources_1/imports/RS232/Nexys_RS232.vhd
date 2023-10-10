------------------------------------------------------
-- Autor: Juan Antonio López Martín
-- Departamento de Ingeniería Electrónica 
------------------------------------------------------ 

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity nexys_RS232 is
  port (
    
	-- Puertos PMOD de usuario (x4)
	JA 				: inout STD_LOGIC_VECTOR(2 downto 1);    
	
	-- Displays 7 segmentos (x8)
    SEGMENT            : out STD_LOGIC_VECTOR(6 downto 0);  
    AN                 : out  STD_LOGIC_VECTOR(7 downto 0);    

-- Botones de usuario (x5)
    BTNC             : in  STD_LOGIC;    
    BTNU             : in  STD_LOGIC;      

-- Interruptores (x16)
    SW                 : in   STD_LOGIC_VECTOR(15 downto 0);    
-- LEDs (x16)
    LED                : out  STD_LOGIC_VECTOR(15 downto 0);   

-- Reloj de la FPGA
    CLK100MHZ        : in   STD_LOGIC
	 );  
end nexys_RS232;


architecture a_behavior of nexys_RS232 is

-- declaración de componentes 
    component clk_wiz_0
        port (
          reset     : in  std_logic;
          clk_in1   : in  std_logic;
          clk_out1  : out  std_logic;
          locked    : out std_logic);
    end component;

    component RS232top is
      port (
        Reset     : in  std_logic;   -- Low-level asynchronous reset
        Clk       : in  std_logic;   -- System clock (20MHz), rising edge 
	
        Data_in   : in  std_logic_vector(7 downto 0);  -- Parallel TX byte 
        Valid_D   : in  std_logic;   -- Handshake signal from guest, active low 
        Ack_in    : out std_logic;   -- Data ack, low when it has been stored
        TX_RDY    : out std_logic;   -- System ready to transmit
        TD        : out std_logic;   -- RS232 Transmission line
	
        RD        : in  std_logic;   -- RS232 Reception line
        Data_out  : out std_logic_vector(7 downto 0);  -- Parallel RX byte
        Data_read : in  std_logic;   -- Send RX data to guest 
        Full      : out std_logic;   -- Internal RX memory full 
        Empty     : out std_logic;  -- Internal RX memory empty
        
        Speed     : in std_logic_vector(1 downto 0);
        N_bits    : in std_logic_vector(1 downto 0)
        );
    end component;
    
    component Display_cntrl is
    port(
        CLK: in std_logic;
        RESET: in std_logic;
        Sum_enable: in std_logic;
        Data: in std_logic_vector(7 downto 0);
        Digctrl : out std_logic_vector(7 DOWNTO 0);
        Segment : out std_logic_vector(6 DOWNTO 0)
    );
    end component;
    

-- declaración de señales 
    signal reset     : std_logic;
    signal reset_p   : std_logic;
    signal clk       : std_logic;

-- signals for UUT (RS_232top) 
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
    
    signal Speed: std_logic_vector(1 downto 0);
    signal N_bits: std_logic_vector(1 downto 0);
    
begin
--Options

--Speed "00"=28800, "01"=57600, "10"=115200, "11"= 230400
Speed <= SW(9 downto 8);

--N_bits "00"=5, "01"=6, "10"=7, "11"=8
N_bits <= SW(11 downto 10);

-- Reset
     reset <= SW(15);

-- Datos de entrada y salida
     LED(7 downto 0) <= Data_out;
     Data_in <= SW(7 downto 0);

-- Visualización de las señales de salida y estado del sistema
     LED(9 downto 8) <= "00";
     LED(10) <= Ack_in;
     LED(11) <= TX_RDY;
     LED(12) <= '0';
     LED(13) <= Full;
     LED(14) <= Empty;
     LED(15) <= reset;

-- Señales de petición de envío y recepción de datos (entrada) 
     Valid_D <= NOT (BTNC);
     Data_read <= BTNU; 
  
-- realimentación lineas TD => RD  (necesita un cable entre los pines 1 y 2 del pmodJA)
     JA(1) <= TD;   -- OUTPUT PORT
     JA(2) <= 'Z';   -- OUTPUT PORT
     RD <= JA(2);   -- INPUT PORT

-- conexión de las lineas TD y RD PC mediante el puerto microUSB (puerto serie RS232)
--     UART_RXD_OUT <= TD;
--     RD <= UART_TXD_IN;


  reset_p <= not reset;
-- instanciación de componentes 
    clk_20MHz : clk_wiz_0 PORT MAP(
        reset => reset_p,
        clk_in1 => CLK100MHz,
        clk_out1 => clk,
        locked => open);

    RS232top_inst : RS232top PORT MAP(
        Reset      => reset, 
        Clk        => clk,
        Data_in    => Data_in,
        Valid_D    => Valid_D,
        Ack_in     => Ack_in,
        TX_RDY     => TX_RDY,
        TD         => TD,
        RD         => RD,
        Data_out   => Data_out,
        Data_read  => Data_read,
        Full       => Full, 
        Empty      => Empty,
        Speed      => Speed,
        N_bits     => N_bits
        );
        
    Display_ctrl_inst: Display_cntrl port map(
        clk => clk,
        reset => reset,
        Sum_enable => BTNC,
        Data => Data_out,
        Digctrl => AN,
        segment => SEGMENT
        );


end a_behavior;
