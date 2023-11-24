
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
  OE        : out   std_logic;--Salida Habilitaci�n de la salida de la RAM; activo a nivel bajo
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
  write_FF,
  request_end,
  load_data,
  transmision
);

signal current_state_reg : state_t;
signal Address_reg: unsigned(2 downto 0); --solo se utiliza hasta x"05"
signal byte_count_reg: unsigned(2 downto 0); --solo se utiliza hasta x"03"
                                                
signal Databus_tmp: std_logic_vector(7 downto 0);
signal Write_en_tmp: std_logic;

signal send_comm_reg : std_logic;

begin

  Recepcion_transmision_process: process(clk, reset)
  begin
    if reset = '0' then
      Address_reg <= (others => '0');
      current_state_reg <= idle;
      byte_count_reg <= (others => '0');
            
    elsif rising_edge(clk) then
      case current_state_reg is
    
        when idle=>
          if Send_Comm = '1' and RX_Full = '0' then -- get data and set valid on the same cycle, data is gotten combinatorily
            current_state_reg <= load_data;
            Address_reg       <= to_unsigned(4, Address_reg'length);
          elsif RX_Empty = '0' and Send_Comm = '0' then--si memoria interna no vac�a, recibe datos --El orden es por llegada(MSB, Int, LSB)
            current_state_reg <= request;
          end if;
        
        when request=>
          if DMA_ACK = '1' then
            current_state_reg <= writing;
            Address_reg <= byte_count_reg;
            byte_count_reg <= byte_count_reg + 1;
          end if;
        
        when writing=>        
          if byte_count_reg = 3 then
            current_state_reg <= write_FF;
            Address_reg <= byte_count_reg;
            byte_count_reg <= (others=>'0');
          end if;
          if byte_count_reg < 3 then 
            Address_reg <= (others=>'0');
            current_state_reg <= request_end;
          end if;
        
        when write_FF=>
          Address_reg <= (others=>'0');
          current_state_reg <= request_end;
          
        when request_end=>
          if DMA_ACK = '0' then
            current_state_reg <= idle;
          end if;
            
        when load_data=>
          if ACK_out = '0' and TX_RDY = '0' then--cuando se recibe el dato en RS232 (ACK_out) y se est� enviando el dato(TX_RDY)
            current_state_reg <= transmision;
          end if;
          
        when transmision=>
          if Address_reg = 4 then
            current_state_reg <= load_data;
            Address_reg       <= to_unsigned(5, Address_reg'length);
          end if;
          if Address_reg = 5 then
            current_state_reg <= idle;
            Address_reg       <= (others=>'0');
          end if;

      end case;
    end if;
  end process;
  
  -- Combinatorily make signals from state to save registers
  with current_state_reg select
  Databus_tmp <= 
    RCVD_data      when writing,
    x"FF"          when write_ff,
    (others=> '0') when others;
  
  Write_en_tmp <= '1' when current_state_reg = writing or current_state_reg = write_ff else '0';

  --asignaci�n se�ales de salida
  Data_Read <= '1' when current_state_reg = writing else '0';
  Valid_D   <= '0' when current_state_reg = load_data else '1';
  TX_Data   <= databus; -- Connectar databus directamente ya que en RS232 se captura en un registro
  Address   <= "00000" & std_logic_vector(Address_reg);
  Databus   <= Databus_tmp when write_en_tmp = '1' else (others=> 'Z');
  Write_en  <= Write_en_tmp;
  OE        <= '0' when current_state_reg = load_data or 
                        current_state_reg = transmision else '1';
  DMA_RQ    <= '1' when current_state_reg = request or
                        current_state_reg = writing or
                        current_state_reg = write_ff else '0';
  READY     <= '0' when (current_state_reg = idle and send_comm = '1' and send_comm_reg= '0') or
                        current_state_reg /= idle and (not(current_state_reg = transmision and Address_reg = 5)) else '1';


  send_comm_proc : process( clk, Reset )
  begin
    if Reset = '0' then
      send_comm_reg <= '0';
    elsif rising_edge(clk) then
      send_comm_reg <= send_comm;
    end if;
  end process ; -- send_comm_proc
END behavior;


