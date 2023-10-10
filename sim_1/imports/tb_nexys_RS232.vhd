
library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std.all;
library util;
   use util.RS232_test.all;
   use util.utility.all;
   
entity TB_nexys_RS232 is
end TB_nexys_RS232;

architecture Testbench of TB_nexys_RS232 is

  component nexys_RS232 is 
  port (
    
    -- Puertos PMOD de usuario (x4)
    JA                 : inout STD_LOGIC_VECTOR(2 downto 1);    
    
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
   end component;
  
  signal Clk100MHz : std_logic;
  signal SW, LED : std_logic_vector(15 downto 0);

-- signals for UUT (RS_232top) 
    signal Clk, reset : std_logic;
    signal Data_in_s   : std_logic_vector(7 downto 0);  -- Parallel TX byte 
    signal Valid_D   : std_logic:='1';   -- Handshake signal from guest, active low 
    signal Ack_in    : std_logic;   -- Data ack, low when it has been stored
    signal TX_RDY    : std_logic;   -- System ready to transmit
    signal TD        : std_logic;   -- RS232 Transmission line
	
    signal RD        : std_logic;   -- RS232 Reception line
    signal Data_out  : std_logic_vector(7 downto 0);  -- Parallel RX byte
    signal Data_read : std_logic:='0';   -- Send RX data to guest 
    signal Full      : std_logic;   -- Internal RX memory full 
    signal Empty     : std_logic;  -- Internal RX memory empty
    
    -- Signals to convert from std_logic_vector to enum types
    signal speed : speed_t;
    signal nbits : nbits_t;
  
    signal Segment: std_logic_vector(6 downto 0);
    signal AN : std_logic_vector(7 downto 0);
    signal BTNC, BTNU : std_logic;
    signal JA : std_logic_vector(2 downto 1);
    
  
  constant Tclk: time := 10 ns;  -- Clock Period 
  constant Tclk2: time := 50 ns;  -- Clock Period 
  
  signal s_SW: unsigned(1 downto 0):="00";
  signal tiempo:time:=8680.6 ns;

begin

  -- Instantiation of "Unit Under Test" 
  Unit_nexys_RS232 :  nexys_RS232
    port map (
	JA => JA,
    Segment => Segment,
    AN => AN,

    BTNC => BTNC,   
    BTNU => BTNU,      

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
  
process(LED(14))
begin
  if (falling_edge(LED(14))) then
    Valid_D <= (LED(14));
    Data_read <= not (LED(14));
    else
    s_SW<=s_SW+1 after 500*TClk2; 
    Valid_D <= (LED(14)) after 250*Tclk2; -- reset D to 0 after 10us
    Data_read <= not (LED(14)) after 200*Tclk2;
  end if;
end process;

with speed select
tiempo <= 8680.6 ns when normal,
34722.4 ns when quarter,
17361.2 ns when half,
4340.3 ns when doble,
8680.6 ns when others;

----------------------------------

-- Visualización de las señales de salida y estado del sistema
     Data_out <= LED(7 downto 0);
     Ack_in <= LED(10);
     TX_RDY <= LED(11);
     Full <= LED(13);
     Empty <= LED(14);

-- Señales de petición de envío y recepción de datos (entrada) 
     BTNC <= NOT Valid_D;
     BTNU <= Data_read; 
  
-- realimentación lineas TD => RD  (necesita un cable entre los pines 1 y 2 del pmodJA)
    TD <= JA(1);   -- OUTPUT PORT
    JA(2) <= RD;   -- INPUT PORT

--Mejoras
speed <= speed_t'val(to_integer(unsigned(SW(9 downto 8))));
nbits <= nbits_t'val(to_integer(unsigned(SW(11 downto 10))));

----------------------------------------------------------
sw(7 downto 0) <= data_in_s;
sW(11 downto 10) <= std_logic_vector(s_SW);


    p_reset : PROCESS
    variable Data_in: std_logic_vector(7 downto 0):=x"00";
    BEGIN
    SW(15 downto 12) <= (others=>'0');   
    RD <= '1';
    SW(9 downto 8) <= "10"; --115200    
    wait for 20*TClk2; 
    SW(15) <= '1';
    wait for 1000*TClk2;
    ----------------------
    SW(9 downto 8) <= "10";
    Data_in := "11100010";
    Data_in_S <= data_in;
    wait for 20*Tclk2;
    Transmit(RD,tiempo, Data_in);
    wait for 1000*TClk2;
    Transmit(RD,tiempo, Data_in);
    wait for 1000*TClk2;
    Transmit(RD,tiempo, Data_in);
    wait for 1000*TClk2;
    Transmit(RD,tiempo, Data_in);
    wait for 1000*TClk2;
        ----------------------
    SW(9 downto 8) <= "11";
    wait for 20*Tclk2;
    Transmit(RD,tiempo, Data_in);
    wait for 1000*TClk2;
    Transmit(RD,tiempo, Data_in);
    wait for 1000*TClk2;
    Transmit(RD,tiempo, Data_in);
    wait for 1000*TClk2;
    Transmit(RD,tiempo, Data_in);
    wait for 1000*TClk2;
            ----------------------
    SW(9 downto 8) <= "01"; --half
    wait for 20*Tclk2;
    Transmit(RD,tiempo, Data_in);
    wait for 1000*TClk2;
    Transmit(RD,tiempo, Data_in);
    wait for 1000*TClk2;
    Transmit(RD,tiempo, Data_in);
    wait for 1000*TClk2;
    Transmit(RD,tiempo, Data_in);
    wait for 1000*TClk2;
        ----------------------
    SW(9 downto 8) <= "00"; --quarter
    wait for 20*Tclk2;
    Transmit(RD,tiempo, Data_in);
    wait for 1000*TClk2;
    Transmit(RD,tiempo, Data_in);
    wait for 1000*TClk2;
    Transmit(RD,tiempo, Data_in);
    wait for 1000*TClk2;
    Transmit(RD,tiempo, Data_in);
    wait for 1000*TClk2;
     wait;
     
  END PROCESS;

end Testbench;

