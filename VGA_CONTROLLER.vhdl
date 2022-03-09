-------------------------------------------------------------------------------
--
-- Title       : VGA controller
-- Design      : VGA
-- Author      : Marcin Maj
-- Company     : AGH Kraków
--
-------------------------------------------------------------------------------
--
-- Description : 
-- VGA driver for 800x600 @60Hz	vide/image		
-- 	
-- http://tinyvga.com/vga-timing/800x600@60Hz
-------------------------------------------------------------------------------	

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_unsigned.all;

entity VGA_CONTROLLER is
	
	generic(
		------- HORIZONTAL PUlSE WIDTH VALUES --------
		H_PIXELS			: INTEGER := 640;	-- visible area
		H_FRONT_PORCH		: INTEGER := 16;
		H_SYNC_PULSE		: INTEGER := 96;	
		H_BACK_PORCH		: INTEGER := 48;	 
		H_SYNC_POLARITY		: STD_LOGIC := '0';		-- polarity of horizontal sync pulse
		
		------- VERTICAL PUlSE WIDTH VALUES --------
		V_PIXELS			: INTEGER := 480;	-- visible area
		V_FRONT_PORCH		: INTEGER := 10;
		V_SYNC_PULSE		: INTEGER := 2;
		V_BACK_PORCH		: INTEGER := 33;
		V_SYNC_POLARITY		: STD_LOGIC := '0'	    	-- polarity of vertical sync pulse
		); 	
	
	port(
		------- PORT DECLARATIONS --------
		CLK			: in STD_LOGIC;											-- increments over every pixel
		RESET		: in STD_LOGIC;	 											-- asynchronous reset active low  
		CE			: in STD_LOGIC;
		H_SYNC		: out STD_LOGIC;											-- horizontal sync signal
		V_SYNC		: out STD_LOGIC;											-- vertical sync signal
		DISP_EN		: out STD_LOGIC;											-- display enable
		COL			: out STD_LOGIC_VECTOR(9 downto 0) := (others => '0');		-- horizontal pixel coordinate
		ROW			: out STD_LOGIC_VECTOR(9 downto 0) := (others => '0')		-- vertical pixel coordinate
		);
end VGA_CONTROLLER;

architecture VGA_CONTROLLER of VGA_CONTROLLER is
	constant H_PERIOD : INTEGER := H_SYNC_PULSE + H_BACK_PORCH + H_PIXELS + H_FRONT_PORCH;  -- number of clocks for one row
	constant V_PERIOD : INTEGER := V_SYNC_PULSE + V_BACK_PORCH + V_PIXELS + V_FRONT_PORCH;  -- number of rows in column	 
	
	signal H_COUNT : STD_LOGIC_VECTOR (9 downto 0) := "0000000000";
	signal V_COUNT : STD_LOGIC_VECTOR (9 downto 0) := "0000000000";
	
begin
	
	process(CLK, RESET)
		--variable H_COUNT : INTEGER range 0 to H_PERIOD - 1 := 0; -- counts columns
		--variable V_COUNT : INTEGER range 0 to V_PERIOD - 1 := 0; -- counts rows
	begin
		if RESET = '1' then    			    --reset asserted
			H_COUNT <= (others => '0');         --reset horizontal counter
			V_COUNT <= (others => '0');         --reset vertical counter
			H_SYNC <= not H_SYNC_POLARITY;      --deassert horizontal sync
			V_SYNC <= not V_SYNC_POLARITY;      --deassert vertical sync
			DISP_EN <= '0';          	    --disable display
			COL <= (others => '0');             --reset column pixel coordinate
			ROW <= (others => '0');             --reset row pixel coordinate
			
		elsif CLK'event and CLK = '1' then
			if CE = '1'  then
				---- counters ----
				if H_COUNT < H_PERIOD - 1 then 		-- horizontal counter - incremented every 25ns
					H_COUNT <= H_COUNT + 1;
				else
					H_COUNT <= (others => '0'); 
					if V_COUNT < V_PERIOD - 1 then	-- vertical counter - incremented every 26.4us
						V_COUNT <= V_COUNT + 1;
					else
						V_COUNT <= (others => '0'); 
					end if;	-- vertical counter
				end if;	-- horizontal counter
				
				
				---- horizontal sync signal ----
				if H_COUNT < H_PIXELS + H_FRONT_PORCH or H_COUNT >= H_PIXELS + H_FRONT_PORCH + H_SYNC_PULSE then  -- check if horizontal counter signal is out of horizontal sync range
					H_SYNC <= not H_SYNC_POLARITY;	  		-- disable horizontal sync pulse
				else
					H_SYNC <= H_SYNC_POLARITY;			-- enable horizontal sync pulse
				end if;	-- horizontal sync signal
				
				
				---- vertical sync signal ----
				if V_COUNT < V_PIXELS + V_FRONT_PORCH or V_COUNT >= V_PIXELS + V_FRONT_PORCH + V_SYNC_PULSE then   -- check if vertical counter signal is out of vertical sync range
					V_SYNC <= not V_SYNC_POLARITY;			-- disable vertical sync pulse
				else
					V_SYNC <= V_SYNC_POLARITY;		  	-- enable vertical sync pulse
				end if; -- vertical sync signal		   	
				
				
				---- set pixel coordinates ----
				if H_COUNT < H_PIXELS then	-- horizontal time
					COL <= H_COUNT;		-- set horizontal pixel coordinates
				end if;
				if V_COUNT < V_PIXELS then
					ROW <= V_COUNT;
				end if;
				
				
				---- display enable ----
				if H_COUNT < H_PIXELS and V_COUNT < V_PIXELS then	-- in display area
					DISP_EN <= '1';
				else
					DISP_EN <= '0';		-- outside display area
				end if;		
				
			end if;	-- CE
		end if;	-- CLK/RESET	   	  
	end process; 
	
end VGA_CONTROLLER;
