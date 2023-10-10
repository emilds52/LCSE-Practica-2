
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library util;
use util.utility.ALL;

entity RS232_TX is
port (
    Clk    : in  std_logic;
    Reset  : in  std_logic;
    Start  : in  std_logic;
    Data   : in  std_logic_vector(7 downto 0);
    Speed  : in  speed_t;
    N_bits : in  nbits_t;
    EOT    : out std_logic;
    TX     : out std_logic
);
end RS232_TX;

architecture Behavioral of RS232_TX is

signal TX_reg  : std_logic;
signal EOT_reg : std_logic;

type state_t is (idle, StartBit, SendData, StopBit);
signal current_state_reg : state_t;

signal Speed_reg  : speed_t;
signal N_bits_reg : nbits_t;

constant pulse_width_default : unsigned(7 downto 0):=to_unsigned(174,8); -- 8 bits para representar 174: ceil(log2(174 + 1))
signal pulse_width     : unsigned(9 downto 0); -- 10 bits para poder representar 174*4 - 1 (ceil(log2(pulse_width_default*4)))
signal pulse_count_reg : unsigned(9 downto 0);
signal word_length     : unsigned(2 downto 0);
signal data_count_reg  : unsigned(2 downto 0);

begin
FSM:process(clk)
begin
    if rising_edge(clk) then
        if reset = '0' then
            TX_reg            <= '1';
            current_state_reg <= idle;
            Speed_reg         <= normal;
            N_bits_reg        <= eightBits;
            -- No hay reset para pulse_count_reg y data_count_reg porque no se evaluan en idle y se asigna un valor antes de pasar al siguiente estado
        else
            case current_state_reg is
                when Idle=>
                    -- Solo se admite un cambio en velocidad y bits en el estado de idle.
                    Speed_reg  <= Speed;
                    N_bits_reg <= N_bits;
                    if start='1' then
                        current_state_reg <= StartBit;
                        pulse_count_reg   <= (others=>'0');
                    end if;
                    
                when StartBit=>
                    TX_reg <= '0';
                    if pulse_count_reg = pulse_width then
                        current_state_reg <= SendData;
                        pulse_count_reg   <= (others=>'0');
                        data_count_reg    <= (others=>'0');
                    else
                        pulse_count_reg <= pulse_count_reg + 1;
                    end if;
                    
                when SendData=>
                    TX_reg <= data(to_integer(data_count_reg));
                    if pulse_count_reg = pulse_width then
                        pulse_count_reg <= (others=>'0');
                        if data_count_reg = word_length then
                            current_state_reg <= StopBit;
                        else
                            data_count_reg <= data_count_reg + 1;
                        end if;
                    else
                        pulse_count_reg <= pulse_count_reg + 1;
                    end if;
                    
                when StopBit=>
                    TX_reg <= '1';
                    if pulse_count_reg = pulse_width then
                        current_state_reg <= idle;
                        pulse_count_reg   <= (others=>'0');
                    else
                        pulse_count_reg <= pulse_count_reg + 1;
                    end if;
                    
            end case;
        end if;
    end if;
end process;


-- Multiplexor para decidir a qué pulse length contar, Speed_reg no cambia fuera de idle
pulse_width_comb:process(Speed_reg)
begin
    case( Speed_reg ) is
        when quarter =>
            -- hay que usar resize para que tenga el mismo número de bits. 
            -- No Debería suponer ningún problema ya que pulse_width tiene 10 bits para tener el valor de 174*4-1.
            pulse_width <= resize(pulse_width_default*4 - 1,pulse_width'length); 
        
        when half =>
            pulse_width <= resize(pulse_width_default*2 - 1,pulse_width'length);

        when normal =>
            pulse_width <= resize(pulse_width_default - 1,pulse_width'length);

        when doble =>
            pulse_width <= resize(pulse_width_default/2 - 1,pulse_width'length);

        when others =>
            pulse_width <= resize(pulse_width_default - 1,pulse_width'length);
    end case;
end process;


-- Multiplexor para decidir el numero de bits
N_bits_comb:process(N_bits_reg)
begin
    case( N_bits_reg ) is
        when fiveBits =>
            word_length <= to_unsigned(4,3);
        
        when sixBits =>
            word_length <= to_unsigned(5,3);

        when sevenBits =>
            word_length <= to_unsigned(6,3);

        when eightBits =>
            word_length <= to_unsigned(7,3);

        when others =>
            word_length <= to_unsigned(7,3); -- por si acaso
    end case;
end process;


-- EOT registrado para evitar glitches en la salida.
EOT_process:PROCESS(clk)
BEGIN
    IF rising_edge(clk) THEN
        if reset='0' then
            EOT_reg <= '1';
        else
            if current_state_reg=idle then
                EOT_reg <= '1';
            else 
                EOT_reg <= '0';
            end if;
        END IF;
    END IF;
END PROCESS;
        
-- Outputs:
TX  <= TX_reg;
EOT <= EOT_reg;

end Behavioral;