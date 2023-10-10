library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity RS232_RX_tb is
end RS232_RX_tb;

architecture Behavioral of RS232_RX_tb is

    component RS232_TX is
        port (
          Clk   : in  std_logic;
          Reset : in  std_logic;
          Start : in  std_logic;
          Data  : in  std_logic_vector(7 downto 0);
          EOT   : out std_logic;
          TX    : out std_logic);
    end component;
    
    component RS232_RX is
        port (
            Clk       : in  std_logic;
            Reset     : in  std_logic;
            LineRD_in : in  std_logic;
            Valid_out : out std_logic;
            Code_out  : out std_logic;
            Store_out : out std_logic
        );
    end component;
    
    signal clk: std_logic := '0';
    signal reset: std_logic := '0';
    signal LineRD_in: std_logic := '0';
    signal Valid_out : std_logic;
    signal Code_out  : std_logic;
    signal Store_out : std_logic;
    
    constant clk_period: time := 10 ns; --20 MHz
    
    signal Start:std_logic:='0';
    signal Data: std_logic_vector(7 downto 0):=(others=>'0');
    signal EOT: std_logic:='0';
    
    begin
    
    TX: RS232_TX
    port map(
        CLK=>CLK,
        RESET=>RESET,
        STart=>STart,
        Data=>DAta,
        EOT=>EOT,
        TX=>LineRD_in
    );
    
    RX: RS232_RX
    port map(
        CLK=>CLK,
        RESET=>RESET,
        LineRD_in=>LineRD_in,
        Valid_out=>Valid_out,
        Code_out=>Code_out,
        Store_out=>Store_out
    );
    
    process
    begin
        Clk <= '0';
        wait for clk_period/2;
        Clk <= '1';
        wait for clk_period/2;
    end process;
    
    process
    begin
        wait for 35 ns;
        RESET<='1';
        Start<='0';
        wait for 35 ns;
        Start<='1';
        Data <= "10000011";
        wait for 35 us;
        Data <= "10101010";
        wait for 35 us;
        Data <= "01001111";
        wait for 35 us;
        Data <= "11110000";
        wait for 35 us;
        start<='0';
        wait for 35 us;
        wait;
    end process;

end Behavioral;
