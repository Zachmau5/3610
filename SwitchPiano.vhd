library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity SwitchPiano is
    Port (
        clk         : in STD_LOGIC;
        stop        : in STD_LOGIC;
        switch      : in STD_LOGIC_VECTOR(7 downto 0);  -- Switches for note selection in Mode A
        mode_select : in STD_LOGIC_VECTOR(2 downto 0);  -- Mode selection input
        freq        : out STD_LOGIC;
        gain        : out STD_LOGIC;
        shutdown    : out STD_LOGIC;
        LED         : out STD_LOGIC_VECTOR(7 downto 0);
        an          : out STD_LOGIC_VECTOR(3 downto 0);
        cat         : out STD_LOGIC_VECTOR(6 downto 0)
    );
end SwitchPiano;

architecture Behavioral of SwitchPiano is
    -- Frequency constants for each note
    type freq_array is array(7 downto 0) of integer;
    constant NOTE_FREQS : freq_array := (382219 / 2, 340530 / 2, 303379 / 2, 286345 / 2,
                                    255102 / 2, 227273 / 2, 202478 / 2, 191113 / 2);

    -- States for the state machine
    type state_type is (idle, tonegen);
    signal state        : state_type := idle;
    signal clk_counter  : freq_array := (others => 0);  -- Counters for each tone frequency
    signal tone         : std_logic_vector(7 downto 0) := (others => '0'); -- Individual tone signals
    signal tone_out     : std_logic := '0';             -- Combined tone output

begin
    process(clk)
    begin
        if rising_edge(clk) then
            if stop = '1' then
                -- Reset outputs when stopped
                clk_counter <= (others => 0);    -- Clear all counters
                tone <= (others => '0');         -- Clear all tones
                tone_out <= '0';                 -- Clear the final output tone
                LED <= (others => '0');          -- Clear all LEDs
            else
                case mode_select is
                    -- Mode A: Switch-controlled tone generation
                    when "001" =>
                        case state is
                            -- Idle state: clear outputs if `stop` is asserted
                            when idle =>
                                if stop = '0' then
                                    state <= tonegen;  -- Start tone generation if not stopped
                                end if;
                            
                            -- Tone generation state
                            when tonegen =>
                                if stop = '1' then
                                    state <= idle;  -- Return to idle if stopped
                                else
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
                                    
                                    -- Combine tones to form chord (OR operation)
                                    tone_out <= tone(0) or tone(1) or tone(2) or tone(3) or
                                                tone(4) or tone(5) or tone(6) or tone(7);
                                end if;
                        end case;
                    
                        -- Map active switches to LEDs
                        LED <= switch;

                        -- Display is not actively used in this mode, set to a default
                        an <= "1111";  -- Disable all segments
                        cat <= "1111111";  -- Turn off display

                    -- Default case: clear outputs if invalid mode
                    when others =>
                        LED <= (others => '0');
                        tone_out <= '0';
                        an <= "1111";
                        cat <= "1111111";
                end case;
            end if;
        end if;
    end process;

    -- Constant outputs
    freq <= tone_out;  -- Send combined tone output to freq
    gain <= '1';       -- -6dB gain
    shutdown <= '1';   -- Keep amplifier active

end Behavioral;
