
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
END DMA;

ARCHITECTURE behavior OF DMA IS

type state_RX_t is (idle, request, writing, request_end);
signal current_state_RX_reg : state_RX_t;
signal next_state_RX : state_RX_t;
--type state_RX_t is (LSB, mid, MSB);
--signal current_state_RX_reg : state_RX_t;

type state_TX_t is (idle, pretransmision_1, transmision_1, pretransmision_2, transmision_2);
signal current_state_TX_reg : state_TX_t;
signal next_state_TX : state_TX_t;

signal Data_Read_reg: std_logic;
signal Valid_D_reg: std_logic;
signal TX_Data_reg: std_logic_vector(7 downto 0);
signal Address_reg: std_logic_vector(7 downto 0);
                                                
signal Databus_reg: std_logic_vector(7 downto 0);
signal Write_en_reg: std_logic;
signal OE_reg: std_logic;
signal DMA_RQ_reg: std_logic;
signal READY_reg: std_logic;

signal Data_Read_tmp: std_logic;
signal Valid_D_tmp: std_logic;
signal TX_Data_tmp: std_logic_vector(7 downto 0);
signal Address_tmp: std_logic_vector(7 downto 0);                              
signal Databus_tmp: std_logic_vector(7 downto 0);
signal Write_en_tmp: std_logic;
signal OE_tmp: std_logic;
signal DMA_RQ_tmp: std_logic;
signal READY_tmp: std_logic;

begin

  Recepcion_process: process(clk, reset)
  begin
    if reset = '0' then
      --
    elsif rising_edge(clk) then
      case current_state_RX_reg is
      
        when idle=>
          if RX_Empty = '0' then--si memoria interna no vacía, recibe datos
            --siempre vienen 3 bytes? El orden es por llegada(MSB, Int, LSB)
            next_state_RX <= request;
          end if;
        
        when request=>
          DMA_RQ_tmp <= '1';--Petición de buses
          if DMA_ACK = '1' then
            next_state_RX <= writing;
            Write_en_tmp <= '1';
            Data_Read_tmp <= '1';
            Address_tmp <= x"00";
          end if;
        
        when writing=>        
          --Data_read_tmp <= '1';--hay que hacerla un ciclo antes para haber recibido el byte
          --Write_en_tmp <= '1';--hay que hacerlo un ciclo antes
          if RX_Empty = '0' then
            Databus_tmp <= RCVD_Data;
            Address_tmp <= Address_reg + 1;
            if Address_reg = x"03" then
              next_state_RX <= request_end;
              Write_en_tmp <= '0';
              Data_Read_tmp <= '0';
              Databus_tmp <= x"FF";
            end if;
          else
            Address_tmp <= x"03";--si son menos de 3 bytes, solo se ocupa de 0x00 a donde llegue, se mantienen los que no llegue --Es decir, si es uno, se mantienen intermeido y LSB como estaban o se ponen a cero?
            Databus_tmp <= x"FF";
            next_state_RX <= request_end;
            Write_en_tmp <= '0';
            Data_Read_tmp <= '0';
          end if;
          
        when request_end=>
          DMA_RQ_tmp <= '0';
          if DMA_ACK = '0' then
            next_state_RX <= idle;
          end if;
      end case;
    end if;
  end process;
  
  Transmision_process: process(Clk, Reset)
  begin
    if reset = '0' then
    --
    elsif rising_edge(clk) then
      case current_state_TX_reg is
        when idle=>
          READY <= '1';
          if Send_Comm = '1' then
            next_state_TX <= transmision_1;
            READY <= '0';
            --*1
          end if;
        when pretransmision_1=>--se puede poner en *1
        --se supone TX_RDY en 1
          Valid_D_tmp <= '0';
          Address_tmp <= x"04";
          OE_tmp <= '0';--habilitación nivel bajo
          next_state_TX <= transmision_1;
          
        when transmision_1=>
          
          TX_Data_tmp <= Databus_reg;
          if ACK_out = '0' then--activa a nivel bajo, llegada a RS232
            next_state_TX <= pretransmision_2;
            Valid_D_tmp <= '1';
            OE_tmp <= '1';
          end if;
          
        when pretransmision_2=>--se puede poner antes
          Valid_D_tmp <= '0';
          Address_tmp <= x"05";
          OE_tmp <= '0';--habilitación nivel bajo
          next_state_TX <= transmision_2;
          
        when transmision_2=>
          TX_Data_tmp <= Databus_reg;
          if ACK_out = '0' then--activa a nivel bajo, llegada a RS232
            next_state_TX <= idle;
            Valid_D <= '1';
            OE_tmp <= '1';
          end if;
      end case;
    end if;
  end process;
        
  register_process: process( Clk, Reset)
  begin
    if reset='0' then
      Data_Read_reg <= '0';
      Valid_D_reg <= '1';--activa a nivel bajo
      TX_Data_reg <= (others => '0');
      Address_reg <= x"00";
      Databus_reg <= (others=>'Z');
      Write_en_reg <= '0';
      OE_reg <= '0';
      DMA_RQ_reg <= '0';
      READY_reg <= '0'; --procesador no ocioso
      current_state_RX_reg <= idle;
      
    elsif rising_edge(clk) then
      Data_Read_reg <= Data_Read_tmp;
      Valid_D_reg <= Valid_D_tmp;
      TX_Data_reg <= TX_Data_tmp;
      Address_reg <= Address_tmp;
      Databus_reg <= Databus_tmp;
      Write_en_reg <= Write_en_tmp;
      OE_reg <= OE_tmp;
      DMA_RQ_reg <= DMA_RQ_tmp;
      READY_reg <= READY_tmp;
      current_state_RX_reg <= next_state_RX;
    end if;
  end process;
  
  --asignación señales de salida
  Data_Read <= Data_Read_reg;
  Valid_D <= Valid_D_reg;
  TX_Data <= TX_Data_reg;
  Address <= Address_reg;
  Databus <= Databus_reg when current_state_RX_reg = writing else (others => 'Z');
  Write_en <= Write_en_reg;
  OE <= OE_reg;
  DMA_RQ <= DMA_RQ_reg;
  READY <= READY_reg;

END behavior;


