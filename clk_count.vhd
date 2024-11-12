library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity clk_counter is
    generic (
        count_down : integer := 50000000  --  to 0.5s at 100 MHz
    );
    Port ( 
        clk    : in STD_LOGIC;
        reset  : in STD_LOGIC;
        count  : out STD_LOGIC_VECTOR(3 downto 0)  -- 4 bits to cover 16 addresses
    );
end clk_counter;

architecture Behavioral of clk_counter is
    signal counter    : unsigned(31 downto 0) := (others => '0');    -- 32-bit counter
    signal freq_sel   : unsigned(3 downto 0) := (others => '0');     -- 4-bit counter for 16 addresses
    constant count_limit : unsigned(31 downto 0) := to_unsigned(count_down, 32); -- chnaged this to help with thought process with timing protocol
begin
    process(clk, reset)
    begin 
        if rising_edge(clk) then
            if reset = '1' then    
                counter <= (others => '0');
                freq_sel <= (others => '0');  -- Reset to start of the song
            else
                if counter = count_limit then
                    -- Increment freq_sel and reset counter when limit is reached
                    if freq_sel = "1111" then
                        freq_sel <= (others => '0');  -- Loop back to start 
                    else
                        freq_sel <= freq_sel + 1;
                    end if;
                    counter <= (others => '0');
                else
                    counter <= counter + 1; -- count up to 50000000
                end if;
            end if;
        end if;
    end process;
    
    -- Output the current address for BRAM as std_logic_vector
    count <= std_logic_vector(freq_sel);

end Behavioral;
