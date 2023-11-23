
LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;
library util;
USE util.PIC_pkg.all;

entity PICtop is
  port (
    Reset       : in  std_logic;           -- Asynchronous, active low
    Clk         : in  std_logic;           -- System clock, 20 MHz, rising_edge

    RS232_RX    : in  std_logic;           -- RS232 RX line
    RS232_TX    : out std_logic;           -- RS232 TX line
    switches    : out std_logic_vector(7 downto 0);   -- Switch status bargraph
    Temp_L      : out std_logic_vector(6 downto 0);   -- Display value for TL
    Temp_H      : out std_logic_vector(6 downto 0));  -- Display value for TH
end PICtop;


architecture behavior of PICtop is

  -----------------------------------------------------------------------
  --  RS232
  ------------------------------------------------------------------------
  
  component RS232top
    port (
      Reset     : in  std_logic;
      Clk       : in  std_logic;
      Data_in   : in  std_logic_vector(7 downto 0);
      Valid_D   : in  std_logic;
      Ack_in    : out std_logic;
      TX_RDY    : out std_logic;
      TD        : out std_logic;
      RD        : in  std_logic;
      Data_out  : out std_logic_vector(7 downto 0);
      Data_read : in  std_logic;
      Full      : out std_logic;
      Empty     : out std_logic;
      Speed     : in std_logic_vector(1 downto 0);
      N_bits    : in std_logic_vector(1 downto 0));
  end component;

  ------------------------------------------------------------------------
  -- RAM
  ------------------------------------------------------------------------
  
   component RAM
    port (
      Clk      : in    std_logic;
      Reset    : in    std_logic;
      write_en : in    std_logic;
      oe       : in    std_logic;
      address  : in    std_logic_vector(7 downto 0);
      databus  : inout std_logic_vector(7 downto 0);
      Switches : out   std_logic_vector(7 downto 0);
      Temp_L   : out   std_logic_vector(6 downto 0);
      Temp_H   : out   std_logic_vector(6 downto 0));
  end component;
  
  ------------------------------------------------------------------------
  --  DMA
  ------------------------------------------------------------------------
  
   component DMA
    port (
      Reset     : in    STD_LOGIC;
      Clk       : in    STD_LOGIC;
      RCVD_Data : in    STD_LOGIC_VECTOR (7 downto 0);
      RX_Full   : in    STD_LOGIC;
      RX_Empty  : in    STD_LOGIC;
      Data_Read : out   STD_LOGIC;
      ACK_out   : in    STD_LOGIC;
      TX_RDY    : in    STD_LOGIC;
      Valid_D   : out   STD_LOGIC;
      TX_Data   : out   STD_LOGIC_VECTOR (7 downto 0);
      Address   : out   STD_LOGIC_VECTOR (7 downto 0);
      Databus   : inout STD_LOGIC_VECTOR (7 downto 0);
      Write_en  : out   STD_LOGIC;
      OE        : out   STD_LOGIC;
      DMA_RQ    : out   STD_LOGIC;
      DMA_ACK   : in    STD_LOGIC;
      Send_comm : in    STD_LOGIC;
      READY     : out   STD_LOGIC
    );
  end component;
  
  ------------------------------------------------------------------------
  --  CPU
  ------------------------------------------------------------------------
  
  component CPU
    port (
      Reset     : in    STD_LOGIC;
      Clk       : in    STD_LOGIC;
      ROM_Data  : in    STD_LOGIC_VECTOR (11 downto 0);
      ROM_Addr  : out   STD_LOGIC_VECTOR (11 downto 0);
      RAM_Addr  : out   STD_LOGIC_VECTOR (7 downto 0);
      RAM_Write : out   STD_LOGIC;
      RAM_OE    : out   STD_LOGIC;
      Databus   : inout STD_LOGIC_VECTOR (7 downto 0);
      DMA_RQ    : in    STD_LOGIC;
      DMA_ACK   : out   STD_LOGIC;
      SEND_comm : out   STD_LOGIC;
      DMA_READY : in    STD_LOGIC;
      Alu_op    : out   alu_op;
      Index_Reg : in    STD_LOGIC_VECTOR (7 downto 0);
      FlagZ     : in    STD_LOGIC;
      FlagC     : in    STD_LOGIC;
      FlagN     : in    STD_LOGIC;
      FlagE     : in    STD_LOGIC
    );
  end component;

  ------------------------------------------------------------------------
  --  ALU
  ------------------------------------------------------------------------  

  component ALU
    port (
      Reset         : in    std_logic;
      Clk           : in    std_logic;
      u_instruction : in    alu_op;
      FlagZ         : out   std_logic;
      FlagC         : out   std_logic;
      FlagN         : out   std_logic;
      FlagE         : out   std_logic;
      Index         : out   std_logic_vector(7 downto 0);
      Databus       : inout std_logic_vector(7 downto 0)
    );
  end component;

  ------------------------------------------------------------------------
  --  ROM
  ------------------------------------------------------------------------  

  component ROM
    port (
      Instruction     : out std_logic_vector(11 downto 0);
      Program_counter : in  std_logic_vector(11 downto 0)
    );
  end component;

  -- RS232 y DMA 
  
  signal TX_Data      : STD_LOGIC_VECTOR (7 downto 0);
	signal RCVD_Data    : STD_LOGIC_VECTOR (7 downto 0);
	signal Addr_DMA     : STD_LOGIC_VECTOR (7 downto 0);
	signal Valid_D      : STD_LOGIC;
	signal Ack_out      : STD_LOGIC;
	signal TX_RDY       : STD_LOGIC;
	signal Data_Read    : STD_LOGIC;
	signal Full         : STD_LOGIC;
	signal Empty        : STD_LOGIC;
	signal Write_en_DMA : STD_LOGIC;
	signal OE_DMA       : STD_LOGIC;
  signal DMA_RQ       : STD_LOGIC;
  signal DMA_ACK      : STD_LOGIC;
  signal Send_comm    : STD_LOGIC;
  signal DMA_READY        : STD_LOGIC;

  signal write_en_mem, oe_mem : STD_LOGIC;
  signal address_mem  : STD_LOGIC_VECTOR(7 downto 0);

  -- CPU, ALU y ROM

  signal Write_en_CPU : std_logic;
  signal OE_CPU       : std_logic;
  signal Addr_CPU     : std_logic_vector(7 downto 0);
  signal Alu_op       : alu_op;
  signal Index_Reg    : std_logic_vector(7 downto 0);
  signal FlagZ        : std_logic;
  signal FlagC        : std_logic;
  signal FlagN        : std_logic;
  signal FlagE        : std_logic;

  signal ROM_Data : std_logic_vector(11 downto 0);
  signal ROM_Addr : std_logic_vector(11 downto 0);

  signal Databus : std_logic_vector(7 downto 0);

begin  -- behavior

  RS232_PHY: RS232top
    port map (
      Reset     => Reset,
      Clk       => Clk,
      Data_in   => TX_Data,
      Valid_D   => Valid_D,
      Ack_in    => ACK_out,
      TX_RDY    => TX_RDY,
      TD        => RS232_TX,
      RD        => RS232_RX,
      Data_out  => RCVD_Data,
      Data_read => Data_read,
      Full      => Full,
      Empty     => Empty,
      Speed     => "10", --115200
      N_bits    => "11" --8 bits
    );

  RAM_PHY: RAM
    port map (
      Reset    => Reset,
      Clk      => Clk,
      write_en => write_en_mem,
      oe       => oe_mem,
      address  => address_mem,
      databus  => databus,
      Switches => switches,
      Temp_L   => Temp_L,
      Temp_H   => Temp_H 
    );
        
  DMA_PHY: DMA
    port map (
      Reset     => Reset,
      Clk       => Clk,
      RCVD_Data => RCVD_Data,
      RX_Full   => Full,
      RX_Empty  => Empty,
      Data_Read => Data_Read,
      ACK_out   => ACK_out,
      TX_RDY    => TX_RDY,
      Valid_D   => Valid_D,
      TX_Data   => TX_Data,
      Address   => Addr_DMA,
      Databus   => Databus,
      Write_en  => Write_en_DMA,
      OE        => OE_DMA,
      DMA_RQ    => DMA_RQ,
      DMA_ACK   => DMA_ACK,
      Send_comm => Send_comm,
      READY     => DMA_READY
    );

  CPU_PHY: CPU
    port map (
      Reset     => Reset,
      Clk       => Clk,
      ROM_Data  => ROM_Data,
      ROM_Addr  => ROM_Addr,
      RAM_Addr  => Addr_CPU,
      RAM_Write => Write_en_CPU,
      RAM_OE    => OE_CPU,
      Databus   => Databus,
      DMA_RQ    => DMA_RQ,
      DMA_ACK   => DMA_ACK,
      SEND_comm => SEND_comm,
      DMA_READY => DMA_READY,
      Alu_op    => Alu_op,
      Index_Reg => Index_Reg,
      FlagZ     => FlagZ,
      FlagC     => FlagC,
      FlagN     => FlagN,
      FlagE     => FlagE
    );
  
  ALU_PHY: ALU
    port map (
      Reset         => Reset,
      Clk           => Clk,
      u_instruction => alu_op,
      FlagZ         => FlagZ,
      FlagC         => FlagC,
      FlagN         => FlagN,
      FlagE         => FlagE,
      Index         => Index_Reg,
      Databus       => Databus
    );

  ROM_PHY: ROM
    port map (
      Instruction     => ROM_Data,
      Program_counter => ROM_Addr
    );
   
  -- RAM_signals

  write_en_mem <= Write_en_DMA or Write_en_CPU;
  oe_mem       <= OE_DMA and OE_CPU;
  address_mem  <= Addr_DMA or Addr_CPU;

end behavior;

