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

    -- Display patterns for each note on the seven-segment display
    type display_array is array(0 to 7) of STD_LOGIC_VECTOR(6 downto 0);
    constant DISPLAY_PATTERNS : display_array := (
        "1001111",  -- C4
        "0010010",  -- D4
        "0000110",  -- E4
        "1001100",  -- F4
        "0100100",  -- G4
        "0100000",  -- A4
        "0001111",  -- B4
        "0000000"   -- C5
    );

    -- State for Mode A
    type state_type is (idle, tonegen);
    signal state        : state_type := idle;
    signal clk_counter  : freq_array := (others => 0);  -- Counters for each tone frequency
    signal tone         : std_logic_vector(7 downto 0) := (others => '0'); -- Individual tone signals
    signal tone_out     : std_logic := '0';             -- Combined tone output
    signal note_select : std_logic_vector(3 downto 0);  -- To hold the note data from BRAM

    signal count        : integer := 0;
    signal freq_reg     : std_logic := '0';

begin
    process(clk)
        variable note_index:integer;
    begin
        if rising_edge(clk) then
            if stop = '1' then
                -- Reset outputs when stopped
                clk_counter <= (others => 0);
                tone <= (others => '0');
                tone_out <= '0';
                LED <= (others => '0');
                an <= "1111";
                cat <= "1111111";

            else
                case mode_select is
                    -- Mode A: Switch-controlled tone generation (Chords)
                    when "001" =>
                        case state is
                            when idle =>
                                if stop = '0' then
                                    state <= tonegen;  -- Start tone generation if not stopped
                                end if;
                            when tonegen =>
                                if stop = '1' then
                                    state <= idle;
                                else
                                    for i in 0 to 7 loop
                                        if switch(i) = '1' then
                                            if clk_counter(i) = 0 then
                                                clk_counter(i) <= NOTE_FREQS(i);  -- Load frequency
                                                tone(i) <= not tone(i);           -- Toggle tone signal
                                            else
                                                clk_counter(i) <= clk_counter(i) - 1;
                                            end if;
                                        else
                                            tone(i) <= '0';  -- No tone if switch not active
                                        end if;
                                    end loop;

                                    -- Combine tones to form a chord (OR operation)
                                    tone_out <= tone(0) or tone(1) or tone(2) or tone(3) or 
                                                tone(4) or tone(5) or tone(6) or tone(7);
                                    LED <= switch;  -- Map active switches to LEDs
                                    an <= "1110";
                                    cat <= DISPLAY_PATTERNS(to_integer(unsigned(switch)));
                                end if;
                        end case;

                    -- Mode B: BRAM-based note playback

                    -- Mode B: BRAM-based note playback
                    when "010" =>
                        an <= "1110";
                        note_index := -1;
                        for i in 0 to 7 loop
                            if switch(i) = '1' then
                                note_index := i;
                            end if;
                        end loop;

                        if note_index /= -1 then
                            LED <= (7 downto 0 => '0');
                            LED(note_index) <= '1';
                            cat <= DISPLAY_PATTERNS(note_index);
                            if count = NOTE_FREQS(note_index) then
                                tone_out <= not tone_out;
                                count <= 0;
                            else
                                count <= count + 1;
                            end if;
                        else
                            LED <= (others => '0');
                            cat <= "1111111";
                            tone_out <= '0';
                        end if;

                    -- Default case: clear outputs
                    when others =>
                        LED <= (others => '0');
                        tone_out <= '0';
                        an <= "1111";
                        cat <= "1111111";
                end case;
            end if;
        end if;
    end process;
    -- Output signals
    freq <= tone_out;  -- Frequency output for chords in Mode A
    gain <= '1';
    shutdown <= '1';

end Behavioral;
