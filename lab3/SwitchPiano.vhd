library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity SwitchPiano is
    Port ( 
        Clk      : in STD_LOGIC;
        switch   : in STD_LOGIC_VECTOR (7 downto 0);  -- Switches for tone selection
        stop     : in STD_LOGIC;                      -- Stop signal for reset
        freq     : out STD_LOGIC;                     -- Frequency output to audio amplifier
        LED      : out STD_LOGIC_VECTOR (7 downto 0); -- LEDs to show active switches
        gain     : out STD_LOGIC;                     -- Gain control for Pmod AMP2
        shutdown : out STD_LOGIC                      -- Shutdown control for Pmod AMP2
    );
end SwitchPiano;

architecture Behavioral of SwitchPiano is

    -- Array for frequencies
    type freq_array is array(7 downto 0) of integer;
    type march_array is array(7 downto 0) of integer;
    --constant NOTE_FREQS : freq_array := (38223, 34129, 30303, 28635, 25510, 22727, 20248, 19111);  -- Frequencies for C, D, E, F, G, A, B, High C
    constant NOTE_FREQS : freq_array := (19111, 20248, 22727, 25510, 28635, 30303, 34129, 38223);  -- Frequencies for C, D, E, F, G, A, B, High C
    constant march: march_array:= (454545,454545,454545,572672,286352,454545,572672,286352,454545);
    -- Signals for clock counters and tone generation
    signal clk_counter   : freq_array := (others => 0);
    signal tone          : std_logic_vector(7 downto 0) := (others => '0');
    signal tone_out      : std_logic := '0';  -- Output tone, result of combined frequencies

begin

    process(Clk, stop)
    begin
        -- Asynchronous reset with stop signal
        if stop = '1' then
            clk_counter <= (others => 0);    -- Clear all counters
            tone <= (others => '0');         -- Clear all tones
            tone_out <= '0';                 -- Clear the final output tone

        elsif rising_edge(Clk) then
            -- Iterate over each switch and generate corresponding tone if stop signal is inactive
            if stop = '0' then  -- Only generate tones if stop is not active
                for i in 0 to 7 loop
                    if switch(i) = '1' then
                        if clk_counter(i) = 0 then
                            clk_counter(i) <= NOTE_FREQS(i);  -- Load frequency for note
                            tone(i) <= not tone(i);           -- Toggle tone signal
                        else
                            clk_counter(i) <= clk_counter(i) - 1;
                        end if;
                    else
                        tone(i) <= '0';  -- No tone if switch not active
                    end if;
                end loop;
            else
                -- If stop is active, set all tones to 0
                tone <= (others => '0');
            end if;

            -- Combine tones to form chord (OR operation for combining)
            tone_out <= tone(0) or tone(1) or tone(2) or tone(3) or tone(4) or tone(5) or tone(6) or tone(7);
        end if;
    end process;

    -- Send the combined tone to freq output
    freq <= tone_out;

    -- Map switches to the LEDs to show active switches
    LED <= switch;

    -- Set gain and shutdown for Pmod AMP2
    gain <= '1';  -- -6dB gain
    shutdown <= '1';  -- Keep amplifier active

end Behavioral;
