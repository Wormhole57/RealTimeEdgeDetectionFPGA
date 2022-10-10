-- Import libraries
LIBRARY ieee;
USE ieee.std_logic_1164.all;

-- Entity
ENTITY DoubleFifoLinebuffer IS
	GENERIC( DATA_LEN: 	INTEGER := 8;
				NUM_COLS: 	INTEGER := 640);
	PORT( CLOCK: 			IN 		STD_LOGIC;
			FSYNC: 			IN 		STD_LOGIC;
			RSYNC: 			IN 		STD_LOGIC;
			DATA_IN: 		IN 		STD_LOGIC_VECTOR(DATA_LEN-1 downto 0);
			DATA_OUT1: 		OUT	 	STD_LOGIC_VECTOR(DATA_LEN-1 downto 0);
			DATA_OUT2: 		BUFFER 	STD_LOGIC_VECTOR(DATA_LEN-1 downto 0);
			DATA_OUT3: 		BUFFER 	STD_LOGIC_VECTOR(DATA_LEN-1 downto 0));
END DoubleFifoLinebuffer;

-- Architecture
ARCHITECTURE Behavior OF DoubleFifoLinebuffer IS

	COMPONENT FifoLinebuffer
		GENERIC( DATA_LEN: 	INTEGER := 8;
					NUM_COLS: 	INTEGER := 640);
		PORT( CLOCK: 			IN 		STD_LOGIC;
				FSYNC: 			IN 		STD_LOGIC;
				RSYNC: 			IN 		STD_LOGIC;
				DATA_IN: 		IN 		STD_LOGIC_VECTOR(DATA_LEN-1 downto 0);
				DATA_BUFFER: 	BUFFER 	STD_LOGIC_VECTOR(DATA_LEN-1 downto 0));
	END COMPONENT;
	
	BEGIN
	
		-- Istantiate 2 single FifoLinebuffers	
		FifoLinebuffer1: FifoLinebuffer
			GENERIC MAP( DATA_LEN 	=> DATA_LEN,
							 NUM_COLS 	=> NUM_COLS)
			PORT MAP( CLOCK 			=> CLOCK,
						 FSYNC 			=> FSYNC,
						 RSYNC 			=> RSYNC,
						 DATA_IN 		=> DATA_IN,
						 DATA_BUFFER 	=> DATA_OUT2);

		FifoLinebuffer2: FifoLinebuffer
			GENERIC MAP( DATA_LEN 	=> DATA_LEN,
							 NUM_COLS 	=> NUM_COLS)
			PORT MAP( CLOCK 			=> CLOCK,
						 FSYNC 			=> FSYNC,
						 RSYNC 			=> RSYNC,
						 DATA_IN 		=> DATA_OUT2,
						 DATA_BUFFER 	=> DATA_OUT3);

		DATA_OUT1 <= DATA_IN;
		
END Behavior;