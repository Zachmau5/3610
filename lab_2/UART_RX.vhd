library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity UART_RX is
    Port ( 
        clk    : in std_logic;  -- clock input
        reset  : in std_logic;  -- reset, active high
        sdata  : in std_logic;  -- serial data in
        pdata  : out std_logic_vector(7 downto 0); -- parallel data out
        ready  : out std_logic  -- ready strobe, active high
    );
end UART_RX;

architecture Behavioral of UART_RX is

    -- State machine enumeration
    type state_type is (idle, start_bit, data, stop_bit, save_data);  -- State names in lowercase
    signal state_rx : state_type := idle;  -- Initialize to idle state

    -- Internal signals
    signal data_buffer : std_logic_vector(7 downto 0); -- Temporary storage for received 8-bit data
    signal count_down : integer range 0 to 10417;  -- Countdown for timing based on baud rate
    signal bit_position : integer := 0;  -- Tracks the position in the data buffer (0-7)
    signal debounce_counter : integer range 0 to 3 := 0;  -- Adjustable, find sweet spot
    
    -- Constants
    constant half_count : integer := 5208;  -- Half of full_count, used to sample in the middle of a bit
    constant full_count : integer := 10417; -- Full count for one bit at 9600 baud with a 100 MHz clock
    -- Explanation: FULL_COUNT = 100 MHz / 9600 baud = 10416.67 (~10417)
    -- HALF_COUNT is used to detect the middle of the start bit for accurate data capture

begin

    -- UART receiver process (handles state transitions and timing)
    process(clk, reset)
    begin
        if reset = '1' then
            -- Reset all internal signals to initial states
            state_rx <= idle;
            pdata <= (others => '0');  -- Clear parallel data output
            ready <= '0';  -- Reset ready signal
            bit_position <= 0;  -- Reset bit position counter
            count_down <= full_count;  -- Reset countdown for baud timing
        elsif rising_edge(clk) then
            case state_rx is
            -- STATE: idle                
            -- state waits for a start bit, falling edge and the sdata --> 0 or low
            -- added a debounce if I typed too fast it would display wrong value
            -- if valid start bit is detected, move to next state --> start_bit
                
                when idle =>
                    if sdata = '0' then  -- Detect start bit
                        if debounce_counter = 3 then  -- Confirm stable low (start bit)
                            state_rx <= start_bit; -- move to start bit 
                            count_down <= half_count;  -- Start counting for mid-bit sample
                            bit_position <= 0; -- declare start at 0 index
                            ready <= '0'; --not ready to tx
                            debounce_counter <= 0; -- declare debounce is gtg, move on
                        else
                            debounce_counter <= debounce_counter + 1;  -- Increment debounce counter
                        end if;
                    else
                        debounce_counter <= 0;  -- Reset debounce counter if line is high
--                        pdata<="00000000";
                    end if;
                    
            -- STATE: start_bit
            -- Once in this state, waits until middle of bit using count_down counter
            -- count_down was populated to be half in the previous state
            -- once count_down ==0, midpoint has been reached and will move to next state and reset to normal width
               
                when start_bit =>
                    if count_down = 0 then
                        state_rx <= data;  -- Move to data collection state
                        count_down <= full_count;  -- Reset countdown for the first data bit
                    else
                        count_down <= count_down - 1;  -- Decrease the countdown
                    end if;
                    
            -- STATE: data
            -- collect 8 bits of data, sdata (serial data) and then throws them into a shift register or buffer/mux
            -- bit position monitors to see if 8 bits are found, if 8 are found, it transitions to stop_bit    
                when data =>
                    if bit_position = 8 then  -- After receiving 8 bits (0 to 7), move to stop bit
                        state_rx <= stop_bit;  -- All data bits collected
                        count_down <= full_count;  -- Set countdown for the stop bit
                    elsif count_down = 0 then
                        data_buffer(bit_position) <= sdata;  -- Capture current bit into data buffer
                        bit_position <= bit_position + 1;  -- Move to next bit position
                        count_down <= full_count;  -- Reset countdown for next bit
                    else
                        count_down <= count_down - 1;  -- Decrease the countdown
                    end if;
            -- STATE: stop_bit
            -- after all data is rx'd, it checks for stop bit ==1 (unnecessary but want to make sure sampling correctly)
            -- if it is valid, it moves to next state, save_data, if stop is invalid, returns to idle
                when stop_bit => 
                    if (count_down = 0) and (sdata = '1') then  -- Check for valid stop bit (line high)
                        state_rx <= save_data; -- valid stop bit
                        pdata <= data_buffer;  -- Transfer received data to pdata output
                    elsif (count_down = 0) and (sdata = '0') then
                        state_rx <= idle;  -- Invalid stop bit, return to idle
                        ready <= '0';  -- Clear ready signal
                    else
                        count_down <= count_down - 1;  -- Decrease the countdown for the stop bit
                    end if;
                    
            -- STATE: save_data
            -- the rx'd byte that is stored in the buffer, is transferred to pdata                
                when save_data =>
                    ready <= '1';  -- Indicate that data is ready
                    state_rx <= idle;  -- Return to idle state after saving data
                
                when others =>
                    state_rx <= idle;  -- Default case, return to idle
            end case;
        end if;
    end process;

end Behavioral;

