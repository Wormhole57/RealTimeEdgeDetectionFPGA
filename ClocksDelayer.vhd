-- Import libraries
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE ieee.std_logic_unsigned.all;

-- Entity
ENTITY ClocksDelayer IS
	GENERIC( ROWS_IN_BIT: 	INTEGER := 9); -- 2^9 = 512 > 480 px
	PORT( CLOCK: 				IN 		STD_LOGIC	:= '0';
			FSYNC_IN: 			IN 		STD_LOGIC	:= '0';
			RSYNC_IN: 			IN 		STD_LOGIC	:= '0';
			FSYNC_OUT: 			OUT 		STD_LOGIC;
			RSYNC_OUT: 			OUT 		STD_LOGIC);
END ClocksDelayer;

-- Architecture
ARCHITECTURE Behavior OF ClocksDelayer IS
	
	-- Signals
	SIGNAL counterRisingEdges: 	STD_LOGIC_VECTOR(ROWS_IN_BIT-1 downto 0);
	SIGNAL counterFallingEdges: 	STD_LOGIC_VECTOR(ROWS_IN_BIT-1 downto 0)	:= (others => '0');
	SIGNAL rsync1: 					STD_LOGIC := '0'; -- Internal rsync
	SIGNAL rsync2: 					STD_LOGIC := '0'; -- Internal rsync delayed by 1 pixel clock period
	SIGNAL rsync3: 					STD_LOGIC := '0'; -- Internal rsync delayed by 2 pixel clock periods
	SIGNAL fsync1: 					STD_LOGIC := '0'; -- Internal fsync
	
	-- Components
	COMPONENT Counter
		GENERIC( N: 				POSITIVE);
		PORT( CLOCK:				IN 		STD_LOGIC;
				ENABLE:				IN 		STD_LOGIC;
				ACTIVE_LOW_RESET:	IN 		STD_LOGIC;
				OUTPUT:				OUT 		STD_LOGIC_VECTOR(N-1 downto 0));
	END COMPONENT;
	
	BEGIN
	
		-- Istantiate components
		RowsCounter: Counter
			GENERIC MAP( N 				=> ROWS_IN_BIT)
			PORT MAP( CLOCK				=> rsync3,		-- Counts rising edges of the rsync	delayed by 2 pixel clock periods
						 ENABLE				=> FSYNC_IN,	-- only if a row is displaying
						 ACTIVE_LOW_RESET	=> FSYNC_IN,	-- and resets when row ends
						 OUTPUT				=> counterRisingEdges);
		
		-- Update output sync waves
		RSYNC_OUT <= rsync3;
		FSYNC_OUT <= fsync1;
		
		-- Generate rsync output delayed signal
		rsync_delayer: PROCESS(CLOCK)
		BEGIN
			IF rising_edge(CLOCK) THEN
				rsync3	<= rsync2;
				rsync2 	<= rsync1;
				rsync1 	<= RSYNC_IN;
			END IF;
		END PROCESS rsync_delayer;
		
		-- Generate fsync output delayed signal
		fsync_delayer: PROCESS(counterRisingEdges, counterFallingEdges)
		BEGIN
			-- Start the delayed fsync when the row counter turns to "2"
			IF counterRisingEdges = STD_LOGIC_VECTOR(TO_UNSIGNED(2, ROWS_IN_BIT)) THEN
				fsync1 <= '1';
			-- Stop the delayed fsync after the row counter turns to "0"
			ELSIF counterFallingEdges = STD_LOGIC_VECTOR(TO_UNSIGNED(0, ROWS_IN_BIT)) THEN
				fsync1 <= '0';
			END IF;
		END PROCESS fsync_delayer;
		
		-- Count falling edges of the rsync	delayed signal
		count_falling_rsync_plus2: PROCESS(rsync3, fsync1)
		BEGIN
			IF falling_edge(rsync3) THEN
				IF fsync1 = '1' THEN
					-- Reset counter on last row
					IF counterFallingEdges = STD_LOGIC_VECTOR(TO_UNSIGNED(479, ROWS_IN_BIT)) THEN
						counterFallingEdges <= (others => '0');
					ELSE
						counterFallingEdges <= counterFallingEdges + 1;
					END IF;
				ELSE
					-- Reset counter when frame ends
					counterFallingEdges <= (others => '0');
				END IF;
			END IF;
		END PROCESS count_falling_rsync_plus2;
		
END Behavior;