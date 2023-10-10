library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library util;
use util.utility.ALL;


entity RS232_RX is
port (
    Clk       : in  std_logic;
    Reset     : in  std_logic;
    LineRD_in : in  std_logic;
    Speed     : in  speed_t;
    N_bits    : in  nbits_t;
    Valid_out : out std_logic;
    Code_out  : out std_logic;
    Store_out : out std_logic
);
end RS232_RX;

architecture Behavioral of RS232_RX is
    -- Salidas
    signal Valid_reg : std_logic;
    signal Code_reg  : std_logic;
    signal Store_reg : std_logic;
    signal Valid_tmp : std_logic;
    signal Code_tmp  : std_logic;
    signal Store_tmp : std_logic;
    -- Internos
    constant pulse_width_default : unsigned(7 downto 0):=to_unsigned(174,8);
    signal   pulse_width         : unsigned(9 downto 0);
    signal   bitCounter_reg      : unsigned(9 downto 0);
    signal   bitCounter_tmp      : unsigned(9 downto 0);
    signal   word_length         : unsigned(2 downto 0);
    signal   data_count_reg      : unsigned(2 downto 0);
    signal   data_count_tmp      : unsigned(2 downto 0);
    signal   stopFlag_reg        : std_logic;
    signal   stopFlag_tmp        : std_logic;
    signal   Speed_reg           : speed_t;
    signal   Speed_tmp           : speed_t;
    signal   N_bits_reg          : nbits_t;
    signal   N_bits_tmp          : nbits_t;
    signal   zeroFillCondition   : boolean;

    type state_t is (idle, StartBit, RcvData, StopBit);
    signal current_state_reg : state_t;
    signal next_state        : state_t;
begin
    
    comb:process(LineRD_in, current_state_reg, bitCounter_reg, stopFlag_reg, data_count_reg, Speed, N_bits, Speed_reg, N_bits_reg, pulse_width, word_length, zeroFillCondition) --process(all) da error de sintaxis no soportado desde 1076-2008
    begin
        -- Valores por defecto
        next_state     <= current_state_reg;
        data_count_tmp <= data_count_reg;
        stopFlag_tmp   <= stopFlag_reg;
        bitCounter_tmp <= (others => '0');
        Valid_tmp      <= '0';
        Code_tmp       <= '0';
        Store_tmp      <= '0';
        Speed_tmp      <= Speed_reg;
        N_bits_tmp     <= N_bits_reg;
        
        case(current_state_reg) is
        
            when idle =>
                data_count_tmp <= (others => '0');
                stopFlag_tmp   <= '0';
                -- Solo actualizar la velocidad de transmisón y el número de bits en el estado de idle
                Speed_tmp <= Speed;
                N_bits_tmp <= N_bits;
                if LineRD_in = '0' then
                    next_state <= StartBit;
                end if;
            
            when StartBit =>
                -- Contar hasta medio pulso para muestrar en el centro
                if bitCounter_reg = ('0' & pulse_width(9 downto 1)) then -- Un bitshift para dividir entre 2
                    bitCounter_tmp <= (others=>'0');
                    next_state     <= RcvData;
                else 
                    bitCounter_tmp <= bitCounter_reg + 1;
                end if;  
            
            when RcvData =>
                if bitCounter_reg = pulse_width then
                    Valid_tmp <= '1';
                    Code_tmp  <= LineRD_in;
                    if data_count_reg = word_length then
                        next_state <= StopBit;
                    else
                        bitCounter_tmp <= (others=>'0');
                        data_count_tmp <= data_count_reg + 1;
                    end if;
                else
                    bitCounter_tmp <= bitCounter_reg + 1;   
                end if;
                    
            when StopBit =>
                if (bitCounter_reg = pulse_width and stopFlag_reg='0') then
                    Store_tmp      <= LineRD_in;
                    bitCounter_tmp <= (others=>'0');
                    stopFlag_tmp   <= '1';
                elsif (bitCounter_reg = ('0' & pulse_width(9 downto 1)) and stopFlag_reg='1') then -- bitshift para dividir por dos
                    stopFlag_tmp   <= '0';
                    next_state     <= idle;
                else 
                    bitCounter_tmp <= bitCounter_reg + 1;
                    -- Rellenar con ceros si usamos menos de 8 bits
                    if zeroFillCondition then
                        Valid_tmp <= '1';
                        Code_tmp  <= '0';
                    end if;
                end if;

            when others =>
                -- Valores por defecto
                
        end case ;
    end process;
    
    -- Lógica combinacional para calcular si hay que rellenar con ceros en el caso de menos de 8 bits
    zeroFillCondition <= ((bitCounter_reg = to_unsigned(0,bitCounter_reg'length)) and (N_bits_reg /= eightbits)) or
                         ((bitCounter_reg = to_unsigned(1,bitCounter_reg'length)) and (N_bits_reg = fivebits or N_bits_reg = sixbits)) or
                         ((bitCounter_reg = to_unsigned(2,bitCounter_reg'length)) and (N_bits_reg = fivebits));

    -- Multiplexor para decidir a qué pulse length contar, Speed_reg no cambia fuera de idle
    pulse_width_comb:process(Speed_reg)
    begin
        case( Speed_reg ) is
            when quarter =>
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

    regs : process( clk, reset )
    begin
        if reset='0' then
            bitCounter_reg    <= (others => '0');
            data_count_reg    <= (others => '0');
            stopFlag_reg      <= '0';
            Valid_reg         <= '0';
            Code_reg          <= '0';
            Store_reg         <= '0';
            current_state_reg <= idle;
            Speed_reg         <= normal;
            N_bits_reg        <= eightBits;
        elsif rising_edge(clk) then
            bitCounter_reg    <= bitCounter_tmp;
            data_count_reg    <= data_count_tmp;
            stopFlag_reg      <= stopFlag_tmp;
            Valid_reg         <= Valid_tmp;
            Code_reg          <= Code_tmp;
            Store_reg         <= Store_tmp;
            current_state_reg <= next_state;
            Speed_reg         <= Speed_tmp;
            N_bits_reg        <= N_bits_tmp;
        end if;
    end process;
    
    -- Salidas
    Valid_out <= Valid_reg;
    Code_out  <= Code_reg;
    Store_out <= Store_reg;

end Behavioral;
