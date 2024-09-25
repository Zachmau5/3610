library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top is
    Port ( 
        clk : in std_logic;  -- 100 MHz clock input
        reset : in std_logic; -- Reset input
        sdata : in std_logic; -- Serial data input
        led_out : out std_logic_vector(7 downto 0)  -- Output LEDs (to show received byte)
    );
end top;

architecture Behavioral of top is

-- Component declaration for UART_RX
component UART_RX is
    Port (
        clk   : in std_logic; -- clock input
        reset : in std_logic; -- reset, active high
        sdata : in std_logic; -- serial data input
        pdata : out std_logic_vector(7 downto 0); -- parallel data output
        ready : out std_logic -- ready strobe, active high
    );
end component;

-- Signals
signal byte_ready : std_logic;  -- Signal for ready status from UART_RX
signal pdata_s : std_logic_vector(7 downto 0);  -- Internal signal to hold pdata from UART_RX

begin

-- Instantiate the UART_RX component
U1: UART_RX 
    port map (
        clk => clk,  -- Connect to top-level clock
        reset => reset,  -- Connect top-level reset
        sdata => sdata,  -- Connect the serial data input
        pdata => pdata_s,  -- Connect the parallel data output to internal signal
        ready => byte_ready  -- Connect the ready signal
);

-- Only show data on LEDs when ready is high
led_out <= pdata_s when byte_ready = '1' else (others => '0');  -- Clear LEDs when data is not ready

end Behavioral;
