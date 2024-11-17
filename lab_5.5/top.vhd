library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--  Entity and Ports:
--   - Defines the interface of the `top` entity.
--   - Inputs:
--     - `clk`: Main system clock.
--     - `rst`: Reset signal.
--     - `switch`: 8-bit input to select notes.
--     - `mode_select`: 3-bit input for selecting operational mode (A, B, or C).
--     - `sdata_in`: Serial data input for UART reception.
--   - Outputs:
--     - `freq`, `gain`, `shutdown`: Control signals for audio output.
--     - `led`: 8-bit output for LED indicators.
--     - `an`: 4-bit output for 7-segment display anode selection.
--     - `cat`: 7-bit output for 7-segment display cathode pattern.
--     - `sdata_out`: Serial data output for UART transmission.

entity top is
    Port ( 
        clk         : in STD_LOGIC;
        rst         : in STD_LOGIC;
        switch      : in STD_LOGIC_VECTOR (7 downto 0);
        mode_select : in STD_LOGIC_VECTOR (2 downto 0);
        sdata_in    : in STD_LOGIC;
        freq        : out STD_LOGIC;
        gain        : out STD_LOGIC;
        shutdown    : out STD_LOGIC;
        led         : out STD_LOGIC_VECTOR (7 downto 0);
        an          : out STD_LOGIC_VECTOR(3 downto 0);
        cat         : out STD_LOGIC_VECTOR(6 downto 0);
        sdata_out   : out STD_LOGIC
    );
end top;
--  Internal Signals and Constants:
--   - Signals and constants declared for internal operations.
--   - Signals:
--     - `addr`: Address for BRAM readout.
--     - `note_select`: Note selection value from BRAM.
--     - `mapped_note`: 8-bit representation of the note.
--     - `uart_note`: 8-bit data received from UART.
--     - `uart_ready`: UART ready flag indicating received data availability.
--     - `tx_busy`: UART transmission status.
--     - `ena_s`: Enable signal for BRAM.
--     - `uart_done`: Completion flag for UART transmission.
--     - `mapped_switch`: 8-bit representation of active switch.
--     - `uart_ready_latched`: Latched version of `uart_ready`.
--     - `led_internal`, `cat_internal`, `an_internal`: Internal signals for LED and display management.
--   - Constants:
--     - Constants for different modes of the 7-segment display (`MODE_A_DISPLAY`, `MODE_B_DISPLAY`, `MODE_C_DISPLAY`).
architecture Behavioral of top is
    -- Internal signals
    signal addr           : std_logic_vector(3 downto 0);
    signal note_select    : std_logic_vector(3 downto 0);
    signal mapped_note    : std_logic_vector(7 downto 0);
    signal uart_note      : std_logic_vector(7 downto 0);
    signal uart_ready     : std_logic;
    signal tx_busy        : std_logic;
    signal ena_s          : std_logic := '0';    -- Enable signal for BRAM
    signal uart_done      : std_logic;  -- Added uart_done signal for UART transmission completion
    signal mapped_switch  : std_logic_vector(7 downto 0);  -- Internal signal for switch mapping
    signal uart_ready_latched : std_logic := '0';
    signal led_internal   : std_logic_vector(7 downto 0);  -- Signal for driving `led` output
    signal cat_internal   : std_logic_vector(6 downto 0);  -- Signal for driving `cat` output
    signal an_internal    : std_logic_vector(3 downto 0);  -- Signal for driving `an` output

    -- Mode display patterns
    constant MODE_A_DISPLAY : std_logic_vector(6 downto 0) := "0001000";
    constant MODE_B_DISPLAY : std_logic_vector(6 downto 0) := "0000000";
    constant MODE_C_DISPLAY : std_logic_vector(6 downto 0) := "0110001";

    -- Component declarations
    component UART_RX is
        Port (
            clk   : in std_logic;
            reset : in std_logic;
            sdata : in std_logic;
            pdata : out std_logic_vector(7 downto 0);
            ready : out std_logic
        );
    end component;

    component UART_TX is
        Port (
            clk    : in std_logic;
            reset  : in std_logic;
            pdata  : in std_logic_vector(7 downto 0);
            load   : in std_logic;
            busy   : out std_logic;
            sdata  : out std_logic;
            done   : out std_logic
        );
    end component;

    component SwitchPiano is
        Port (
            clk         : in STD_LOGIC;
            stop        : in STD_LOGIC;
            switch      : in STD_LOGIC_VECTOR(7 downto 0);
            mode_select : in STD_LOGIC_VECTOR(2 downto 0);
            uart_ready  : in STD_LOGIC;    -- UART ready signal for controlled playback
            freq        : out STD_LOGIC;
            gain        : out STD_LOGIC;
            shutdown    : out STD_LOGIC;
            LED         : out STD_LOGIC_VECTOR(7 downto 0);
            an          : out STD_LOGIC_VECTOR(3 downto 0);
            cat         : out STD_LOGIC_VECTOR(6 downto 0)
        );
    end component;

    component blk_mem_gen_0 is
        Port (
            clka   : IN STD_LOGIC;
            ena    : IN STD_LOGIC;
            wea    : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
            addra  : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
            dina   : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
            douta  : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
        );
    end component;

    component clk_counter is
        Port (
            clk     : in STD_LOGIC;
            reset   : in STD_LOGIC;
            count   : out STD_LOGIC_VECTOR(3 downto 0)
        );
    end component;

begin
    -- Process for latching uart_ready
    -- Handles latching of the `uart_ready` signal for stability.
    -- Clears the latched value (`uart_ready_latched`) after UART transmission (`uart_done`) or note playback completes.
    process(clk, rst)
    begin
        if rst = '1' then
            uart_ready_latched <= '0';
        elsif rising_edge(clk) then
            if uart_ready = '1' then
                uart_ready_latched <= '1';  -- Latch the ready signal
            elsif mode_select = "100" and uart_done = '1' then
                uart_ready_latched <= '0';  -- Clear the latch after UART transmission is done or note playback is completed
            end if;
        end if;
    end process;

    -- Combined process to handle mode display, BRAM enable, note mapping, and Mode C playback
    process(clk, rst, mode_select, switch, note_select, uart_ready, uart_note)
    begin
        if rst = '1' then
            -- Reset logic
            an_internal <= "1111";
            cat_internal <= "1111111";
            ena_s <= '0';
            mapped_note <= (others => '0');
            mapped_switch <= (others => '0');  -- Clear mapped_switch
            led_internal <= (others => '0');  -- Clear LEDs

        elsif rising_edge(clk) then
            -- Mode-based display logic
            case mode_select is
                when "001" =>  -- Mode A
                    an_internal <= "0111";  -- Display mode by default
                    cat_internal <= MODE_A_DISPLAY;
                    ena_s <= '0';  -- Disable BRAM for Mode A
                    mapped_switch <= switch;  -- Use switches directly in Mode A
                    led_internal <= switch;  -- Use switches to drive LEDs

                when "010" =>  -- Mode B
                    an_internal <= "0111";  -- Display mode by default
                    cat_internal <= MODE_B_DISPLAY;
                    ena_s <= '1';  -- Enable BRAM in Mode B
                    case note_select is
                        when "0001" => mapped_note <= "00000001";  -- C note
                        when "0010" => mapped_note <= "00000010";  -- D note
                        when "0011" => mapped_note <= "00000100";  -- E note
                        when "0100" => mapped_note <= "00001000";  -- F note
                        when "0101" => mapped_note <= "00010000";  -- G note
                        when "0110" => mapped_note <= "00100000";  -- A note
                        when "0111" => mapped_note <= "01000000";  -- B note
                        when "1000" => mapped_note <= "10000000";  -- C' note
                        when others => mapped_note <= "00000000";  -- Default
                    end case;
                    mapped_switch <= mapped_note;  -- Pass BRAM output to mapped_switch
                    led_internal <= mapped_note;  -- Drive LEDs based on note

                when "100" =>  -- Mode C (UART-Controlled Playback)
                    ena_s <= '0';  -- Disable BRAM
                    an_internal <= "0111";  -- Display mode by default
                    cat_internal <= MODE_C_DISPLAY;

                    -- Update `mapped_switch` only when `uart_ready_latched` is high
                    if uart_ready_latched = '1' then
                        case uart_note is
                            when "00110001" => mapped_switch <= "00000001"; -- ASCII '1' for C note
                            when "00110010" => mapped_switch <= "00000010"; -- ASCII '2' for D note
                            when "00110011" => mapped_switch <= "00000100"; -- ASCII '3' for E note
                            when "00110100" => mapped_switch <= "00001000"; -- ASCII '4' for F note
                            when "00110101" => mapped_switch <= "00010000"; -- ASCII '5' for G note
                            when "00110110" => mapped_switch <= "00100000"; -- ASCII '6' for A note
                            when "00110111" => mapped_switch <= "01000000"; -- ASCII '7' for B note
                            when "00111000" => mapped_switch <= "10000000"; -- ASCII '8' for C' note
                            when others     => mapped_switch <= (others => '0'); -- Ignore invalid keys
                        end case;
                    end if;

                    -- Assign `mapped_switch` to `led_internal` so that only the appropriate LED lights up
                    led_internal <= mapped_switch;

                when others =>
                    mapped_switch <= (others => '0');
                    ena_s <= '0';
                    an_internal <= "1111";
                    cat_internal <= "1111111";
                    led_internal <= (others => '0');  -- Clear LEDs
            end case;

            -- Update `cat_internal` to display the note being played
            if mapped_switch /= "00000000" then
                an_internal <= "1110";  -- Display the note when a note is active
                case mapped_switch is
                    when "00000001" => cat_internal <= "1001111";  -- C note
                    when "00000010" => cat_internal <= "0010010";  -- D note
                    when "00000100" => cat_internal <= "0000110";  -- E note
                    when "00001000" => cat_internal <= "1001100";  -- F note
                    when "00010000" => cat_internal <= "0100100";  -- G note
                    when "00100000" => cat_internal <= "0100000";  -- A note
                    when "01000000" => cat_internal <= "0001111";  -- B note
                    when "10000000" => cat_internal <= "0000000";  -- C' note
                    when others     => cat_internal <= "1111111";  -- Default
                end case;
            end if;
        end if;
    end process;

    -- Assign the led, an, and cat outputs based on internal logic
    led <= led_internal;
    cat <= cat_internal;
    an <= an_internal;

    -- Instantiate SwitchPiano, passing `mapped_switch` for tone generation
    U1: SwitchPiano
    port map (
        clk          => clk,
        stop         => rst,
        switch       => mapped_switch,  -- Pass mapped_switch to SwitchPiano
        mode_select  => mode_select,
        uart_ready   => uart_ready,     -- Connect uart_ready to SwitchPiano to trigger playback
        freq         => freq,
        LED          => open,           -- Do not connect SwitchPiano LED to avoid multiple drivers
        gain         => gain,
        shutdown     => shutdown,
        an           => open,
        cat          => open
    );

    -- Instantiate BRAM, enabling it only when ena_s is high (Mode B)
    U2: blk_mem_gen_0
    port map (
        clka     => clk, 
        ena      => ena_s,               -- Controlled by ena_s
        wea      => "0",
        addra    => addr,
        dina     => "0000",
        douta    => note_select
    );

    -- Instantiate clk_counter for Mode B address generation
    U3: clk_counter
    port map (
        clk      => clk,
        reset    => rst,
        count    => addr
    );

    -- UART_RX for receiving notes from Putty in Mode C
    U4: UART_RX
    port map (
        clk      => clk, 
        reset    => rst,
        sdata    => sdata_in,
        pdata    => uart_note,
        ready    => uart_ready
    );

    -- UART_TX for echoing notes back to Putty in Mode C
    U5: UART_TX
    port map (
        clk      => clk,
        reset    => rst,
        pdata    => uart_note,
        load     => uart_ready,
        busy     => tx_busy,
        done     => uart_done,
        sdata    => sdata_out
    );

end Behavioral;
