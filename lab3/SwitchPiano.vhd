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

    -- Signals for each note's frequency divider and tone generation
    signal clk_divider_C, clk_divider_D, clk_divider_E, clk_divider_F : integer := 0;
    signal clk_divider_G, clk_divider_A, clk_divider_B, clk_divider_HighC : integer := 0;

    signal clk_counter_C, clk_counter_D, clk_counter_E, clk_counter_F : integer := 0;
    signal clk_counter_G, clk_counter_A, clk_counter_B, clk_counter_HighC : integer := 0;

    signal tone_C, tone_D, tone_E, tone_F : std_logic := '0';
    signal tone_G, tone_A, tone_B, tone_HighC : std_logic := '0';
    signal tone_out : std_logic := '0';  -- Output tone, result of combined frequencies

    -- Frequency constants for each tone (based on system clock of 100 MHz)
    constant C_FREQ      : integer := 38223;  -- 100MHz / (2 * 261.63 Hz)
    constant D_FREQ      : integer := 34129;  -- 100MHz / (2 * 293.66 Hz)
    constant E_FREQ      : integer := 30303;  -- 100MHz / (2 * 329.63 Hz)
    constant F_FREQ      : integer := 28635;  -- 100MHz / (2 * 349.23 Hz)
    constant G_FREQ      : integer := 25510;  -- 100MHz / (2 * 392 Hz)
    constant A_FREQ      : integer := 22727;  -- 100MHz / (2 * 440 Hz)
    constant B_FREQ      : integer := 20248;  -- 100MHz / (2 * 493.88 Hz)
    constant HIGH_C_FREQ : integer := 19111;  -- 100MHz / (2 * 523.25 Hz)

begin
    process(Clk)
    begin
        if rising_edge(Clk) then

            -- Handle chord generation based on switch input for all notes
            -- Assign each switch to a frequency divider for the corresponding note
            if switch(0) = '1' then
                clk_divider_C <= C_FREQ;
            else
                clk_divider_C <= 0;
            end if;

            if switch(1) = '1' then
                clk_divider_D <= D_FREQ;
            else
                clk_divider_D <= 0;
            end if;

            if switch(2) = '1' then
                clk_divider_E <= E_FREQ;
            else
                clk_divider_E <= 0;
            end if;

            if switch(3) = '1' then
                clk_divider_F <= F_FREQ;
            else
                clk_divider_F <= 0;
            end if;

            if switch(4) = '1' then
                clk_divider_G <= G_FREQ;
            else
                clk_divider_G <= 0;
            end if;

            if switch(5) = '1' then
                clk_divider_A <= A_FREQ;
            else
                clk_divider_A <= 0;
            end if;

            if switch(6) = '1' then
                clk_divider_B <= B_FREQ;
            else
                clk_divider_B <= 0;
            end if;

            if switch(7) = '1' then
                clk_divider_HighC <= HIGH_C_FREQ;
            else
                clk_divider_HighC <= 0;
            end if;

            -- Tone generation for each note
            -- Tone generation for C
            if clk_divider_C > 0 then
                if clk_counter_C = 0 then
                    clk_counter_C <= clk_divider_C;
                    tone_C <= not tone_C;  -- Toggle the tone signal
                else
                    clk_counter_C <= clk_counter_C - 1;
                end if;
            else
                tone_C <= '0';  -- No tone if not selected
            end if;

            -- Tone generation for D
            if clk_divider_D > 0 then
                if clk_counter_D = 0 then
                    clk_counter_D <= clk_divider_D;
                    tone_D <= not tone_D;  -- Toggle the tone signal
                else
                    clk_counter_D <= clk_counter_D - 1;
                end if;
            else
                tone_D <= '0';  -- No tone if not selected
            end if;

            -- Tone generation for E
            if clk_divider_E > 0 then
                if clk_counter_E = 0 then
                    clk_counter_E <= clk_divider_E;
                    tone_E <= not tone_E;  -- Toggle the tone signal
                else
                    clk_counter_E <= clk_counter_E - 1;
                end if;
            else
                tone_E <= '0';  -- No tone if not selected
            end if;

            -- Tone generation for F
            if clk_divider_F > 0 then
                if clk_counter_F = 0 then
                    clk_counter_F <= clk_divider_F;
                    tone_F <= not tone_F;  -- Toggle the tone signal
                else
                    clk_counter_F <= clk_counter_F - 1;
                end if;
            else
                tone_F <= '0';  -- No tone if not selected
            end if;

            -- Tone generation for G
            if clk_divider_G > 0 then
                if clk_counter_G = 0 then
                    clk_counter_G <= clk_divider_G;
                    tone_G <= not tone_G;  -- Toggle the tone signal
                else
                    clk_counter_G <= clk_counter_G - 1;
                end if;
            else
                tone_G <= '0';  -- No tone if not selected
            end if;

            -- Tone generation for A
            if clk_divider_A > 0 then
                if clk_counter_A = 0 then
                    clk_counter_A <= clk_divider_A;
                    tone_A <= not tone_A;  -- Toggle the tone signal
                else
                    clk_counter_A <= clk_counter_A - 1;
                end if;
            else
                tone_A <= '0';  -- No tone if not selected
            end if;

            -- Tone generation for B
            if clk_divider_B > 0 then
                if clk_counter_B = 0 then
                    clk_counter_B <= clk_divider_B;
                    tone_B <= not tone_B;  -- Toggle the tone signal
                else
                    clk_counter_B <= clk_counter_B - 1;
                end if;
            else
                tone_B <= '0';  -- No tone if not selected
            end if;

            -- Tone generation for High C
            if clk_divider_HighC > 0 then
                if clk_counter_HighC = 0 then
                    clk_counter_HighC <= clk_divider_HighC;
                    tone_HighC <= not tone_HighC;  -- Toggle the tone signal
                else
                    clk_counter_HighC <= clk_counter_HighC - 1;
                end if;
            else
                tone_HighC <= '0';  -- No tone if not selected
            end if;

            -- Combine tones to form chord (OR operation can be used)
            tone_out <= tone_C or tone_D or tone_E or tone_F or tone_G or tone_A or tone_B or tone_HighC;
        end if;
    end process;

    -- Send the combined tone (chord) to freq output
    freq <= tone_out;

    -- Map the switches to the LEDs to show active switches
    LED <= switch;

    -- Set gain and shutdown for Pmod AMP2
    gain <= '1';  -- Max gain
    shutdown <= '1';  -- Keep amplifier active

end Behavioral;
