-- Import libraries
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE ieee.std_logic_unsigned.all;

-- Entity
ENTITY CacheSystem IS
	GENERIC( DATA_LEN: 					INTEGER := 8;
				NUM_EL_IN_CACHE: 			INTEGER := 3; -- Dimension of mask
				NUM_COLS: 					INTEGER := 640;
				NUM_ROWS: 					INTEGER := 480;
				ROWS_IN_BIT: 				INTEGER := 9; -- 2^9 = 512 > 480 px
				COLS_IN_BIT: 				INTEGER := 10); -- 2^10 = 1024 > 640 px
	PORT( CLOCK: 				IN 		STD_LOGIC;
			FSYNC_IN: 			IN 		STD_LOGIC;
			RSYNC_IN: 			IN 		STD_LOGIC;
			DATA_IN: 			IN 		STD_LOGIC_VECTOR(DATA_LEN-1 downto 0);
			FSYNC_OUT: 			OUT 		STD_LOGIC;
			RSYNC_OUT: 			OUT 		STD_LOGIC;
			DATA_OUT1: 			OUT 		STD_LOGIC_VECTOR(DATA_LEN-1 downto 0);
			DATA_OUT2: 			OUT 		STD_LOGIC_VECTOR(DATA_LEN-1 downto 0);
			DATA_OUT3: 			OUT 		STD_LOGIC_VECTOR(DATA_LEN-1 downto 0);
			DATA_OUT4: 			OUT 		STD_LOGIC_VECTOR(DATA_LEN-1 downto 0);
			DATA_OUT5: 			OUT 		STD_LOGIC_VECTOR(DATA_LEN-1 downto 0);
			DATA_OUT6: 			OUT 		STD_LOGIC_VECTOR(DATA_LEN-1 downto 0);
			DATA_OUT7: 			OUT 		STD_LOGIC_VECTOR(DATA_LEN-1 downto 0);
			DATA_OUT8: 			OUT 		STD_LOGIC_VECTOR(DATA_LEN-1 downto 0);
			DATA_OUT9: 			OUT 		STD_LOGIC_VECTOR(DATA_LEN-1 downto 0));
END CacheSystem;

-- Architecture
ARCHITECTURE Behavior OF CacheSystem IS

	-- Components
	COMPONENT Counter
		GENERIC( N: 				POSITIVE);
		PORT( CLOCK:				IN 		STD_LOGIC;
				ENABLE:				IN 		STD_LOGIC;
				ACTIVE_LOW_RESET:	IN 		STD_LOGIC;
				OUTPUT:				OUT 		STD_LOGIC_VECTOR(N-1 downto 0));
	END COMPONENT;
	
	COMPONENT DoubleFifoLinebuffer
		GENERIC( DATA_LEN: 	INTEGER := 8;
					NUM_COLS: 	INTEGER := 640);
		PORT( CLOCK: 			IN 		STD_LOGIC;
				FSYNC: 			IN 		STD_LOGIC;
				RSYNC: 			IN 		STD_LOGIC;
				DATA_IN: 		IN 		STD_LOGIC_VECTOR(DATA_LEN-1 downto 0);
				DATA_OUT1: 		OUT	 	STD_LOGIC_VECTOR(DATA_LEN-1 downto 0);
				DATA_OUT2: 		BUFFER 	STD_LOGIC_VECTOR(DATA_LEN-1 downto 0);
				DATA_OUT3: 		BUFFER 	STD_LOGIC_VECTOR(DATA_LEN-1 downto 0));
	END COMPONENT;
	
	COMPONENT ClocksDelayer
		GENERIC( ROWS_IN_BIT: 	INTEGER := 9);
		PORT( CLOCK: 				IN 		STD_LOGIC;
				FSYNC_IN: 			IN 		STD_LOGIC;
				RSYNC_IN: 			IN 		STD_LOGIC;
				FSYNC_OUT: 			OUT 		STD_LOGIC;
				RSYNC_OUT: 			OUT 		STD_LOGIC);
	END COMPONENT;
	
	-- Signals
	-- Counters
	SIGNAL counterRows:		STD_LOGIC_VECTOR(ROWS_IN_BIT-1 downto 0);
	SIGNAL counterCols:		STD_LOGIC_VECTOR(COLS_IN_BIT-1 downto 0);
	-- Output data from DoubleFifoLinebuffer (n-th pixel of the last 3 rows)
	SIGNAL out1:				STD_LOGIC_VECTOR(DATA_LEN-1 downto 0);
	SIGNAL out2:				STD_LOGIC_VECTOR(DATA_LEN-1 downto 0);
	SIGNAL out3:				STD_LOGIC_VECTOR(DATA_LEN-1 downto 0);
	-- Internal sync waves
	SIGNAL fsync1:				STD_LOGIC;
	SIGNAL rsync1:				STD_LOGIC;
	-- Caches of the last 3 pixel for the last 3 rows
	SHARED VARIABLE cache1:	STD_LOGIC_VECTOR((NUM_EL_IN_CACHE * DATA_LEN)-1 downto 0);
	SHARED VARIABLE cache2:	STD_LOGIC_VECTOR((NUM_EL_IN_CACHE * DATA_LEN)-1 downto 0);
	SHARED VARIABLE cache3:	STD_LOGIC_VECTOR((NUM_EL_IN_CACHE * DATA_LEN)-1 downto 0);
	-- These caches are a concatenation of 3 8-BIT values
	-- and they shift every new input in this way:
	--                     Cache1:
	--             |--------------------|
	-- NEWDATA --> |  z9  |  z8  |  z7  | --> OLDDATA IS DELETED
	--             |--------------------|
	--             23   16|15   8|7     0 <= BIT
	--                     Cache2:
	--             |--------------------|
	-- NEWDATA --> |  z6  |  z5  |  z4  | --> OLDDATA IS DELETED
	--             |--------------------|
	-- 				23   16|15   8|7     0 <= BIT
	-- 								  Cache3:
	--             |--------------------|
	-- NEWDATA --> |  z3  |  z2  |  z1  | --> OLDDATA IS DELETED
	--             |--------------------|
	--             23   16|15   8|7     0 <= BIT
	
	BEGIN
		
		-- Istantiate components
		RowsCounter: Counter
			GENERIC MAP( N 				=> ROWS_IN_BIT)
			PORT MAP( CLOCK				=> rsync1,
						 ENABLE				=> fsync1,
						 ACTIVE_LOW_RESET	=> fsync1,
						 OUTPUT				=> counterRows);
		
		ColsCounter: Counter
			GENERIC MAP( N 				=> COLS_IN_BIT)
			PORT MAP( CLOCK				=> CLOCK,
						 ENABLE				=> rsync1,
						 ACTIVE_LOW_RESET	=> rsync1,
						 OUTPUT				=> counterCols);
		
		DoubleFifoLinebuffer1: DoubleFifoLinebuffer
			GENERIC MAP( DATA_LEN 	=> DATA_LEN,
							 NUM_COLS 	=> NUM_COLS)
			PORT MAP( CLOCK 			=> CLOCK,
						 FSYNC 			=> FSYNC_IN,
						 RSYNC 			=> RSYNC_IN,
						 DATA_IN 		=> DATA_IN,
						 DATA_OUT1 		=> out1,
						 DATA_OUT2 		=> out2,
						 DATA_OUT3 		=> out3);
		
		ClocksDelayer1: ClocksDelayer
			GENERIC MAP( ROWS_IN_BIT 	=> ROWS_IN_BIT)
			PORT MAP( CLOCK 				=> CLOCK,
						 FSYNC_IN 			=> FSYNC_IN,
						 RSYNC_IN 			=> RSYNC_IN,
						 FSYNC_OUT 			=> fsync1,
						 RSYNC_OUT 			=> rsync1);
		
		-- Update output sync waves
		RSYNC_OUT <= rsync1;
		FSYNC_OUT <= fsync1;
		
		-- Handle elements in the 3 caches
		shifting: PROCESS(CLOCK)
		BEGIN
			IF rising_edge(CLOCK) THEN
				-- 8-BIT value from the "cell" 15-to-8 shifts to "cell" 7-to-0
				cache1( DATA_LEN-1 downto 0 )																	:=		cache1( (NUM_EL_IN_CACHE-1)*DATA_LEN-1 downto (NUM_EL_IN_CACHE-2)*DATA_LEN );
				cache2( DATA_LEN-1 downto 0 )																	:=		cache2( (NUM_EL_IN_CACHE-1)*DATA_LEN-1 downto (NUM_EL_IN_CACHE-2)*DATA_LEN );
				cache3( DATA_LEN-1 downto 0 )																	:=		cache3( (NUM_EL_IN_CACHE-1)*DATA_LEN-1 downto (NUM_EL_IN_CACHE-2)*DATA_LEN );
				-- 8-BIT value from the "cell" 23-to-16 shifts to "cell" 15-to-8
				cache1( (NUM_EL_IN_CACHE-1)*DATA_LEN-1 downto (NUM_EL_IN_CACHE-2)*DATA_LEN )	:=		cache1( (NUM_EL_IN_CACHE-0)*DATA_LEN-1 downto (NUM_EL_IN_CACHE-1)*DATA_LEN );
				cache2( (NUM_EL_IN_CACHE-1)*DATA_LEN-1 downto (NUM_EL_IN_CACHE-2)*DATA_LEN )	:=		cache2( (NUM_EL_IN_CACHE-0)*DATA_LEN-1 downto (NUM_EL_IN_CACHE-1)*DATA_LEN );
				cache3( (NUM_EL_IN_CACHE-1)*DATA_LEN-1 downto (NUM_EL_IN_CACHE-2)*DATA_LEN )	:=		cache3( (NUM_EL_IN_CACHE-0)*DATA_LEN-1 downto (NUM_EL_IN_CACHE-1)*DATA_LEN );
				-- 8-BIT new coming data is stored in the "cell" 23-to-16
				cache1( (NUM_EL_IN_CACHE-0)*DATA_LEN-1 downto (NUM_EL_IN_CACHE-1)*DATA_LEN )	:=		out1;
				cache2( (NUM_EL_IN_CACHE-0)*DATA_LEN-1 downto (NUM_EL_IN_CACHE-1)*DATA_LEN )	:=		out2;
				cache3( (NUM_EL_IN_CACHE-0)*DATA_LEN-1 downto (NUM_EL_IN_CACHE-1)*DATA_LEN )	:=		out3;
			END IF;
		END PROCESS shifting;
		
		-- Split 24-BIT caches in 3 8-BIT data for outputs
		produce_outputs: PROCESS(counterRows, counterCols, fsync1)
		BEGIN
			IF fsync1 = '1' THEN
				-- Discriminate the 9 possible cases
				IF counterRows = STD_LOGIC_VECTOR(TO_UNSIGNED(0, ROWS_IN_BIT)) AND counterCols = STD_LOGIC_VECTOR(TO_UNSIGNED(0, COLS_IN_BIT)) THEN
					-- First pixel
					-- z1,z2,z3,z4,z7 to black
					DATA_OUT1 <= (others => '0');
					DATA_OUT2 <= (others => '0');
					DATA_OUT3 <= (others => '0');
					DATA_OUT4 <= (others => '0');
					DATA_OUT7 <= (others => '0');

					DATA_OUT5 <= cache2( (NUM_EL_IN_CACHE-1)*DATA_LEN-1 downto (NUM_EL_IN_CACHE-2)*DATA_LEN );
					DATA_OUT6 <= cache2( (NUM_EL_IN_CACHE-0)*DATA_LEN-1 downto (NUM_EL_IN_CACHE-1)*DATA_LEN );

					DATA_OUT8 <= cache1( (NUM_EL_IN_CACHE-1)*DATA_LEN-1 downto (NUM_EL_IN_CACHE-2)*DATA_LEN );
					DATA_OUT9 <= cache1( (NUM_EL_IN_CACHE-0)*DATA_LEN-1 downto (NUM_EL_IN_CACHE-1)*DATA_LEN );
				ELSIF counterRows = STD_LOGIC_VECTOR(TO_UNSIGNED(0, ROWS_IN_BIT)) AND counterCols > STD_LOGIC_VECTOR(TO_UNSIGNED(0, COLS_IN_BIT)) AND counterCols < STD_LOGIC_VECTOR(TO_UNSIGNED(NUM_COLS-1, COLS_IN_BIT)) THEN
					-- First row (not first pixel nor last one)
					-- z1,z2,z3 to black
					DATA_OUT1 <= (others => '0');
					DATA_OUT2 <= (others => '0');
					DATA_OUT3 <= (others => '0');
					
					DATA_OUT4 <= cache2( 						  DATA_LEN-1 downto 									  0 );
					DATA_OUT5 <= cache2( (NUM_EL_IN_CACHE-1)*DATA_LEN-1 downto (NUM_EL_IN_CACHE-2)*DATA_LEN );
					DATA_OUT6 <= cache2( (NUM_EL_IN_CACHE-0)*DATA_LEN-1 downto (NUM_EL_IN_CACHE-1)*DATA_LEN );
					
					DATA_OUT7 <= cache1( 						  DATA_LEN-1 downto 									  0 );
					DATA_OUT8 <= cache1( (NUM_EL_IN_CACHE-1)*DATA_LEN-1 downto (NUM_EL_IN_CACHE-2)*DATA_LEN );
					DATA_OUT9 <= cache1( (NUM_EL_IN_CACHE-0)*DATA_LEN-1 downto (NUM_EL_IN_CACHE-1)*DATA_LEN );
				ELSIF counterRows = STD_LOGIC_VECTOR(TO_UNSIGNED(0, ROWS_IN_BIT)) AND counterCols = STD_LOGIC_VECTOR(TO_UNSIGNED(NUM_COLS-1, COLS_IN_BIT)) THEN
					-- First row and last pixel
					-- z1,z2,z3,z6,z9 to black
					DATA_OUT1 <= (others => '0');
					DATA_OUT2 <= (others => '0');
					DATA_OUT3 <= (others => '0');
					DATA_OUT6 <= (others => '0');
					DATA_OUT9 <= (others => '0');
					
					DATA_OUT4 <= cache2( 						  DATA_LEN-1 downto 									  0 );
					DATA_OUT5 <= cache2( (NUM_EL_IN_CACHE-1)*DATA_LEN-1 downto (NUM_EL_IN_CACHE-2)*DATA_LEN );
					
					DATA_OUT7 <= cache1( 						  DATA_LEN-1 downto 									  0 );
					DATA_OUT8 <= cache1( (NUM_EL_IN_CACHE-1)*DATA_LEN-1 downto (NUM_EL_IN_CACHE-2)*DATA_LEN );
				ELSIF counterRows > STD_LOGIC_VECTOR(TO_UNSIGNED(0, ROWS_IN_BIT)) AND counterRows < STD_LOGIC_VECTOR(TO_UNSIGNED(NUM_ROWS-1, ROWS_IN_BIT)) AND counterCols = STD_LOGIC_VECTOR(TO_UNSIGNED(0, COLS_IN_BIT)) THEN
					-- Other rows (not last one) and first column
					-- z1,z4,z7 to black
					DATA_OUT1 <= (others => '0');
					DATA_OUT4 <= (others => '0');
					DATA_OUT7 <= (others => '0');
					
					DATA_OUT2 <= cache3( (NUM_EL_IN_CACHE-1)*DATA_LEN-1 downto (NUM_EL_IN_CACHE-2)*DATA_LEN );
					DATA_OUT3 <= cache3( (NUM_EL_IN_CACHE-0)*DATA_LEN-1 downto (NUM_EL_IN_CACHE-1)*DATA_LEN );
					
					DATA_OUT5 <= cache2( (NUM_EL_IN_CACHE-1)*DATA_LEN-1 downto (NUM_EL_IN_CACHE-2)*DATA_LEN );
					DATA_OUT6 <= cache2( (NUM_EL_IN_CACHE-0)*DATA_LEN-1 downto (NUM_EL_IN_CACHE-1)*DATA_LEN );
					
					DATA_OUT8 <= cache1( (NUM_EL_IN_CACHE-1)*DATA_LEN-1 downto (NUM_EL_IN_CACHE-2)*DATA_LEN );
					DATA_OUT9 <= cache1( (NUM_EL_IN_CACHE-0)*DATA_LEN-1 downto (NUM_EL_IN_CACHE-1)*DATA_LEN );
				ELSIF counterRows > STD_LOGIC_VECTOR(TO_UNSIGNED(0, ROWS_IN_BIT)) AND counterRows < STD_LOGIC_VECTOR(TO_UNSIGNED(NUM_ROWS-1, ROWS_IN_BIT)) AND counterCols > STD_LOGIC_VECTOR(TO_UNSIGNED(0, COLS_IN_BIT)) AND counterCols < STD_LOGIC_VECTOR(TO_UNSIGNED(NUM_COLS-1, COLS_IN_BIT)) THEN
					-- Generix inner pixel
					DATA_OUT1 <= cache3( 						  DATA_LEN-1 downto 									  0 );
					DATA_OUT2 <= cache3( (NUM_EL_IN_CACHE-1)*DATA_LEN-1 downto (NUM_EL_IN_CACHE-2)*DATA_LEN );
					DATA_OUT3 <= cache3( (NUM_EL_IN_CACHE-0)*DATA_LEN-1 downto (NUM_EL_IN_CACHE-1)*DATA_LEN );
					
					DATA_OUT4 <= cache2( 						  DATA_LEN-1 downto 									  0 );
					DATA_OUT5 <= cache2( (NUM_EL_IN_CACHE-1)*DATA_LEN-1 downto (NUM_EL_IN_CACHE-2)*DATA_LEN );
					DATA_OUT6 <= cache2( (NUM_EL_IN_CACHE-0)*DATA_LEN-1 downto (NUM_EL_IN_CACHE-1)*DATA_LEN );
					
					DATA_OUT7 <= cache1( 						  DATA_LEN-1 downto 									  0 );
					DATA_OUT8 <= cache1( (NUM_EL_IN_CACHE-1)*DATA_LEN-1 downto (NUM_EL_IN_CACHE-2)*DATA_LEN );
					DATA_OUT9 <= cache1( (NUM_EL_IN_CACHE-0)*DATA_LEN-1 downto (NUM_EL_IN_CACHE-1)*DATA_LEN );
				ELSIF counterRows > STD_LOGIC_VECTOR(TO_UNSIGNED(0, ROWS_IN_BIT)) AND counterRows < STD_LOGIC_VECTOR(TO_UNSIGNED(NUM_ROWS-1, ROWS_IN_BIT)) AND counterCols = STD_LOGIC_VECTOR(TO_UNSIGNED(NUM_COLS-1, COLS_IN_BIT)) THEN
					-- One the other rows (not last one) and last column, z3,z6,z9 to black
					DATA_OUT3 <= (others => '0');
					DATA_OUT6 <= (others => '0');
					DATA_OUT9 <= (others => '0');
					
					DATA_OUT1 <= cache3( 						  DATA_LEN-1 downto 									  0 );
					DATA_OUT2 <= cache3( (NUM_EL_IN_CACHE-1)*DATA_LEN-1 downto (NUM_EL_IN_CACHE-2)*DATA_LEN );
					
					DATA_OUT4 <= cache2( 						  DATA_LEN-1 downto 									  0 );
					DATA_OUT5 <= cache2( (NUM_EL_IN_CACHE-1)*DATA_LEN-1 downto (NUM_EL_IN_CACHE-2)*DATA_LEN );
					
					DATA_OUT7 <= cache1( 						  DATA_LEN-1 downto 									  0 );
					DATA_OUT8 <= cache1( (NUM_EL_IN_CACHE-1)*DATA_LEN-1 downto (NUM_EL_IN_CACHE-2)*DATA_LEN );
				ELSIF counterRows = STD_LOGIC_VECTOR(TO_UNSIGNED(NUM_ROWS-1, ROWS_IN_BIT)) AND counterCols = STD_LOGIC_VECTOR(TO_UNSIGNED(0, COLS_IN_BIT)) THEN
					-- Last row and first column
					--	z1,z4,z7,z8,z9 to black
					DATA_OUT1 <= (others => '0');
					DATA_OUT4 <= (others => '0');
					DATA_OUT7 <= (others => '0');
					DATA_OUT8 <= (others => '0');
					DATA_OUT9 <= (others => '0');
					
					DATA_OUT2 <= cache3( (NUM_EL_IN_CACHE-1)*DATA_LEN-1 downto (NUM_EL_IN_CACHE-2)*DATA_LEN );
					DATA_OUT3 <= cache3( (NUM_EL_IN_CACHE-0)*DATA_LEN-1 downto (NUM_EL_IN_CACHE-1)*DATA_LEN );
					
					DATA_OUT5 <= cache2( (NUM_EL_IN_CACHE-1)*DATA_LEN-1 downto (NUM_EL_IN_CACHE-2)*DATA_LEN );
					DATA_OUT6 <= cache2( (NUM_EL_IN_CACHE-0)*DATA_LEN-1 downto (NUM_EL_IN_CACHE-1)*DATA_LEN );
				ELSIF counterRows = STD_LOGIC_VECTOR(TO_UNSIGNED(NUM_ROWS-1, ROWS_IN_BIT)) AND counterCols > STD_LOGIC_VECTOR(TO_UNSIGNED(0, COLS_IN_BIT)) AND counterCols < STD_LOGIC_VECTOR(TO_UNSIGNED(NUM_COLS-1, COLS_IN_BIT)) THEN
					-- Last row and other columns (not first nor last one)
					-- z7,z8,z9 to black
					DATA_OUT7 <= (others => '0');
					DATA_OUT8 <= (others => '0');
					DATA_OUT9 <= (others => '0');
					
					DATA_OUT1 <= cache3( 						  DATA_LEN-1 downto 									  0 );
					DATA_OUT2 <= cache3( (NUM_EL_IN_CACHE-1)*DATA_LEN-1 downto (NUM_EL_IN_CACHE-2)*DATA_LEN );
					DATA_OUT3 <= cache3( (NUM_EL_IN_CACHE-0)*DATA_LEN-1 downto (NUM_EL_IN_CACHE-1)*DATA_LEN );
					
					DATA_OUT4 <= cache2( 						  DATA_LEN-1 downto 									  0 );
					DATA_OUT5 <= cache2( (NUM_EL_IN_CACHE-1)*DATA_LEN-1 downto (NUM_EL_IN_CACHE-2)*DATA_LEN );
					DATA_OUT6 <= cache2( (NUM_EL_IN_CACHE-0)*DATA_LEN-1 downto (NUM_EL_IN_CACHE-1)*DATA_LEN );
				ELSIF counterRows = STD_LOGIC_VECTOR(TO_UNSIGNED(NUM_ROWS-1, ROWS_IN_BIT)) AND counterCols = STD_LOGIC_VECTOR(TO_UNSIGNED(NUM_COLS-1, COLS_IN_BIT)) THEN
					-- Last pixel
					-- z3,z6,z9,z8,z7 to black
					DATA_OUT3 <= (others => '0');
					DATA_OUT6 <= (others => '0');
					DATA_OUT9 <= (others => '0');
					DATA_OUT8 <= (others => '0');
					DATA_OUT7 <= (others => '0');
					
					DATA_OUT1 <= cache3( 						  DATA_LEN-1 downto 									  0 );
					DATA_OUT2 <= cache3( (NUM_EL_IN_CACHE-1)*DATA_LEN-1 downto (NUM_EL_IN_CACHE-2)*DATA_LEN );
					
					DATA_OUT4 <= cache2( 						  DATA_LEN-1 downto 									  0 );
					DATA_OUT5 <= cache2( (NUM_EL_IN_CACHE-1)*DATA_LEN-1 downto (NUM_EL_IN_CACHE-2)*DATA_LEN );
				END IF;
			END IF;
		END PROCESS produce_outputs;
		
END Behavior;