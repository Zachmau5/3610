library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity UART_TX is
    Port (
        clk    : in std_logic;  -- Clock input
        reset  : in std_logic;  -- Reset, active high
        pdata  : in std_logic_vector(7 downto 0);  -- Parallel data input (8 bits)
        load   : in std_logic;  -- Load signal, active high (initiates data transmission)
        busy   : out std_logic;  -- Busy indicator, active high (transmitter is busy when high)
        sdata  : out std_logic   -- Serial data output (UART transmit line)
    );
end UART_TX;

architecture Behavioral of UART_TX is

    -- State machine enumeration
    -- The transmitter operates through these states:
    --   - idle:      Transmitter is idle, waiting for data to send.
    --   - load_data: Transmitter loads data into internal register for transmission.
    --   - transmit:  Transmitter sends data bits serially.
    type state_type is (idle, load_data, transmit);
    signal state_tx : state_type := idle;  -- Initialize to idle state

    -- Internal signals
    signal tx_frame   : std_logic_vector(9 downto 0);  -- Frame to transmit: start bit, data bits, stop bit
    signal count_down : integer range 0 to 10416;      -- Countdown timer for baud rate timing
    signal bit_index  : integer range 0 to 10 := 0;    -- Index of the current bit being transmitted (0-10)
    signal prev_load  : std_logic := '0';              -- Previous state of 'load' signal for edge detection

    -- Constants
    -- 'full_count' represents the number of clock cycles for one bit period at the desired baud rate.
    -- Calculated as: (Clock Frequency / Baud Rate) - 1
    -- For a 100 MHz clock and a baud rate of 9600:
    --   full_count = (100,000,000 / 9,600) - 1 = 10416
    constant full_count : integer := 10416;  -- Number of clock cycles per bit period

begin

    -- UART transmitter process
    -- This process implements the state machine for UART transmission.
    -- It handles edge detection on the 'load' signal, data loading, and bit transmission.
    process(clk, reset)
    begin
        if reset = '1' then
            -- Reset condition: initialize all signals to default values
            state_tx    <= idle;             -- Set state to idle
            sdata       <= '1';              -- UART line is idle high
            busy        <= '0';              -- Transmitter is not busy
            count_down  <= full_count;       -- Initialize countdown timer
            bit_index   <= 0;                -- Reset bit index
            tx_frame    <= (others => '1');  -- Clear transmit frame (set all bits to '1')
            prev_load   <= '0';              -- Clear previous load signal

        elsif rising_edge(clk) then
            -- Edge detection for 'load' signal
            -- Purpose: Detect the rising edge of 'load' to initiate data transmission only once per 'load' assertion.
            -- 'prev_load' holds the value of 'load' from the previous clock cycle.
            -- By comparing 'load' and 'prev_load', we can detect when 'load' transitions from '0' to '1'.
            if load = '1' and prev_load = '0' then
                -- Rising edge of 'load' detected (transition from '0' to '1')
                if state_tx = idle then
                    state_tx <= load_data;    -- Move to 'load_data' state to begin transmission
                end if;
            end if;
                prev_load <= load;-- IMPORTANT P, THIS ELIMINATES CONTINOUS TX
            --	Every clock cycle, the current value of load is stored in prev_load.
            -- This allows the system to compare the current value of load with its value from the previous clock cycle
            -- This comparison checks whether load has transitioned from 0 (low) in the previous clock cycle to 1 (high) in the current clock cycle. 
            -- If so, this indicates a rising edge, and the system transitions to the load_data state to start transmission.
	        -- If the load signal is high but did not transition from low (i.e., if prev_load is also 1), the system does not initiate another transmission    
        
            -- State machine handling
            case state_tx is

                when idle =>
                    -- Idle state: transmitter is waiting for data
                    busy  <= '0';             -- Not busy in idle state
                    sdata <= '1';             -- UART line remains idle high

                when load_data =>
                    -- Load data into 'tx_frame' for transmission
                    tx_frame(0)          <= '0';       -- Start bit (logic low)
                    tx_frame(8 downto 1) <= pdata;     -- Data bits (LSB first)
                    tx_frame(9)          <= '1';       -- Stop bit (logic high)
                    bit_index            <= 0;         -- Initialize bit index
                    count_down           <= full_count;-- Reset countdown timer
                    busy                 <= '1';       -- Transmitter is now busy
                    state_tx             <= transmit;  -- Move to 'transmit' state

                when transmit =>
                    -- Transmit state: sending bits serially
                    busy <= '1';                         -- Transmitter remains busy
                    if count_down = 0 then               -- Time to send the next bit
                        sdata <= tx_frame(bit_index);    -- Output the current bit on 'sdata'
                        bit_index <= bit_index + 1;      -- Move to the next bit
                        count_down <= full_count;        -- Reset countdown timer for next bit
                        if bit_index = 10 then           -- All bits have been transmitted
                            state_tx   <= idle;          -- Return to idle state
                            busy       <= '0';           -- Transmitter is no longer busy
                            bit_index  <= 0;             -- Reset bit index
                            sdata      <= '1';           -- Ensure 'sdata' is high in idle
                        end if;
                    else
                        count_down <= count_down - 1;    -- Decrement countdown timer
                    end if;

                when others =>
                    -- Default case: return to idle state
                    state_tx <= idle;
            end case;
        end if;
    end process;

end Behavioral;
