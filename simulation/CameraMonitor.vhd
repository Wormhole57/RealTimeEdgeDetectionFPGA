-- Import libraries
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE ieee.std_logic_unsigned.all;
USE std.textio.all;

-- Entity
ENTITY CameraMonitor IS
	GENERIC( ROWS_IN_BIT: 	INTEGER := 9;
				COLS_IN_BIT: 	INTEGER := 10;
				DATA_LEN: 		INTEGER := 8);
	PORT( CLOCK: 				IN 		STD_LOGIC;
			RESET:				IN 		STD_LOGIC;
			FSYNC_IN: 			IN 		STD_LOGIC;
			RSYNC_IN: 			IN 		STD_LOGIC;
			DATA_IN_B: 			IN 		STD_LOGIC_VECTOR(DATA_LEN-1 downto 0);
			DATA_IN_G: 			IN 		STD_LOGIC_VECTOR(DATA_LEN-1 downto 0);
			DATA_IN_R: 			IN 		STD_LOGIC_VECTOR(DATA_LEN-1 downto 0);
			NUM_COLS_OUT: 		OUT 		STD_LOGIC_VECTOR( (DATA_LEN*2)-1 downto 0 );
			NUM_ROWS_OUT: 		OUT 		STD_LOGIC_VECTOR( (DATA_LEN*2)-1 downto 0 );
			ACTUAL_COL_OUT: 	OUT 		STD_LOGIC_VECTOR( (DATA_LEN*2)-1 downto 0 );
			ACTUAL_ROW_OUT: 	OUT 		STD_LOGIC_VECTOR( (DATA_LEN*2)-1 downto 0 );
			FSYNC_OUT: 			OUT 		STD_LOGIC;
			RSYNC_OUT: 			OUT 		STD_LOGIC;
			DATA_OUT: 			OUT 		STD_LOGIC_VECTOR(DATA_LEN-1 downto 0));
END CameraMonitor;

-- Architecture
ARCHITECTURE Behavior OF CameraMonitor IS
	
	TYPE char_file IS FILE OF CHARACTER;
	
	FILE file_in:  char_file OPEN read_mode  IS "images/test.bmp";
	FILE file_out: char_file OPEN write_mode IS "results/test.bmp";
	
	BEGIN
		
		PROCESS(CLOCK, FSYNC_IN, RSYNC_IN)
			VARIABLE fsync: 			STD_LOGIC := '0';
			VARIABLE rsync: 			STD_LOGIC := '0';
			VARIABLE done: 			STD_LOGIC := '0';
			VARIABLE done_reset: 	STD_LOGIC := '0';
			
			VARIABLE char:				CHARACTER;
			VARIABLE tmp:				STD_LOGIC_VECTOR(DATA_LEN-1 downto 0);
			VARIABLE blue:				STD_LOGIC_VECTOR(DATA_LEN-1 downto 0);
			VARIABLE green:			STD_LOGIC_VECTOR(DATA_LEN-1 downto 0);
			VARIABLE red:				STD_LOGIC_VECTOR(DATA_LEN-1 downto 0);
			VARIABLE blue_weighted: UNSIGNED(DATA_LEN-1 downto 0);
			VARIABLE green_weighted:UNSIGNED(DATA_LEN-1 downto 0);
			VARIABLE red_weighted: 	UNSIGNED(DATA_LEN-1 downto 0);
			VARIABLE luma: 			STD_LOGIC_VECTOR(DATA_LEN-1 downto 0);
			
			VARIABLE num_cols:		STD_LOGIC_VECTOR( (DATA_LEN*2)-1 downto 0 );
			VARIABLE num_rows:		STD_LOGIC_VECTOR( (DATA_LEN*2)-1 downto 0 );
			VARIABLE colsCounter:	STD_LOGIC_VECTOR( (DATA_LEN*2)-1 downto 0 );
			VARIABLE rowsCounter:	STD_LOGIC_VECTOR( (DATA_LEN*2)-1 downto 0 );
			VARIABLE cnt:				INTEGER;
			
			BEGIN
				IF RESET = '1' THEN
					IF done_reset = '0'	THEN
						-- Reset outputs and counters
						DATA_OUT 	<= (others => 'X');
						RSYNC_OUT 	<= '0';
						FSYNC_OUT 	<= '0';
						num_cols 	:= (others => '0');
						num_rows 	:= (others => '0');
						colsCounter := (others => '0');
						rowsCounter := (others => '0');
						
						-- Copy header from input file to output file
						FOR i IN 0 TO 53 LOOP
							read(file_in, char);
							write(file_out, char);
							
							-- Extract relevant information from header...
							CASE i IS
								WHEN 18 => num_cols(  DATA_LEN-1    downto 0 ) 					:= STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS(char), DATA_LEN));
								WHEN 19 => num_cols( (DATA_LEN*2)-1 downto  DATA_LEN ) 		:= STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS(char), DATA_LEN));
								WHEN 22 => num_rows(  DATA_LEN-1    downto 0 ) 					:= STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS(char), DATA_LEN));
								WHEN 23 => num_rows( (DATA_LEN*2)-1 downto DATA_LEN ) 		:= STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS(char), DATA_LEN));
								WHEN others => null;
							END CASE;
						END LOOP;
						
						-- ...as image width and height
						NUM_COLS_OUT <= num_cols;
						NUM_ROWS_OUT <= num_rows;
						num_cols     := num_cols - 1;
						num_rows     := num_rows - 1;

						-- Prepare re-activation of output sync waves
						fsync := '1';
						rsync := '1';
						cnt	:= 10 ;
						done	:= '0';
						done_reset := '1';
					END IF;
				ELSIF rising_edge(CLOCK) THEN
					-- Update output sync waves
					RSYNC_OUT <= rsync;
					FSYNC_OUT <= fsync;
					
					IF rsync = '1' THEN
						
						IF done = '0' THEN
							IF NOT endfile(file_in) THEN
								-- Read color values
								read(file_in, char);
								blue  := STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS(char), DATA_LEN));
								read(file_in, char);
								green := STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS(char), DATA_LEN));
								read(file_in, char);
								red   := STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS(char), DATA_LEN));
								-- Conversion to gray value
								-- Fixed point approximation of luma from RGB
								-- ITU-R BT.2100 from en.wikipedia.org/wiki/Grayscale
								-- Y = 0.2627R + 0.6780G + 0.0593B
								red_weighted   := UNSIGNED("00"  & blue(7 downto 2));
								green_weighted := UNSIGNED("0"  & green(7 downto 1));
								blue_weighted  := UNSIGNED("0000" & red(7 downto 4));
								luma  := STD_LOGIC_VECTOR(blue_weighted + green_weighted + red_weighted);
							ELSE
								-- DEBUG: if file ends prematurely, consider remaining pixels black
								luma  := (others => '0');
							END IF;
							DATA_OUT	<= luma;
							
							-- Update counters
							ACTUAL_COL_OUT <= colsCounter;
							ACTUAL_ROW_OUT <= rowsCounter;
						END IF;
						
						IF colsCounter = num_cols THEN
							-- Reset column counter
							colsCounter := (others => '0');
							-- Prepare output rsync to go low
							rsync			:= '0';
							IF rowsCounter = num_rows THEN
								-- Close input file
								file_close(file_in);
								-- Reset row counter
								rowsCounter := (others => '0');
								-- Prepare output fsync to go low
								fsync			:= '0';
								done			:= '1';
								done_reset 	:= '0';
							ELSE
								-- Increment row counter
								rowsCounter := rowsCounter + 1;
							END IF;
						ELSE
							-- Increment column counter
							colsCounter := colsCounter + 1;
						END IF;
						
					ELSE
						
						-- Reset output
						DATA_OUT <= (others => 'X');
						
						-- Handle re-activation of output rsync
						-- (and fsync if frame has not been displayed entirely)
						IF done = '0' THEN
							IF cnt > 1 THEN
								cnt := cnt - 1;
							ELSE
								cnt := 10;
								rsync := '1';
								fsync := '1';
							END IF;
						ELSE
							IF cnt > 1 THEN
								cnt := cnt - 1;
							ELSE
								cnt := 10;
								rsync := '1';
							END IF;
						END IF;
						
					END IF;
					
					-- Write gray scale pixels on output image
					IF FSYNC_IN = '1' THEN
						IF RSYNC_IN = '1' THEN
							write(file_out, CHARACTER'VAL(TO_INTEGER(UNSIGNED(DATA_IN_B))));
							write(file_out, CHARACTER'VAL(TO_INTEGER(UNSIGNED(DATA_IN_G))));
							write(file_out, CHARACTER'VAL(TO_INTEGER(UNSIGNED(DATA_IN_R))));
						END IF;
					END IF;
				END IF;
		END PROCESS;
END Behavior;