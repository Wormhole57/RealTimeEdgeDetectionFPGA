-- Import libraries
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;

-- Entity
ENTITY Counter IS
	GENERIC( N: 				INTEGER := 10);  -- Length of output vector [bit]
	PORT( CLOCK:				IN 		STD_LOGIC;
			ENABLE:				IN 		STD_LOGIC;
			ACTIVE_LOW_RESET:	IN 		STD_LOGIC;
			OUTPUT:				OUT 		STD_LOGIC_VECTOR(N-1 downto 0));
END Counter;

-- Architecture
ARCHITECTURE Behavior OF Counter IS
	
	SIGNAL i: STD_LOGIC_VECTOR(N-1 downto 0) := (others => '0');
	
	BEGIN
	
		counting: PROCESS(CLOCK, ACTIVE_LOW_RESET, ENABLE)
		BEGIN
			-- Handle reset
			IF ACTIVE_LOW_RESET = '0' THEN
				i <= (others => '0');
			-- Otherwise increment counter
			ELSIF rising_edge(CLOCK) THEN
				IF ENABLE = '1' THEN
					i <= i + 1;
				END IF;
			END IF;
		END PROCESS counting;
	
		OUTPUT <= i;
		
END Behavior;