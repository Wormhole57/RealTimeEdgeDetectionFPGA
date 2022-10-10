-- Import libraries
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE ieee.std_logic_unsigned.all;

-- Entity
ENTITY SobelKernel IS
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
END SobelKernel;

-- Architecture
ARCHITECTURE Behavior OF SobelKernel IS
	
	CONSTANT N: INTEGER := DATA_LEN + 3;	
	
	BEGIN
		
		-- Perform Sobel edge detection for each input pixel
		sobel_edge_detection: PROCESS(CLOCK, FSYNC_IN, RSYNC_IN)
		
			VARIABLE x_derivate, y_derivate, gradient_magnitude:	STD_LOGIC_VECTOR(N-1 downto 0);
			
			BEGIN
				IF rising_edge(CLOCK) THEN
					-- Update output sync waves
					RSYNC_OUT <= RSYNC_IN;
					FSYNC_OUT <= FSYNC_IN;
					
					IF FSYNC_IN = '1' THEN
						IF RSYNC_IN = '1' THEN
							-- Sobel approssimation for first x-derivate of grayscale transition:
							-- |--------------|     |--------------|
							-- | z1 | z2 | z3 |     | -1 |  0 | +1 |
							-- |--------------|     |--------------|
							-- | z4 | z5 | z6 | (*) | -k |  0 | +k | => f'x = (z3 + k*z6 + z9) - (z1 + k*z4 + z7)
							-- |--------------|     |--------------|
							-- | z7 | z8 | z9 |     | -1 |  0 | +1 |
							-- |--------------|     |--------------|
							
							-- k = 2
							x_derivate := ("000" & DATA_IN3) + ("00" & DATA_IN6 & '0') + ("000" & DATA_IN9) - ("000" & DATA_IN1) - ("00" & DATA_IN4 & '0') - ("000" & DATA_IN7);
							-- OR
							-- k = 4
							--x_derivate := ("000" & DATA_IN3) + ('0' & DATA_IN6 & "00") + ("000" & DATA_IN9) - ("000" & DATA_IN1) - ('0' & DATA_IN4 & "00") - ("000" & DATA_IN7);
							-- k = 1
							--x_derivate := ("000" & DATA_IN3) + ("000" & DATA_IN6) + ("000" & DATA_IN9) - ("000" & DATA_IN1) - ("000" & DATA_IN4) - ("000" & DATA_IN7);
							
							-- Sobel approssimation for first y-derivate of grayscale transition:
							-- |--------------|     |--------------|
							-- | z1 | z2 | z3 |     | -1 | -k | -1 |
							-- |--------------|     |--------------|
							-- | z4 | z5 | z6 | (*) |  0 |  0 |  0 | => f'y = (z7 + k*z8 + z9) - (z1 + k*z2 + z3)
							-- |--------------|     |--------------|
							-- | z7 | z8 | z9 |     | +1 | +k | +1 |
							-- |--------------|     |--------------|
							
							-- k = 2
							y_derivate := ("000" & DATA_IN7) + ("00" & DATA_IN8 & '0') + ("000" & DATA_IN9) - ("000" & DATA_IN1) - ("00" & DATA_IN2 & '0') - ("000" & DATA_IN3);
							-- OR
							-- k = 4
							--y_derivate := ("000" & DATA_IN7) + ('0' & DATA_IN8 & "00") + ("000" & DATA_IN9) - ("000" & DATA_IN1) - ('0' & DATA_IN2 & "00") - ("000" & DATA_IN3);
							-- K = 1
							--y_derivate := ("000" & DATA_IN7) + ("000" & DATA_IN8) + ("000" & DATA_IN9) - ("000" & DATA_IN1) - ("000" & DATA_IN2) - ("000" & DATA_IN3);
							
							-- Approssimation for magnitude of gradient vector:
							-- grad(f) = [f'x ; f'y]  =>  mag(grad(f)) = sqrt( f'x^2 + f'y^2 )  =>  mag(grad(f)) = |f'x| + |f'y|
							IF x_derivate(N-1) = '1' THEN
								x_derivate := NOT x_derivate + 1; -- Complement C2
							END IF;
							IF y_derivate(N-1) = '1' THEN
								y_derivate := NOT y_derivate + 1; -- Complement C2
							END IF;
							gradient_magnitude := x_derivate + y_derivate;
							
							-- Edge pixel: if magnitude > chosen threshold
							IF gradient_magnitude > STD_LOGIC_VECTOR(TO_UNSIGNED(127, N)) THEN
								-- Edge pixels will be white
								DATA_OUT <= (others => '1');
							ELSE
								-- Other pixels will take their color from the last 8 BITS of the magnitude
								--DATA_OUT <= gradient_magnitude(DATA_LEN-1 downto 0);
								-- OR
								-- Will be black
								DATA_OUT <= "00000000";
							END IF;
						END IF;
					END IF;
				END IF;
		END PROCESS sobel_edge_detection;
END Behavior;