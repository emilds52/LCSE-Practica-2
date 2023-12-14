library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.Numeric_Std.all;

library util;
USE util.utility.all;
USE util.PIC_pkg.all;

entity TricolorLED is
  port (
    clk : in std_logic;
    reset : in std_logic;
    Actuators : in array_of_std4_t(5 downto 0);
    PWM_LEDs : out std_logic_vector(5 downto 0)
  );
end TricolorLED;

architecture Behavioral of TricolorLED is

component PWM_Generator is
  generic (
    pwm_bits : positive := 4
  );
  port (
    clk : in std_logic;
    reset : in std_logic;
    percentage : in std_logic_vector(pwm_bits - 1 downto 0);
    pwm_out : out std_logic
  );
end component;

begin

  LED_PWM_gen : for i in 0 to 5 generate
  begin
    PWM_LED_i_INST: PWM_Generator
    generic map(
      pwm_bits => 4
      )
      port map (
        CLK    => CLK,
        Reset  => Reset,
        percentage => Actuators(i),
        pwm_out   => PWM_LEDs(i) 
        );
  end generate;



end architecture;
