LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;

library util;
USE util.PIC_pkg.all;
USE util.RS232_test.all;

entity terna_tb is
end terna_tb;

architecture TestBench of terna_tb is

  component terna is
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
  end component;
  
  signal Reset    : std_logic;
  signal Clk      : std_logic;
  signal RS232_RX : std_logic;
  signal RS232_TX : std_logic;
  signal DMA_RQ   : std_logic;
  signal DMA_ACK  : std_logic := '0';
  signal Send     : std_logic := '0';
  signal READY    : std_logic;
  
  begin
 
  terna_inst: terna
    port map(
      Clk      => Clk,
      Reset    => Reset,
      RS232_RX => RS232_RX,
      RS232_TX => RS232_TX,
      Send     => Send,
      DMA_ACK  => DMA_ACK,
      READY    => READY,
      DMA_RQ   => DMA_RQ
    );
  
    -----------------------------------------------------------------------------
    -- Reset & clock generator
    -----------------------------------------------------------------------------
    
      Reset <= '0', '1' after 75 ns;
    
      p_clk : PROCESS
      BEGIN
         clk <= '1', '0' after 25 ns;
         wait for 50 ns;
      END PROCESS;
    
    -------------------------------------------------------------------------------
    -- Sending some stuff through RS232 port
    -------------------------------------------------------------------------------
    
      ack_process: process(DMA_RQ)
      begin
        if (DMA_RQ = '1') then
          DMA_ACK <= '1';
          wait for 20 ns;
        elsif DMA_RQ = '0' then
          DMA_ACK <= '1';
          wait for 20 ns;
        end if;
      end process;
      
      SEND_STUFF : process
      begin
       RS232_RX <= '1';
       wait for 40 us;
       Transmit(RS232_RX, X"49");
       Transmit(RS232_RX, X"34");
       Transmit(RS232_RX, X"31");
       Transmit(RS232_RX, X"89");
      
       wait;
      end process SEND_STUFF;
  
  end architecture;