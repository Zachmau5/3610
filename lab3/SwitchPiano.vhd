library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity SwitchPiano is
    Port ( 
        Clk      : in STD_LOGIC;
        switch   : in STD_LOGIC_VECTOR (7 downto 0);  -- Switches for tone selection
        LED      : out STD_LOGIC_VECTOR (7 downto 0);  -- LEDs to show active switches
        freq     : out STD_LOGIC;  -- Frequency output to audio amplifier
        gain     : out STD_LOGIC;  -- Gain control for Pmod AMP2
        shutdown : out STD_LOGIC  -- Shutdown control for Pmod AMP2
    );
end SwitchPiano;

architecture Behavioral of SwitchPiano is

    signal clk_divider : integer := 0;
    signal clk_counter : integer := 0;
    signal tone : std_logic := '0';
    signal song_index : integer := 0;
    signal song_counter : integer := 0;
    signal song_playing : std_logic := '0';

    -- Frequency constants for each tone (based on system clock of 100 MHz)
    constant C_FREQ : integer := 38223;  -- 100MHz / (2 * 261.63 Hz)
    constant D_FREQ : integer := 34129;  -- 100MHz / (2 * 293.66 Hz)
    constant E_FREQ : integer := 30303;  -- 100MHz / (2 * 329.63 Hz)
    constant F_FREQ : integer := 28635;  -- 100MHz / (2 * 349.23 Hz)
    constant G_FREQ : integer := 25510;  -- 100MHz / (2 * 392 Hz)
    constant A_FREQ : integer := 22727;  -- 100MHz / (2 * 440 Hz)
    constant B_FREQ : integer := 20248;  -- 100MHz / (2 * 493.88 Hz)
    constant HIGH_C_FREQ : integer := 19111;  -- 100MHz / (2 * 523.25 Hz)

    -- Song definition: A sequence of notes (frequencies) and their durations
    type song_t is array (0 to 7) of integer;
    constant song_notes : song_t := (C_FREQ, D_FREQ, E_FREQ, F_FREQ, G_FREQ, A_FREQ, B_FREQ, HIGH_C_FREQ);
    constant song_durations : song_t := (10000000, 10000000, 10000000, 10000000, 10000000, 10000000, 10000000, 10000000);  -- Duration of each note

begin
    process(Clk)
    begin
        if rising_edge(Clk) then
            -- Detect if switch combination "00000011" is pressed
            if switch = "00000011" then
                -- If song is not already playing, reset song index and counter
                if song_playing = '0' then
                    song_index <= 0;  -- Reset song to the beginning
                    song_counter <= 0;
                    song_playing <= '1';  -- Set flag to indicate song is playing
                end if;
                
                -- Play the song by stepping through the notes
                if song_counter = 0 then
                    -- Move to the next note in the song
                    clk_divider <= song_notes(song_index);
                    song_counter <= song_durations(song_index);
                    song_index <= (song_index + 1) mod 8;  -- Loop back to the beginning of the song
                else
                    song_counter <= song_counter - 1;
                end if;
            else
                -- If no song is playing, play individual tones based on switch input
                song_playing <= '0';  -- Reset the song flag when switches are released

                -- Select the appropriate frequency based on the active switch
                case switch is
                    when "00000001" => clk_divider <= C_FREQ;
                    when "00000010" => clk_divider <= D_FREQ;
                    when "00000100" => clk_divider <= E_FREQ;
                    when "00001000" => clk_divider <= F_FREQ;
                    when "00010000" => clk_divider <= G_FREQ;
                    when "00100000" => clk_divider <= A_FREQ;
                    when "01000000" => clk_divider <= B_FREQ;
                    when "10000000" => clk_divider <= HIGH_C_FREQ;
                    when others      => clk_divider <= 0;
                end case;
            end if;

            -- Generate the tone if a switch is active or a song is playing
            if clk_divider > 0 then
                if clk_counter = 0 then
                    clk_counter <= clk_divider;
                    tone <= not tone;  -- Toggle the tone signal
                else
                    clk_counter <= clk_counter - 1;
                end if;
            else
                tone <= '0';  -- No tone if no switch is pressed
            end if;
        end if;
    end process;

    -- Send the tone to freq output
    freq <= tone;

    -- Map the switches to the LEDs
    LED <= switch;

    -- Set gain and shutdown for Pmod AMP2
    gain <= '1';  -- Max gain
    shutdown <= '1';  -- Keep amplifier active

end Behavioral;
