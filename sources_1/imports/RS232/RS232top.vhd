
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;  
 
library util;
use util.utility.all;   

entity RS232top is

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

end RS232top;

architecture RTL of RS232top is
 
 ------------------------------------------------------------------------
  -- Components for Transmitter Block
  ------------------------------------------------------------------------

  component RS232_TX
    port (
      Clk   : in  std_logic;
      Reset : in  std_logic;
      Start : in  std_logic;
      Data  : in  std_logic_vector(7 downto 0);
      Speed  : in  speed_t;
      N_bits : in  nbits_t;
      EOT    : out std_logic;
      TX     : out std_logic
      );
  end component;

  ------------------------------------------------------------------------
  -- Components for Receiver Block
  ------------------------------------------------------------------------

  component ShiftRegister
    port (
      Reset  : in  std_logic;
      Clk    : in  std_logic;
      Enable : in  std_logic;
      D      : in  std_logic;
      Q      : out std_logic_vector(7 downto 0));
  end component;

  component RS232_RX
    port (
      Clk       : in  std_logic;
      Reset     : in  std_logic;
      LineRD_in : in  std_logic;
      Speed     : in  speed_t;
      N_bits    : in  nbits_t;
      Valid_out : out std_logic;
      Code_out  : out std_logic;
      Store_out : out std_logic);
  end component;

  component fifo
    port (
      clk   : IN  std_logic;
      srst  : IN  std_logic;
      din   : IN  std_logic_VECTOR(7 downto 0);
      wr_en : IN  std_logic;
      rd_en : IN  std_logic;
      dout  : OUT std_logic_VECTOR(7 downto 0);
      full  : OUT std_logic;
      empty : OUT std_logic);
  end component;

  ------------------------------------------------------------------------
  -- Internal Signals
  ------------------------------------------------------------------------

  signal Data_FF    : std_logic_vector(7 downto 0);
  signal StartTX    : std_logic;  -- start signal for transmitter
  signal LineRD_in  : std_logic;  -- internal RX line
  signal Valid_out  : std_logic;  -- valid bit at the receiver
  signal Code_out   : std_logic;  -- bit at the receiver output
  signal sinit      : std_logic;  -- fifo reset
  signal Fifo_in    : std_logic_vector(7 downto 0);
  signal Fifo_write : std_logic;
  signal TX_RDY_i   : std_logic;
  -- Signals to convert from std_logic_vector to enum types
  signal speed_tmp : speed_t;
  signal nbits_tmp : nbits_t;
  
begin  -- RTL

speed_tmp <= speed_t'val(to_integer(unsigned(speed)));
nbits_tmp <= nbits_t'val(to_integer(unsigned(n_bits)));

  Transmitter: RS232_TX
    port map (
      Clk   => Clk,
      Reset => Reset,
      Start => StartTX,
      Data  => Data_FF,
      Speed => speed_tmp,
      N_bits => nbits_tmp,
      EOT   => TX_RDY_i,
      TX    => TD
      );

  Receiver: RS232_RX
    port map (
      Clk       => Clk,
      Reset     => Reset,
      LineRD_in => LineRD_in,
      Speed => speed_tmp,
      N_bits => nbits_tmp,
      Valid_out => Valid_out,
      Code_out  => Code_out,
      Store_out => Fifo_write
      );

  Shift: ShiftRegister
    port map (
      Reset  => Reset,
      Clk    => Clk,
      Enable => Valid_Out,
      D      => Code_Out,
      Q      => Fifo_in);

  sinit <= not reset;
  
  Internal_memory: fifo
    port map (
      clk   => clk,
      srst  => sinit,
      din   => Fifo_in,
      wr_en => Fifo_write,
      rd_en => Data_read,
      dout  => Data_out,
      full  => Full,
      empty => Empty);

  -- purpose: Clocking process for input protocol
  Clocking : process (Clk, Reset)
  begin
    if Reset = '0' then  -- asynchronous reset (active low)
      Data_FF   <= (others => '0');
      LineRD_in <= '1';
      Ack_in    <= '1';
    elsif rising_edge(Clk) then  -- rising edge of the clock
      LineRD_in <= RD;
      if Data_read = '1' then
          Data_FF <= Data_in;
      end if;
      if Valid_D = '0' and TX_RDY_i = '1' then
        Ack_in  <= '0';
        StartTX <= '1';
      else
        Ack_in  <= '1';
        StartTX <= '0';
      end if;
    end if;
  end process Clocking;

  TX_RDY <= TX_RDY_i;

end RTL;

