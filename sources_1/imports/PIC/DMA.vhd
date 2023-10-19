
LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;

USE work.PIC_pkg.all;

ENTITY DMA IS
PORT (
  Clk      : in    std_logic;
  Reset    : in    std_logic;
  RCVD_Data : in    std_logic;
  RX_Full : in    std_logic;
  RX_Empty : in    std_logic;
  Data_Read : out    std_logic;
  ACK_out : in    std_logic;
  TX_RDY : in    std_logic;
  Valid_D : out    std_logic;
  TX_Data  : out    std_logic_vector(7 downto 0);
  Address  : out std_logic_vector(7 downto 0);
  Databus : inout   std_logic_vector(7 downto 0);
  Write_en : out    std_logic;
  OED : out    std_logic; 
  DMA_RQ : out    std_logic;
  DMA_ACK : in    std_logic;
  Send_comm : in    std_logic;
  READY: out std_logic
    
);
END DMA;

ARCHITECTURE behavior OF DMA IS

begin

END behavior;

