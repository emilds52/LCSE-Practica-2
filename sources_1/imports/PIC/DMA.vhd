
LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;
USE IEEE.std_logic_unsigned.all;

library util;
USE util.PIC_pkg.all;

ENTITY DMA IS
PORT (
  Clk       : in    std_logic;
  Reset     : in    std_logic;
  RCVD_Data : in    std_logic_vector(7 downto 0);--Dato recibido por la l�nea 232
  RX_Full   : in    std_logic;
  RX_Empty  : in    std_logic;
  Data_Read : out   std_logic;--Petici�n de lectura de un nuevo dato de los recibidos
  ACK_out   : in    std_logic;--Se�al de reconocimiento de llegada de datos al Transmisor RS232
  TX_RDY    : in    std_logic;
  Valid_D   : out   std_logic;--Validaci�n del dato enviado al transmisor RS232
  TX_Data   : out   std_logic_vector(7 downto 0);
  Address   : out   std_logic_vector(7 downto 0);
  Databus   : inout std_logic_vector(7 downto 0);
  Write_en  : out   std_logic;--Indicaci�n de escritura para la RAM
  OE        : out   std_logic;--Salida Habilitaci�n de la salida de la RAM
  DMA_RQ    : out   std_logic;--Salida Petici�n de buses al procesador principal
  DMA_ACK   : in    std_logic;--Entrada Reconocimiento y pr�stamo de buses por parte del procesador principal
  Send_comm : in    std_logic;--Entrada Se�al de comienzo de env�o de datos, controlada por el procesador principal
  READY     : out   std_logic --Salida Se�al a nivel alto �nicamente cuando el procesador se encuentre totalmente ocioso
    
);
END DMA;

ARCHITECTURE behavior OF DMA IS

type state_t is (
  idle,
  request,
  writing,
  request_end,
  pretransmision_1,
  transmision_1,
  pretransmision_2,
  transmision_2
);

signal current_state_reg : state_t;

signal Data_Read_reg: std_logic;
signal Valid_D_reg: std_logic;
signal TX_Data_reg: std_logic_vector(7 downto 0);
signal Address_reg: std_logic_vector(7 downto 0);
                                                
signal Databus_reg: std_logic_vector(7 downto 0);
signal Write_en_reg: std_logic;
signal OE_reg: std_logic;
signal DMA_RQ_reg: std_logic;
signal READY_reg: std_logic;

begin

  Recepcion_transmision_process: process(clk, reset)
  begin
    if reset = '0' then
      Data_Read_reg <= '0';
      Valid_D_reg <= '1';--activa a nivel bajo
      TX_Data_reg <= (others => '0');
      Address_reg <= x"00";
      databus_reg <= (others=> '0');
      Write_en_reg <= '0';
      OE_reg <= '0';
      DMA_RQ_reg <= '0';
      READY_reg <= '0'; --procesador no ocioso
      current_state_reg <= idle;
            
    elsif rising_edge(clk) then
      case current_state_reg is
    
        when idle=>
          READY_reg <= '1';
          Address_reg <= x"00";
          if Send_Comm = '1' then 
            current_state_reg <= pretransmision_1;
            READY_reg <= '0';
          elsif RX_Empty = '0' then--si memoria interna no vac�a, recibe datos
            --siempre vienen 3 bytes? El orden es por llegada(MSB, Int, LSB)
            current_state_reg <= request;
            READY_reg <= '0';
          end if;
        
        when request=>
          DMA_RQ_reg <= '1';--Petici�n de buses
          if DMA_ACK = '1' then
            current_state_reg <= writing;
            Write_en_reg <= '1';
            Data_Read_reg <= '1';
            Address_reg <= x"00";
          end if;
        
        when writing=>        
          --Data_Read_reg <= '1';--hay que hacerla un ciclo antes para haber recibido el byte
          --Write_en_reg <= '1';--hay que hacerlo un ciclo antes
          if RX_Empty = '0' then
            databus_reg <= RCVD_Data;
            Address_reg <= Address_reg + 1;
            if Address_reg = x"03" then
              current_state_reg <= request_end;
              Write_en_reg <= '0';
              Data_Read_reg <= '0';
              databus_reg <= x"FF";
            end if;
          else
            Address_reg <= x"03";--si son menos de 3 bytes, solo se ocupa de 0x00 a donde llegue, se mantienen los que no llegue --Es decir, si es uno, se mantienen intermeido y LSB como estaban o se ponen a cero?
            databus_reg <= x"FF";
            current_state_reg <= request_end;
            Write_en_reg <= '0';
            Data_Read_reg <= '0';
          end if;
          
        when request_end=>
          DMA_RQ_reg <= '0';
          if DMA_ACK = '0' then
            current_state_reg <= idle;
            READY_reg <= '1';
          end if;
            
        when pretransmision_1=>--se puede poner en *1
        --se supone TX_RDY en 1
          Valid_D_reg <= '0';
          Address_reg <= x"04";
          OE_reg <= '0';--habilitaci�n nivel bajo
          current_state_reg <= transmision_1;
          
        when transmision_1=>
          TX_Data_reg <= Databus_reg;
          if ACK_out = '0' then--activa a nivel bajo, llegada a RS232
            current_state_reg <= pretransmision_2;
            Valid_D_reg <= '1';
            OE_reg <= '1';
          end if;
          
        when pretransmision_2=>--se puede poner antes
          Valid_D_reg <= '0';
          Address_reg <= x"05";
          OE_reg <= '0';--habilitaci�n nivel bajo
          current_state_reg <= transmision_2;
          
        when transmision_2=>
          TX_Data_reg <= Databus_reg;
          if ACK_out = '0' then--activa a nivel bajo, llegada a RS232
            current_state_reg <= idle;
            Valid_D <= '1';
            OE_reg <= '1';
          end if;
      end case;
    end if;
  end process;
        
  
  --asignaci�n se�ales de salida
  Data_Read <= Data_Read_reg;
  Valid_D <= Valid_D_reg;
  TX_Data <= TX_Data_reg;
  Address <= Address_reg;
--  Databus <= Databus_reg;
  Databus <= Databus_reg when write_en_reg='1' else (others=> 'Z'); --Sale XXX en simulaci�n

  Write_en <= Write_en_reg;
  OE <= OE_reg;
  DMA_RQ <= DMA_RQ_reg;
  READY <= READY_reg;

END behavior;


