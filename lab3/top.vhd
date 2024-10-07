library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top is
    Port (
        clk      : in std_logic;  -- 100 MHz clock input
        led_out  : out std_logic_vector(7 downto 0);  -- Output LEDs
        switch   : in std_logic_vector(7 downto 0);  -- Switch input for tones
        freq     : out std_logic;  -- Frequency output for audio generation
        gain     : out std_logic;  -- Gain control for Pmod AMP2
--        check    : out STD_LOGIC;
        shutdown : out std_logic   -- Shutdown control for Pmod AMP2
    );
end top;

architecture Behavioral of top is

    -- Component declaration for SwitchPiano
    component SwitchPiano is
        Port ( 
            Clk      : in std_logic;
            switch   : in std_logic_vector(7 downto 0);
            LED      : out std_logic_vector(7 downto 0);
            freq     : out std_logic;
            gain     : out std_logic;
--            check    : out STD_LOGIC;
            shutdown : out std_logic
        );
    end component;

begin
    -- Instantiate SwitchPiano with audio support
    U1: SwitchPiano
        Port map (
            Clk      => clk,
            switch   => switch,
            LED      => led_out,
            freq     => freq,  -- Audio frequency output
            gain     => gain,  -- Gain control signal
--            check   =>check,
            shutdown => shutdown  -- Shutdown control signal
        );

end Behavioral;
