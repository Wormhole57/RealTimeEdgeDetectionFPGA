-- Import libraries
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE ieee.std_logic_unsigned.all;

-- Entity
ENTITY FifoLinebuffer IS
	GENERIC( DATA_LEN: 	INTEGER := 8;
				NUM_COLS: 	INTEGER := 640);
	PORT( CLOCK: 			IN 		STD_LOGIC;
			FSYNC: 			IN 		STD_LOGIC;
			RSYNC: 			IN 		STD_LOGIC;
			DATA_IN: 		IN 		STD_LOGIC_VECTOR(DATA_LEN-1 downto 0);
			DATA_BUFFER: 	BUFFER 	STD_LOGIC_VECTOR(DATA_LEN-1 downto 0));
END FifoLinebuffer;

-- Architecture
ARCHITECTURE Behavior OF FifoLinebuffer IS

	TYPE ram_type IS ARRAY(NUM_COLS-1 downto 0) OF STD_LOGIC_VECTOR(DATA_LEN-1 downto 0);
	
	SIGNAL ram_array: 		ram_type;
	SIGNAL NOT_CLOCK: 		STD_LOGIC;
	SIGNAL cols_counter: 	INTEGER := 0;
	
	BEGIN
		NOT_CLOCK <= NOT CLOCK;
		
		-- Reading from memory
		reading: PROCESS(CLOCK, FSYNC, RSYNC)
		BEGIN
			IF rising_edge(CLOCK) THEN
				IF FSYNC = '1' THEN
					IF RSYNC = '1' THEN
						-- Outputting data from buffer
						DATA_BUFFER <= ram_array(cols_counter);
					END IF;
				END IF;
			END IF;
		END PROCESS;
		
		-- Writing on memory
		writing: PROCESS(NOT_CLOCK, FSYNC, RSYNC)
		BEGIN
			IF rising_edge(NOT_CLOCK) THEN
				IF FSYNC = '1' THEN
					IF RSYNC = '1' THEN
						-- Saving data pushing them in buffer
						ram_array(cols_counter) <= DATA_IN;
						
						-- Handle the colomn counter
						IF cols_counter < NUM_COLS-1 THEN
							cols_counter <= cols_counter + 1;
						ELSE
							cols_counter <= 0;
						END IF;
					ELSE
						cols_counter <= 0;
					END IF;
				END IF;
			END IF;
		END PROCESS;
		
END Behavior;