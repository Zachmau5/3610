library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

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

architecture Behavioral of top is
    -- Internal signals
    signal addr           : std_logic_vector(3 downto 0);
    signal note_select    : std_logic_vector(3 downto 0);
    signal mapped_note    : std_logic_vector(7 downto 0);
    signal uart_note      : std_logic_vector(7 downto 0);
    signal uart_ready     : std_logic;
    signal tx_busy        : std_logic;
    signal tx_load        : std_logic;
    signal current_note   : std_logic_vector(7 downto 0);
    signal uart_done      : std_logic;
    signal ena_s          : std_logic := '0';  -- Enable signal for BRAM

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
    -- Combined process to handle mode display, BRAM enable, and note mapping
    process(clk, rst, mode_select, switch, note_select)
    begin
        if rst = '1' then
            -- Reset logic
            an <= "1111";  -- Disable all segments on reset
            cat <= "1111111";
            ena_s <= '0';   -- Disable BRAM
            mapped_note <= (others => '0');  -- Clear mapped note

        elsif rising_edge(clk) then
            -- Mode-based display logic
            case mode_select is
                when "001" =>
                    -- Mode A display and mapped_note handling
                    an <= "0111";
                    cat <= MODE_A_DISPLAY;
                    ena_s <= '0';  -- Disable BRAM for Mode A
                    mapped_note <= switch;  -- Use switches directly in Mode A

                when "010" =>
                    -- Mode B display and BRAM enable
                    an <= "0111";
                    cat <= MODE_B_DISPLAY;
                    ena_s <= '1';  -- Enable BRAM in Mode B

                    -- Map note_select (from BRAM) to mapped_note in Mode B
                    case note_select is
                        when "0001" => mapped_note <= "00000001";  -- C note
                        when "0010" => mapped_note <= "00000010";  -- D note
                        when "0011" => mapped_note <= "00000100";  -- E note
                        when "0100" => mapped_note <= "00001000";  -- F note
                        when "0101" => mapped_note <= "00010000";  -- G note
                        when "0110" => mapped_note <= "00100000";  -- A note
                        when "0111" => mapped_note <= "01000000";  -- B note
                        when "1000" => mapped_note <= "10000000";  -- C' note
                        when others => mapped_note <= "00000000";  -- Default or unused value
                    end case;

                when "100" =>
                    -- Mode C display and BRAM disable
                    an <= "0111";
                    cat <= MODE_C_DISPLAY;
                    ena_s <= '0';  -- Disable BRAM for Mode C
                    mapped_note <= (others => '0');  -- Default or clear mapped_note

                when others =>
                    -- Default display and BRAM disable
                    an <= "1111";
                    cat <= "1111111";
                    ena_s <= '0';
                    mapped_note <= (others => '0');
            end case;
        end if;
    end process;
    -- Instantiate SwitchPiano, passing mapped_note for tone generation
    U1: SwitchPiano
    port map (
        clk          => clk,
        stop         => rst,
        switch       => mapped_note,
        mode_select  => mode_select,
        freq         => freq,
        LED          => led,
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

    -- UART instances (unchanged)
    U4: UART_RX
    port map (
        clk      => clk, 
        reset    => rst,
        sdata    => sdata_in,
        pdata    => uart_note,
        ready    => uart_ready
    );

    U5: UART_TX
    port map (
        clk      => clk,
        reset    => rst,
        pdata    => current_note,
        load     => uart_ready,
        busy     => tx_busy,
        done     => uart_done,
        sdata    => sdata_out
    );
end Behavioral;
