--library IEEE;
--use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.NUMERIC_STD.ALL;

--entity top is
--    Port (
--        clk     : in std_logic;  -- 100 MHz clock input
--        reset   : in std_logic;  -- Reset input (active high)
--        sdata   : in std_logic;  -- Serial data input (from UART RX)
--        led_out : out std_logic_vector(7 downto 0);  -- Output LEDs (to show received byte)
--        tx_out  : out std_logic   -- Serial data output (to UART TX)
--    );
--end top;

--architecture Behavioral of top is

--    -- Component declaration for UART_RX
--    component UART_RX is
--        Port (
--            clk   : in std_logic;  -- clock input
--            reset : in std_logic;  -- reset, active high
--            sdata : in std_logic;  -- serial data input
--            pdata : out std_logic_vector(7 downto 0);  -- parallel data output
--            ready : out std_logic  -- ready strobe, active high
--        );
--    end component;

--    -- Component declaration for UART_TX (Transmitter)
--    component UART_TX is
--        Port (
--            clk    : in std_logic;  -- clock input
--            reset  : in std_logic;  -- reset, active high
--            pdata  : in std_logic_vector(7 downto 0);  -- parallel data input
--            load   : in std_logic;  -- load signal, active high
--            busy   : out std_logic;  -- busy indicator
--            sdata  : out std_logic  -- serial data output
--        );
--    end component;

--    -- Signals
--    signal byte_ready      : std_logic;                -- Signal for ready status from UART_RX
--    signal pdata_s         : std_logic_vector(7 downto 0);  -- Internal signal to hold pdata from UART_RX
--    signal tx_busy         : std_logic;                -- Signal to indicate if the transmitter is busy
--    signal tx_load         : std_logic := '0';         -- Load signal for the transmitter
--    signal prev_byte_ready : std_logic := '0';         -- Previous state of byte_ready for edge detection

--begin

--    -- Instantiate the UART_RX component
--    U1: UART_RX
--        port map (
--            clk    => clk,        -- Connect to top-level clock
--            reset  => reset,      -- Connect top-level reset
--            sdata  => sdata,      -- Connect the serial data input
--            pdata  => pdata_s,    -- Connect the parallel data output to internal signal
--            ready  => byte_ready  -- Connect the ready signal
--        );

--    -- Instantiate the UART_TX component (Transmitter)
--    U2: UART_TX
--        port map (
--            clk    => clk,       -- Connect to top-level clock
--            reset  => reset,     -- Connect top-level reset
--            pdata  => pdata_s,   -- Load the data received from UART_RX into UART_TX
--            load   => tx_load,   -- Load signal to initiate transmission
--            busy   => tx_busy,   -- Busy signal indicating if the transmitter is transmitting
--            sdata  => tx_out     -- Transmit the data out to serial line
--        );

--    -- Only show data on LEDs when ready is high
--    led_out <= pdata_s when byte_ready = '1' else (others => '0');  -- Clear LEDs when data is not ready

--    -- Process to generate tx_load signal using edge detection on byte_ready
--    tx_load_process : process(clk)
--    begin
--        if rising_edge(clk) then
--            if reset = '1' then
--                prev_byte_ready <= '0';
--                tx_load         <= '0';
--            else
--                prev_byte_ready <= byte_ready;
--                if (prev_byte_ready = '0') and (byte_ready = '1') and (tx_busy = '0') then
--                    tx_load <= '1';  -- Assert tx_load for one clock cycle on rising edge of byte_ready
--                else
--                    tx_load <= '0';  -- Deassert tx_load
--                end if;
--            end if;
--        end if;
--    end process;

--end Behavioral;
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top is
    Port (
        clk     : in std_logic;  -- 100 MHz clock input
        reset   : in std_logic;  -- Reset input (active high)
        sdata   : in std_logic;  -- Serial data input (from UART RX)
        led_out : out std_logic_vector(7 downto 0);  -- Output LEDs (to show received byte)
        tx_out  : out std_logic   -- Serial data output (to UART TX)
    );
end top;

architecture Behavioral of top is

    -- Component declaration for UART_RX
    component UART_RX is
        Port (
            clk   : in std_logic;  -- clock input
            reset : in std_logic;  -- reset, active high
            sdata : in std_logic;  -- serial data input
            pdata : out std_logic_vector(7 downto 0);  -- parallel data output
            ready : out std_logic  -- ready strobe, active high
        );
    end component;

    -- Component declaration for UART_TX (Transmitter)
    component UART_TX is
        Port (
            clk    : in std_logic;  -- clock input
            reset  : in std_logic;  -- reset, active high
            pdata  : in std_logic_vector(7 downto 0);  -- parallel data input
            load   : in std_logic;  -- load signal, active high
            busy   : out std_logic;  -- busy indicator
            sdata  : out std_logic  -- serial data output
        );
    end component;

    -- Signals
    signal byte_ready : std_logic;                -- Signal for ready status from UART_RX
    signal pdata_s    : std_logic_vector(7 downto 0);  -- Internal signal to hold pdata from UART_RX
    signal tx_busy    : std_logic;                -- Signal to indicate if the transmitter is busy
    signal tx_load    : std_logic;                -- Signal to indicate if the transmitter is busy
begin

    -- Instantiate the UART_RX component
    U1: UART_RX
        port map (
            clk    => clk,        -- Connect to top-level clock
            reset  => reset,      -- Connect top-level reset
            sdata  => sdata,      -- Connect the serial data input
            pdata  => pdata_s,    -- Connect the parallel data output to internal signal
            ready  => byte_ready  -- Connect the ready signal
        );

    -- Instantiate the UART_TX component (Transmitter)
    U2: UART_TX
        port map (
            clk    => clk,       -- Connect to top-level clock
            reset  => reset,     -- Connect top-level reset
            pdata  => pdata_s,   -- Load the data received from UART_RX into UART_TX
            load   => byte_ready, -- Directly use byte_ready as the load signal
            busy   => tx_busy,   -- Busy signal indicating if the transmitter is transmitting
            sdata  => tx_out     -- Transmit the data out to serial line
        );

    -- Only show data on LEDs when ready is high
    led_out <= pdata_s when byte_ready = '1' else (others => '0');  -- Clear LEDs when data is not ready

end Behavioral;
