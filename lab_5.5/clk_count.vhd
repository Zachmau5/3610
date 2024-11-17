library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity clk_counter is
    generic (
        count_down : integer := 50000000  -- Adjusts to 0.5s at 100 MHz clock
    );
    Port ( 
        clk    : in STD_LOGIC;
        reset  : in STD_LOGIC;
        count  : out STD_LOGIC_VECTOR(3 downto 0)  -- 4-bit output for BRAM addresses (0-15)
    );
end clk_counter;

architecture Behavioral of clk_counter is
    -- Internal signals for counting
    signal counter    : unsigned(31 downto 0) := (others => '0');    -- 32-bit counter
    signal freq_sel   : unsigned(3 downto 0) := (others => '0');     -- 4-bit counter for 16 addresses
    constant count_limit : unsigned(31 downto 0) := to_unsigned(count_down, 32);  -- Set the count limit based on input

begin
    process(clk, reset)
    begin 
        if reset = '1' then
            -- Reset condition: Clear counters and start from the beginning
            counter <= (others => '0');
            freq_sel <= (others => '0');  -- Reset address to start of sequence

        elsif rising_edge(clk) then
            if counter = count_limit then
                -- Increment `freq_sel` and reset `counter` when `count_limit` is reached
                counter <= (others => '0');  -- Reset the main counter

                if freq_sel = "1111" then
                    freq_sel <= (others => '0');  -- Reset to zero after reaching the last address
                else
                    freq_sel <= freq_sel + 1;
                end if;

            else
                -- Increment the main counter until it reaches `count_limit`
                counter <= counter + 1;
            end if;
        end if;
    end process;
    
    -- Output `freq_sel` as the 4-bit address for BRAM
    count <= std_logic_vector(freq_sel);

end Behavioral;
