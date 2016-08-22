LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.all;
USE IEEE.STD_LOGIC_UNSIGNED.all;
USE IEEE.STD_LOGIC_ARITH.all;
LIBRARY work;
USE work.up3core.all;

ENTITY ElevadoresFinal IS
	PORT (
		Clock_48Mhz, Reset, Keyboard_clk, Keyboard_data		: IN STD_LOGIC;
		VGA_red, VGA_green, VGA_blue, VGA_Hsync, VGA_Vsync	: OUT STD_LOGIC
	);
END ElevadoresFinal;

ARCHITECTURE Controle OF ElevadoresFinal IS
	-- controle de sinais dos elevadores
	TYPE CallBuffer IS ARRAY (1 TO 15) OF INTEGER RANGE 0 TO 15;
	signal ARR_DESTINOS_SIG : CallBuffer;
	SIGNAL C_orig							: INTEGER RANGE 0 TO 15;
	SIGNAL C_dest							: INTEGER RANGE 0 TO 15;
	SIGNAL E1_pos, E2_pos, E3_pos			: INTEGER RANGE 1 TO 15;
	SIGNAL E1_load, E2_load, E3_load		: INTEGER RANGE 0 TO 15;
	-- controle de sinais (video and keyboard)
	SIGNAL E1_on, E2_on, E3_on				: STD_LOGIC;
	SIGNAL E1char_on, E2char_on, E3char_on	: STD_LOGIC;
	SIGNAL Floor_on, Floor_Char_on			: STD_LOGIC;
	SIGNAL Call_on, Call_Char_on			: STD_LOGIC;
	SIGNAL E1_motion, E2_motion, E3_motion	: INTEGER RANGE -8 TO 7;
	SIGNAL red, green, blue, vsync			: STD_LOGIC;
	SIGNAL pix_row, pix_col					: STD_LOGIC_VECTOR(9 DOWNTO 0);
	SIGNAL pix_X, pix_Y						: INTEGER RANGE 0 TO 1023;
	SIGNAL button_read						: STD_LOGIC;
	SIGNAL button, pix_floor				: INTEGER RANGE 0 TO 15;
	SIGNAL btn_buff							: STD_LOGIC_VECTOR(5 DOWNTO 0);
	SIGNAL ve1_dest_sig, ve2_dest_sig, ve3_dest_sig: integer range 0 to 15;
	SIGNAL endChamada : STD_LOGIC_VECTOR(5 DOWNTO 0);
	SIGNAL andarPos : INTEGER RANGE 0 TO 15;
	COMPONENT ReadKeyboard
		PORT (
			clock_48Mhz, reset			: IN std_logic;
			keyboard_clk, keyboard_data	: IN std_logic;
			button_read					: IN std_logic;
			button						: OUT INTEGER RANGE 0 TO 15
		);
	END COMPONENT;	
BEGIN
	-- Connect components
	Comp_VGA_sync: VGA_sync
		PORT MAP (
			clock_48Mhz => Clock_48Mhz, 
			red => red, green => green, blue => blue,	
    	    red_out => VGA_red, green_out => VGA_green, blue_out => VGA_blue,
			horiz_sync_out => VGA_Hsync, vert_sync_out => vsync,
			pixel_row => pix_row, pixel_column => pix_col
		);
	Floor_Char: char_rom
		PORT MAP (
			clock => Clock_48Mhz,
			character_address => "11" & not(pix_row(8 downto 5)),
			font_row => pix_row(3 downto 1), font_col => pix_col(3 downto 1),
			rom_mux_output => Floor_Char_on
		);
	Call_Char: char_rom
		PORT MAP (
			clock => Clock_48Mhz,
			--character_address => btn_buff,
			character_address => endChamada,
			font_row => pix_row(3 downto 1), font_col => pix_col(3 downto 1),
			rom_mux_output => Call_Char_on
		);
	E1char: char_rom
		PORT MAP (
			clock => Clock_48Mhz,
			character_address => "11" & CONV_STD_LOGIC_VECTOR(E1_load, 4),
			font_row => pix_row(3 downto 1), font_col => pix_col(3 downto 1),
			rom_mux_output => E1char_on
		);
		E2char: char_rom
		PORT MAP (
			clock => Clock_48Mhz,
			character_address => "11" & CONV_STD_LOGIC_VECTOR(E2_load, 4),
			font_row => pix_row(3 downto 1), font_col => pix_col(3 downto 1),
			rom_mux_output => E2char_on
		);
		E3char: char_rom
		PORT MAP (
			clock => Clock_48Mhz,
			character_address => "11" & CONV_STD_LOGIC_VECTOR(E3_load, 4),
			font_row => pix_row(3 downto 1), font_col => pix_col(3 downto 1),
			rom_mux_output => E3char_on
		);
	Comp_ReadKeyboard: ReadKeyboard
		PORT MAP (
			clock_48Mhz=>clock_48Mhz, reset=>reset,
			keyboard_clk => keyboard_clk, keyboard_data => keyboard_data,
			button_read => button_read, button => button
		);	


	-- Generate video signals
	red <= Call_on;
	green <= (E1char_on AND E1_on) OR (E2char_on AND E2_on) OR (E3char_on AND E3_on) OR Floor_on;
	blue <=	E1_on OR E2_on OR E3_on;
	VGA_Vsync <= vsync;
	pix_X <= CONV_INTEGER(pix_col);
	pix_Y <= CONV_INTEGER(pix_row);
	andarPos <= (480-pix_Y)/32 + 1;
	endChamada <= "101010" WHEN C_orig=andarPos ELSE "11" & CONV_STD_LOGIC_VECTOR(ARR_DESTINOS_SIG(andarPos), 4);
	
	
	pix_floor <= 15-(pix_Y/32);
	
	btn_buff <= "11" & CONV_STD_LOGIC_VECTOR(ARR_DESTINOS_SIG(pix_floor), 4);

	Read_Keyboard: PROCESS (button)
	BEGIN
	    
	    --if (Clock_48Mhz'event) and (Clock_48Mhz = '1') then	    
			
		--end if;
	    
	    --Floor_on <= Floor_Char_on;
	END PROCESS Read_Keyboard;
	
	

	-- Draw floor numbers
	Draw_Floors: PROCESS (pix_col, pix_row)
	BEGIN
		IF pix_X>=64 AND pix_X<80 AND pix_row(4)='0' THEN
			Floor_on <= Floor_Char_on;
	 	ELSE
	 		Floor_on <= '0';
		END IF;	
	END PROCESS Draw_Floors;
	
	

	-- Draw call numbers
	Draw_Calls: PROCESS (pix_col, pix_row)	
	BEGIN
		--IF pix_X<16 AND pix_row(4)='0' AND (bufs(andarPos)/=0 OR C_orig=andarPos) THEN
		IF pix_X<16 AND pix_row(4)='0' and (ARR_DESTINOS_SIG(andarPos)/=0 OR C_orig=andarPos) THEN
			Call_on <= Call_Char_on;
			
	 	ELSE
	 		Call_on <= '0';
		END IF;
	END PROCESS Draw_Calls;

	-- Draw elevators
	Draw_Elevators: PROCESS (pix_col, pix_row)
		VARIABLE X, Y:	INTEGER RANGE -1024 TO 1023;
	BEGIN
		X := 128;		--> E1
		Y := 480-32*E1_pos;
		IF pix_X>=X AND pix_X<X+16 AND pix_Y>=Y AND pix_Y<Y+16 THEN
			E1_on <= '1';
	 	ELSE
	 		E1_on <= '0';
		END IF;
		X := 192;		--> E2
		Y := 480-32*E2_pos;
		IF pix_X>=X AND pix_X<X+16 AND pix_Y>=Y AND pix_Y<Y+16 THEN
			E2_on <= '1';
	 	ELSE
	 		E2_on <= '0';
		END IF;
		X := 256;		--> E3
		Y := 480-32*E3_pos;
		IF pix_X>=X AND pix_X<X+16 AND pix_Y>=Y AND pix_Y<Y+16 THEN
			E3_on <= '1';
	 	ELSE
	 		E3_on <= '0';
		END IF;
	END PROCESS Draw_Elevators;

	-- Move elevadores
	MoverElevadores: PROCESS
		VARIABLE count			: integer range 0 to 60 := 0;
		variable halt 			:  boolean;
		variable button_buff	: INTEGER RANGE 0 TO 15 := 0; 
		variable ARR_DESTINOS : CallBuffer;
		
		variable E1_ocupado : boolean;
		variable E2_ocupado : boolean;
		variable E3_ocupado : boolean;
	
		variable c: integer;
		variable ve1_orig, ve2_orig, ve3_orig: integer range 0 to 15;
		variable ve1_dest, ve2_dest, ve3_dest: integer range 0 to 15;	
		variable ve1_pos, ve2_pos, ve3_pos: integer range 0 to 15;
		variable ve1_load, ve2_load, ve3_load: integer range 0 to 15;			
	BEGIN
		WAIT UNTIL vsync='1';
		
		IF reset = '0' THEN
			halt := false;
			E1_ocupado := false;
			E2_ocupado := false;
			E3_ocupado := false;
				
			ve1_pos := 1;
			ve2_pos := 1;
			ve3_pos := 1;
				
			ve1_dest := 0;
			ve2_dest := 0;
			ve3_dest := 0;
				
			ve1_load := 0;
			ve2_load := 0;
			ve3_load := 0;
			
			ve1_dest_sig <= 0;
			ve2_dest_sig <= 0;
			ve3_dest_sig <= 0;			
			
			for c in 1 to 15 loop
				ARR_DESTINOS(c) := 0;
				ARR_DESTINOS_SIG(c) <= 0;
			end loop;			
		END IF;
		count := count+1;
		IF count>=30 THEN	-- FREQUENCIA = vsync/30 = 2Hz
			count := 0;		
			button_read <= '0';
								
			if (c_dest /= 0) then				
				c_orig <= 0;
				c_dest <= 0;								
			end if;
			
			if (button /= 0) then
				button_read <= '1';
				
				if (c_orig = 0) then
					c_orig <= button;					
					halt := true;
				else
					ARR_DESTINOS(c_orig) := button;
					ARR_DESTINOS_SIG(c_orig) <= button;
					c_dest <= button;					
					halt := false;
					
				end if;
			end if;			
							
			If (halt = false) then
			
----------------------------------------------------------------------------------------------------------
			
			if (E1_ocupado = false) then				
				for c in 1 to 15 loop
					if ARR_DESTINOS(c) /= 0 then																
						ve1_dest := c;	
						ve1_orig := ARR_DESTINOS(c);
						ARR_DESTINOS(c) := 0;
						E1_ocupado := true;
						exit;
					end if;
				end loop;			
			end if;
			
			if (E2_ocupado = false) then
				for c in 1 to 15 loop
					if ARR_DESTINOS(c) /= 0 then																
						ve2_dest := c;						
						ve2_orig := ARR_DESTINOS(c);
						ARR_DESTINOS(c) := 0;
						E2_ocupado := true;
						exit;
					end if;
				end loop;
			end if;
			
			if (E3_ocupado = false) then				
				for c in 1 to 15 loop
					if ARR_DESTINOS(c) /= 0 then																
						ve3_dest := c;			
						ve3_orig := ARR_DESTINOS(c);
						ARR_DESTINOS(c) := 0;
						E3_ocupado := true;
						exit;
					end if;
				end loop;
			end if;			
			
			if (ve1_dest /= 0) then
				if (ve1_pos < ve1_dest) then
					ve1_pos := ve1_pos + 1;
				elsif (ve1_pos > ve1_dest) then
					ve1_pos := ve1_pos - 1;
				else
					if(ve1_load = 0)then
						ve1_load := ve1_pos;
						ve1_dest := ve1_orig;
						ARR_DESTINOS_SIG(ve1_pos) <= 0;
					else
						ARR_DESTINOS_SIG(ve1_pos) <= 0;
						ve1_load := 0;
						ve1_orig := 0;
						ve1_dest := 0;
						
						E1_ocupado := false;
					end if;
				end if;	
			end if;
			
			if (ve2_dest /= 0) then
				if (ve2_pos < ve2_dest) then
					ve2_pos := ve2_pos + 1;
				elsif (ve2_pos > ve2_dest) then
					ve2_pos := ve2_pos - 1;
				else
					if(ve2_load = 0)then
						ve2_load := ve2_pos;
						ve2_dest := ve2_orig;
						ARR_DESTINOS_SIG(ve2_pos) <= 0;
					else
						ARR_DESTINOS_SIG(ve2_pos) <= 0;
						ve2_load := 0;
						ve2_orig := 0;
						ve2_dest := 0;
						E2_ocupado := false;
					end if;
				end if;	
			end if;
			
			if (ve3_dest /= 0) then
				if (ve3_pos < ve3_dest) then
					ve3_pos := ve3_pos + 1;
				elsif (ve3_pos > ve3_dest) then
					ve3_pos := ve3_pos - 1;
				else
					if(ve3_load = 0)then
						ve3_load := ve3_pos;
						ve3_dest := ve3_orig;
						ARR_DESTINOS_SIG(ve3_pos) <= 0;
					else
						ARR_DESTINOS_SIG(ve3_pos) <= 0;
						ve3_load := 0;
						ve3_orig := 0;
						ve3_dest := 0;
						E3_ocupado := false;
					end if;
				end if;	
			end if;
			
----------------------------------------------------------------------------------------------------------
			
			end if;
			
			--ARR_DESTINOS_SIG <= ARR_DESTINOS;
			E1_pos <= ve1_pos;
			E2_pos <= ve2_pos;
			E3_pos <= ve3_pos;
		
			E1_load <= ve1_load;
			E2_load <= ve2_load;
			E3_load <= ve3_load;
			
		END IF;				-- fim 2Hz
	END PROCESS MoverElevadores;

END Controle;
