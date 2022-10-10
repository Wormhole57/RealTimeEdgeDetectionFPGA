-- Import libraries
LIBRARY ieee;
USE ieee.std_logic_1164.all;

-- Entity
ENTITY EdgeDetector IS
	GENERIC( DATA_LEN: 					INTEGER := 8;
				NUM_EL_IN_CACHE: 			INTEGER := 3;
				NUM_COLS: 					INTEGER := 640;
				NUM_ROWS: 					INTEGER := 480;
				ROWS_IN_BIT: 				INTEGER := 9;
				COLS_IN_BIT: 				INTEGER := 10);
	PORT( CLOCK: 			IN 		STD_LOGIC;
			FSYNC_IN: 		IN 		STD_LOGIC;
			RSYNC_IN: 		IN 		STD_LOGIC;
			DATA_IN: 		IN 		STD_LOGIC_VECTOR(DATA_LEN-1 downto 0);
			FSYNC_OUT: 		OUT 		STD_LOGIC;
			RSYNC_OUT: 		OUT 		STD_LOGIC;
			DATA_OUT_B: 	OUT 		STD_LOGIC_VECTOR(DATA_LEN-1 downto 0);
			DATA_OUT_G: 	OUT 		STD_LOGIC_VECTOR(DATA_LEN-1 downto 0);
			DATA_OUT_R: 	OUT 		STD_LOGIC_VECTOR(DATA_LEN-1 downto 0));
END EdgeDetector;

-- Architecture
ARCHITECTURE Behavior OF EdgeDetector IS
	
	-- Signals
	SIGNAL z1:	STD_LOGIC_VECTOR(DATA_LEN-1 downto 0);
	SIGNAL z2:	STD_LOGIC_VECTOR(DATA_LEN-1 downto 0);
	SIGNAL z3:	STD_LOGIC_VECTOR(DATA_LEN-1 downto 0);
	SIGNAL z4:	STD_LOGIC_VECTOR(DATA_LEN-1 downto 0);
	SIGNAL z5:	STD_LOGIC_VECTOR(DATA_LEN-1 downto 0);
	SIGNAL z6:	STD_LOGIC_VECTOR(DATA_LEN-1 downto 0);
	SIGNAL z7:	STD_LOGIC_VECTOR(DATA_LEN-1 downto 0);
	SIGNAL z8:	STD_LOGIC_VECTOR(DATA_LEN-1 downto 0);
	SIGNAL z9:	STD_LOGIC_VECTOR(DATA_LEN-1 downto 0);
	
	SIGNAL fsync_inner:	STD_LOGIC;
	SIGNAL rsync_inner:	STD_LOGIC;
	
	SIGNAL data_out: STD_LOGIC_VECTOR(DATA_LEN-1 downto 0);
	
	-- Components
	COMPONENT CacheSystem
		GENERIC( DATA_LEN: 					INTEGER := 8;
					NUM_EL_IN_CACHE: 			INTEGER := 3;
					NUM_COLS: 					INTEGER := 640;
					NUM_ROWS: 					INTEGER := 480;
					ROWS_IN_BIT: 				INTEGER := 9;
					COLS_IN_BIT: 				INTEGER := 10);
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
	END COMPONENT;
	
	COMPONENT SobelKernel
		GENERIC( DATA_LEN: 				INTEGER := 8);
		PORT( CLOCK: 				IN 		STD_LOGIC;
				FSYNC_IN: 			IN 		STD_LOGIC;
				RSYNC_IN: 			IN 		STD_LOGIC;
				DATA_IN1: 			IN 		STD_LOGIC_VECTOR(DATA_LEN-1 downto 0);
				DATA_IN2: 			IN 		STD_LOGIC_VECTOR(DATA_LEN-1 downto 0);
				DATA_IN3: 			IN 		STD_LOGIC_VECTOR(DATA_LEN-1 downto 0);
				DATA_IN4: 			IN 		STD_LOGIC_VECTOR(DATA_LEN-1 downto 0);
				DATA_IN5: 			IN 		STD_LOGIC_VECTOR(DATA_LEN-1 downto 0);
				DATA_IN6: 			IN 		STD_LOGIC_VECTOR(DATA_LEN-1 downto 0);
				DATA_IN7: 			IN 		STD_LOGIC_VECTOR(DATA_LEN-1 downto 0);
				DATA_IN8: 			IN 		STD_LOGIC_VECTOR(DATA_LEN-1 downto 0);
				DATA_IN9: 			IN 		STD_LOGIC_VECTOR(DATA_LEN-1 downto 0);
				FSYNC_OUT: 			OUT 		STD_LOGIC;
				RSYNC_OUT: 			OUT 		STD_LOGIC;
				DATA_OUT: 			OUT 		STD_LOGIC_VECTOR(DATA_LEN-1 downto 0));
	END COMPONENT;
	
	BEGIN
		
		-- Istantiate components
		CacheSystem1: CacheSystem
			GENERIC MAP( 	DATA_LEN 			=> DATA_LEN,
								NUM_EL_IN_CACHE	=> NUM_EL_IN_CACHE,
								NUM_COLS 			=> NUM_COLS,
								NUM_ROWS 			=> NUM_ROWS,
								ROWS_IN_BIT 		=> ROWS_IN_BIT,
								COLS_IN_BIT 		=> COLS_IN_BIT)
			PORT MAP( 	CLOCK 			=> CLOCK,
							FSYNC_IN 		=> FSYNC_IN,
							RSYNC_IN 		=> RSYNC_IN,
							DATA_IN 			=> DATA_IN,
							FSYNC_OUT 		=> fsync_inner,
							RSYNC_OUT 		=> rsync_inner,
							DATA_OUT1 		=> z1,
							DATA_OUT2 		=> z2,
							DATA_OUT3 		=> z3,
							DATA_OUT4 		=> z4,
							DATA_OUT5 		=> z5,
							DATA_OUT6 		=> z6,
							DATA_OUT7 		=> z7,
							DATA_OUT8 		=> z8,
							DATA_OUT9 		=> z9);
			  
		SobelKernel1: SobelKernel
			GENERIC MAP( 	DATA_LEN 			=> DATA_LEN)
			PORT MAP( 	CLOCK 			=> CLOCK,
							FSYNC_IN 		=> fsync_inner,
							RSYNC_IN 		=> rsync_inner,
							DATA_IN1 		=> z1,
							DATA_IN2 		=> z2,
							DATA_IN3 		=> z3,
							DATA_IN4 		=> z4,
							DATA_IN5 		=> z5,
							DATA_IN6 		=> z6,
							DATA_IN7 		=> z7,
							DATA_IN8 		=> z8,
							DATA_IN9 		=> z9,
							FSYNC_OUT 		=> FSYNC_OUT,
							RSYNC_OUT 		=> RSYNC_OUT,
							DATA_OUT 		=> data_out);
		
		--Set same gray scale output for the 3 output colors
		DATA_OUT_B <= data_out;
		DATA_OUT_G <= data_out;
		DATA_OUT_R <= data_out;
		
END Behavior;