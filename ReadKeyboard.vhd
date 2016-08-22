LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE IEEE.STD_LOGIC_UNSIGNED.all;
LIBRARY work;
USE work.up3core.all;

ENTITY ReadKeyboard IS
	PORT (
		clock_48Mhz, reset			: IN std_logic;
		keyboard_clk, keyboard_data	: IN std_logic;
		button_read					: IN std_logic;
		button						: OUT INTEGER RANGE 0 TO 15
	);
END ReadKeyboard;

ARCHITECTURE behavior OF ReadKeyboard IS
	TYPE STATE_TYPE IS (wait_ready, read_data, read_low);
	SIGNAL state					: STATE_TYPE;
	SIGNAL fifo						: STD_LOGIC_VECTOR(39 DOWNTO 0);
	SIGNAL scan_read, scan_ready	: STD_LOGIC;
	SIGNAL scan_code				: STD_LOGIC_VECTOR(7 DOWNTO 0);
BEGIN
	Comp_keyboard: keyboard
		PORT MAP (
			keyboard_clk => keyboard_clk, keyboard_data => keyboard_data,
			clock_48Mhz => Clock_48Mhz,	reset => reset, read => scan_read,
			scan_code => scan_code, scan_ready => scan_ready
		);
	PROCESS (scan_ready, reset, clock_48Mhz)
	BEGIN
		IF reset <= '0' THEN
			state <= read_low;
			fifo <= X"00_00_00_00_00";
		ELSIF (clock_48Mhz'EVENT) AND clock_48Mhz='1' THEN
			IF button_read = '1' THEN
				button <= 0;
			END IF;
			CASE state IS 
			WHEN read_low =>
				scan_read <= '0';
				IF fifo(15 DOWNTO 8)=X"F0" THEN	-- It´s a BREAK code
					CASE fifo(7 DOWNTO 0) is
						WHEN X"16" => button <= 1;
						WHEN X"1E" => button <= 2;
						WHEN X"26" => button <= 3;
						WHEN X"25" => button <= 4;
						WHEN X"2E" => button <= 5;
						WHEN X"36" => button <= 6;
						WHEN X"3D" => button <= 7;
						WHEN X"3E" => button <= 8;
						WHEN X"46" => button <= 9;
						WHEN X"1C" => button <= 10;
						WHEN X"32" => button <= 11;
						WHEN X"21" => button <= 12;
						WHEN X"23" => button <= 13;
						WHEN X"24" => button <= 14;
						WHEN X"2B" => button <= 15;
						WHEN OTHERS => button <= 0;
					END CASE;
				END IF;
				state <= wait_ready;
			WHEN wait_ready =>
				IF scan_ready = '1' THEN
					scan_read <= '1';
					state <= read_data;
				ELSE
					state <= wait_ready;
				END IF;
			WHEN read_data =>
				fifo <= fifo(31 DOWNTO 0) & scan_code;
				state <= read_low;
			END CASE;
		END IF;
	END PROCESS;  
END behavior;
