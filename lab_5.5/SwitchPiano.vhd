library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity SwitchPiano is
    Port (
        clk         : in STD_LOGIC;
        stop        : in STD_LOGIC;
        switch      : in STD_LOGIC_VECTOR(7 downto 0);  -- Switches for note selection in Mode A
        mode_select : in STD_LOGIC_VECTOR(2 downto 0);  -- Mode selection input
        uart_ready  : in STD_LOGIC;                     -- UART ready signal to trigger playback
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

    -- States for the state machine
    type state_type is (IDLE, CHORD_GEN, BRAM_PLAYBACK, UART_PLAYBACK);
    signal state : state_type := IDLE;
    signal clk_counter : freq_array := (others => 0);
    signal tone : std_logic_vector(7 downto 0) := (others => '0');
    signal tone_out : std_logic := '0';
    signal count : integer := 0;
    signal playback_timer : integer := 0;
    signal playing : std_logic := '0';
    signal uart_ready_latched : std_logic := '0';
    constant HALF_SECOND  : integer := 50000000;  
    signal current_frequency : integer:=0;
begin
    process(clk)
        variable note_index : integer;
    begin
        if rising_edge(clk) then
            if stop = '1' then
                -- Reset on stop
                LED <= (others => '0');
                an <= "1111";
                cat <= "1111111";
                tone_out <= '0';
                count <= 0;
                playback_timer <= 0;
                playing <= '0';
                uart_ready_latched <= '0';
                state <= IDLE;  -- Move to IDLE state

            else
                case state is
                    -- IDLE State: Wait for mode selection
                    when IDLE =>
                        if mode_select = "001" then
                            state <= CHORD_GEN;  -- Move to chord generation mode
                        elsif mode_select = "010" then
                            state <= BRAM_PLAYBACK;  -- Move to BRAM playback mode
                        elsif mode_select = "100" and uart_ready = '1' then
                            uart_ready_latched <= '1';
                            state <= UART_PLAYBACK;  -- Move to UART playback mode
                        end if;

                    -- Mode A: Chord Generation
                    when CHORD_GEN =>
                        for i in 0 to 7 loop
                            if switch(i) = '1' then
                                if clk_counter(i) = 0 then
                                    clk_counter(i) <= NOTE_FREQS(i);
                                    tone(i) <= not tone(i);  -- Toggle tone signal
                                else
                                    clk_counter(i) <= clk_counter(i) - 1;
                                end if;
                            else
                                tone(i) <= '0';  -- No tone if switch not active
                            end if;
                        end loop;

                        -- Combine tones to form a chord
                        tone_out <= tone(0) or tone(1) or tone(2) or tone(3) or 
                                    tone(4) or tone(5) or tone(6) or tone(7);
                        LED <= switch;  -- Map active switches to LEDs
                        an <= "1110";
                        cat <= DISPLAY_PATTERNS(to_integer(unsigned(switch)));

                        -- Return to IDLE if mode changes
                        if mode_select /= "001" then
                            state <= IDLE;
                        end if;

                    -- Mode B: BRAM Playback
                    when BRAM_PLAYBACK =>
                        an <= "1110";
                        note_index := -1;
                        for i in 0 to 7 loop
                            if switch(i) = '1' then
                                note_index := i;
                            end if;
                        end loop;

                        if note_index /= -1 then
                            LED <= (others => '0');
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

                        -- Return to IDLE if mode changes
                        if mode_select /= "010" then
                            state <= IDLE;
                        end if;

                    -- Mode C: UART-Controlled Playback (fixing the initial keystroke handling)
                    when UART_PLAYBACK =>
                        -- Detect a new keystroke and latch the ready signal
                        if uart_ready = '1' and uart_ready_latched = '0' then
                            uart_ready_latched <= '1';  -- Latch the ready signal
                    
                            -- Determine the note_index based on which switch is active
                            note_index := -1;  -- Default to -1 indicating no valid note
                            for i in 0 to 7 loop
                                if switch(i) = '1' then
                                    note_index := i;  -- Assign the index of the first active switch
                                    exit;  -- Exit the loop once the first active switch is found
                                end if;
                            end loop;
                    
                            -- Start playing the note if a valid note_index is found
                            if note_index >= 0 and note_index <= 7 then
                                playing <= '1';  -- Start playing the note
                    
                                -- Light up the corresponding LED and display pattern
                                LED <= (others => '0');
                                LED(note_index) <= '1';
                                cat <= DISPLAY_PATTERNS(note_index);
                                count <= 0;  -- Reset the count to start the frequency generation from the beginning
                            end if;
                        end if;
                    
                        -- Handle tone generation while playing
                        if playing = '1' then
                            if count = NOTE_FREQS(note_index) then
                                tone_out <= not tone_out;
                                count <= 0;
                            else
                                count <= count + 1;
                            end if;
                        end if;
                    
                        -- Reset uart_ready_latched once the keystroke is processed
                        if uart_ready = '0' then
                            uart_ready_latched <= '0';
                        end if;
                    
                        -- Return to IDLE if mode changes
                        if mode_select /= "100" then
                            playing <= '0';
                            tone_out <= '0';
                            LED <= (others => '0');
                            cat <= "1111111";
                            state <= IDLE;
                        end if;

                    

                    when others =>
                        -- Fallback case, reset everything
                        state <= IDLE;
                end case;
            end if;
        end if;
    end process;


    -- Output signals
    freq <= tone_out;     -- Use tone_out for final frequency output
    gain <= '1';          -- Keep amplifier gain active
    shutdown <= '1';      -- Keep amplifier active

end Behavioral;
