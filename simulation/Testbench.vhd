-- Import libraries
LIBRARY ieee;
USE ieee.STD_LOGIC_1164.all;
USE std.env.finish;

-- Entity
ENTITY Testbench IS
	GENERIC( DATA_LEN: INTEGER := 8);
END Testbench;

-- Architecture
ARCHITECTURE Simulation OF Testbench IS

	-- Inputs
    SIGNAL clock: 		STD_LOGIC 										:= '1';
    SIGNAL fsync_in: 	STD_LOGIC 										:= '0';
    SIGNAL rsync_in: 	STD_LOGIC 										:= '0';
    SIGNAL data_in:  	STD_LOGIC_VECTOR(DATA_LEN-1 downto 0) 	:= (others => '0');
	SIGNAL reset: 		STD_LOGIC 										:= '0';

    -- Outputs
    SIGNAL fsync_out: STD_LOGIC;
    SIGNAL rsync_out:	STD_LOGIC;
    SIGNAL data_out: 	STD_LOGIC_VECTOR(DATA_LEN-1 downto 0);

    -- Clock period definitions
	-- T_clock = 40 ns  <==>  f_clock = 25 MHz
    CONSTANT half_period: TIME := 20 ns;
	
	-- Counter signals
	SIGNAL num_cols_in: 		STD_LOGIC_VECTOR( (DATA_LEN*2)-1 downto 0 );
	SIGNAL num_rows_in: 		STD_LOGIC_VECTOR( (DATA_LEN*2)-1 downto 0 );
	SIGNAL actual_col_in:  	STD_LOGIC_VECTOR( (DATA_LEN*2)-1 downto 0 );
	SIGNAL actual_row_in:  	STD_LOGIC_VECTOR( (DATA_LEN*2)-1 downto 0 );
	
	-- Components
	COMPONENT EdgeDetector
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
	END COMPONENT;
	
	BEGIN
		
		-- Instantiate the Device Under Test (DUT)
		uut: EdgeDetector
			PORT MAP( 	CLOCK 			=> clock,
							FSYNC_IN 		=> fsync_in,
							RSYNC_IN 		=> rsync_in,
							DATA_IN 			=> data_in,
							FSYNC_OUT 		=> fsync_out,
							RSYNC_OUT 		=> rsync_out,
							DATA_OUT_B 		=> data_out,
							DATA_OUT_G 		=> data_out,
							DATA_OUT_R		=> data_out);
		
		-- Instantiate the input-output simulated periferical
		camera_and_monitor: entity work.CameraMonitor
			PORT MAP( 	CLOCK		 		=> clock,
							RESET		 		=> reset,
							FSYNC_IN 		=> fsync_out,
							RSYNC_IN 		=> rsync_out,
							DATA_IN_B		=> data_out,
							DATA_IN_G 		=> data_out,
							DATA_IN_R		=> data_out,
							NUM_COLS_OUT 	=> num_cols_in,
							NUM_ROWS_OUT 	=> num_rows_in,
							ACTUAL_COL_OUT => actual_col_in,
							ACTUAL_ROW_OUT => actual_row_in,
							FSYNC_OUT 		=> fsync_in,
							RSYNC_OUT 		=> rsync_in,
							DATA_OUT 		=> data_in);
		
		-- Pixel clock generation
		clock_generation: PROCESS(clock)
			BEGIN
				IF clock = '1' THEN
					clock <= '0' AFTER half_period, '1' AFTER 2*half_period;
				END IF;
		END PROCESS clock_generation;
		
		-- This little delay let CameraMonitor read the BMP file header
		reset <= '1', '0' AFTER 60 ns;
		
		-- The simulation stops after the image is converted
		PROCESS
			BEGIN
				-- Minimum time requested = (640+10)*480+60 = 12480000 ns
				WAIT FOR 12506000 ns;
				finish;
		END PROCESS;

END Simulation;
