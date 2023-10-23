LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;

library util;
USE util.PIC_pkg.all;

entity terna is
  port(
    Clk      : in  std_logic;
    Reset    : in std_logic;
    
    RS232_RX : in std_logic;
    RS232_TX : out std_logic;
    
    Send     : in std_logic;
    DMA_ACK  : in std_logic;
    READY    : out std_logic;
    DMA_RQ   : out std_logic
  );
end terna;

architecture ternaria of terna is

  component DMA is
    PORT (
      Clk       : in    std_logic;
      Reset     : in    std_logic;
      RCVD_Data : in    std_logic_vector(7 downto 0);--Dato recibido por la línea 232
      RX_Full   : in    std_logic;
      RX_Empty  : in    std_logic;
      Data_Read : out   std_logic;--Petición de lectura de un nuevo dato de los recibidos
      ACK_out   : in    std_logic;--Señal de reconocimiento de llegada de datos al Transmisor RS232
      TX_RDY    : in    std_logic;
      Valid_D   : out   std_logic;--Validación del dato enviado al transmisor RS232
      TX_Data   : out   std_logic_vector(7 downto 0);
      Address   : out   std_logic_vector(7 downto 0);
      Databus   : inout std_logic_vector(7 downto 0);
      Write_en  : out   std_logic;--Indicación de escritura para la RAM
      OE        : out   std_logic;--Salida Habilitación de la salida de la RAM
      DMA_RQ    : out   std_logic;--Salida Petición de buses al procesador principal
      DMA_ACK   : in    std_logic;--Entrada Reconocimiento y préstamo de buses por parte del procesador principal
      Send_comm : in    std_logic;--Entrada Señal de comienzo de envío de datos, controlada por el procesador principal
      READY     : out   std_logic --Salida Señal a nivel alto únicamente cuando el procesador se encuentre totalmente ocioso
    );
  end component;
  
  component RAM is
    PORT (
      Clk      : in    std_logic;
      Reset    : in    std_logic;
      write_en : in    std_logic;
      oe       : in    std_logic;
      address  : in    std_logic_vector(7 downto 0);
      databus  : inout std_logic_vector(7 downto 0);
      Switches : out   std_logic_vector(7 downto 0);
      Temp_H   : out   std_logic_vector(6 downto 0);
      Temp_L   : out   std_logic_vector(6 downto 0)
    );
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
      Empty     : out std_logic;   -- Internal RX memory empty
      
      Speed: in std_logic_vector(1 downto 0);
      N_bits: in std_logic_vector(1 downto 0)
    );
  end component;
  
 --signal Reset    : std_logic;
 --signal Clk      : std_logic;
  signal TX_Data  : std_logic_vector(7 downto 0);
  signal Valid_D  : std_logic;
  signal ACK_out  : std_logic;
  signal TX_RDY   : std_logic;
  --signal RS232_RX : std_logic;
  --signal RS232_TX : std_logic;
  signal RCVD_Data: std_logic_vector(7 downto 0);
  signal Data_read: std_logic;
  signal RX_Full  : std_logic;
  signal RX_Empty : std_logic;
  
  signal Address  : std_logic_vector(7 downto 0);
  signal Databus  : std_logic_vector(7 downto 0);
  signal Write_en : std_logic;  
  signal OE       : std_logic;
  --signal DMA_RQ   : std_logic;
  --signal DMA_ACK  : std_logic;
  --signal Send     : std_logic;
  --signal READY    : std_logic;
 
  signal switches : std_logic_vector(7 downto 0);
  signal Temp_H   : std_logic_vector(6 downto 0);
  signal Temp_L   : std_logic_vector(6 downto 0);
  
  begin
 
  RS232top_inst: RS232top
    port map(
      Reset => Reset,
      CLK => CLK,
      Data_in => TX_Data,
      Valid_D => Valid_D,
      ACK_in => ACK_out,
      TX_RDY => TX_RDY,
      TD => RS232_TX,
      RD => RS232_RX,
      Data_out => RCVD_Data,
      Data_read => Data_read,
      Full => RX_Full,
      Empty => RX_Empty,
      Speed => "10", --115200
      N_bits => "11" --8 bits
    );
  
  DMA_inst: DMA
    port map(
      CLK => CLk,
      Reset => Reset,
      RCVD_Data => RCVD_Data,
      RX_Full => RX_Full,
      RX_Empty => RX_Empty,
      Data_read => Data_read,
      ACK_out => ACK_out,
      TX_RDY => TX_RDY,
      Valid_D => Valid_D,
      TX_Data => TX_Data,
      Address => Address,
      Databus => Databus,
      Write_en => Write_en,
      OE => OE,
      DMA_RQ => DMA_RQ,
      DMA_ACK => DMA_ACK,
      Send_comm => Send,
      READY => READY
    );
    
  RAM_inst: RAM
    port map(
      CLK => CLK,
      Reset => Reset,
      Write_en => Write_en,
      OE => OE,
      Address => Address,
      Databus => Databus,
      Switches => Switches,
      Temp_H => Temp_H,
      Temp_L => Temp_L
    );
  
end architecture;