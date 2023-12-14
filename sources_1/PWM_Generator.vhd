library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.Numeric_Std.all;

entity PWM_Generator is
  generic (
    pwm_bits : positive := 4
  );
  port (
    clk : in std_logic;
    reset : in std_logic;
    percentage : in std_logic_vector(pwm_bits - 1 downto 0);
    pwm_out : out std_logic
  );
end PWM_Generator;

architecture Behavioral of PWM_Generator is

signal pwm_cnt : unsigned(pwm_bits - 1 downto 0):=(others=>'0');
constant contador_max : unsigned(16 downto 0):=to_unsigned(100000, 17);
signal duty_cycle : unsigned(contador_max'range);

begin

with percentage select
duty_cycle <=
   to_unsigned(0,contador_max'length) when "0000",  -- 0
   to_unsigned(10000,contador_max'length) when "0001",  -- 1
   to_unsigned(20000,contador_max'length) when "0010",  -- 2
   to_unsigned(30000,contador_max'length) when "0011",  -- 3
   to_unsigned(40000,contador_max'length) when "0100",  -- 4
   to_unsigned(50000,contador_max'length) when "0101",  -- 5
   to_unsigned(60000,contador_max'length) when "0110",  -- 6
   to_unsigned(70000,contador_max'length) when "0111",  -- 7
   to_unsigned(80000,contador_max'length) when "1000",  -- 8
   to_unsigned(90000,contador_max'length) when "1001",  -- 9
   to_unsigned(0,contador_max'length) when others;  -- E (error)


PWM_PROC : process(clk,reset)
    begin
      if rising_edge(clk)then
      
        if reset = '0' then
          pwm_cnt <= (others => '0');
          pwm_out <= '0';
        
        else 
          pwm_cnt <= pwm_cnt + 1;
          pwm_out <= '0';
          
        if pwm_cnt >= contador_max-1 then
          pwm_cnt <= (others => '0');
        end if;
        
        if pwm_cnt < duty_cycle then
          pwm_out <= '1';
        end if;
      end if; 
    end if;
  end process;

end Behavioral;
------------------------------------------------------------------------------------------------------------------
