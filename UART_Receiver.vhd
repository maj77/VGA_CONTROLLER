-------------------------------------------------------------------------------
--
-- Title       : UART_Receiver
-- Design      : VGA
-- Author      : Marcin Maj
-- Company     : AGH Krakow
--
-------------------------------------------------------------------------------
--
-- Description : 
-- Uart Receiver  
-- 38400 bps
-- 8 data bits, 1 stop bit, 0 parity bits
--
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_unsigned.all;	
use IEEE.numeric_std.all;

entity UART_RX is 
	generic (
			DATA_LEN : INTEGER := 8;
			CLKS_PER_BIT : INTEGER := 2604	   -- powinno byc 2604
		); 
																  											   
	port (
		CLK         	: in  STD_LOGIC;  							-- input clock
		RX_BIT      	: in  STD_LOGIC;  							-- serial data in	 
		w_COL	  	: out STD_LOGIC_VECTOR(7 downto 0);
		w_ROW 		: out STD_LOGIC_VECTOR(7 downto 0);	 
		w_EN		: out STD_LOGIC;
		Q		: out STD_LOGIC_VECTOR(DATA_LEN-1 downto 0) -- parallel data out
		);
end UART_RX;


architecture UART_RX of UART_RX is	
	
	--- INTERNAL SIGNALS ---	
	type RX_STATE is(IDLE,
			START_BIT,
			DATA_BITS,
			STOP_BIT,
			SEND,
			NEXT_ADDR);
				
	
	-- signal representing states	--
	signal 	 STATE 	: RX_STATE := IDLE; 	   
	
	-- sampling signals --
	signal 	 CLK_COUNTER  : INTEGER := 0;	
	constant CLK_HALF_BIT : INTEGER := CLKS_PER_BIT / 2;	-- after 2604 clock ticks hit in half of data bit (for 38400 baud rate)
	
	-- serial to paraller signals --
	signal BIT_INDEX : INTEGER range 0 to DATA_LEN-1 := 0; 
	signal RX_DATA	 : STD_LOGIC_VECTOR(DATA_LEN-1 downto 0) := (others => '0'); 	   
	
	-- memory address signals --
	signal ROW : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
	signal COL : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
begin
	
	process(CLK) 	
	begin
	if CLK'event and CLK = '1' then
		case STATE is
			
			--- idle state ---
			when IDLE =>
			w_EN <= '0';
			CLK_COUNTER <= 0;
			if RX_BIT = '0' then
				STATE <= START_BIT;
			end if;
			
			--- start bit ---
			when START_BIT =>
			if CLK_COUNTER < CLK_HALF_BIT then	 -- wait till half of start bit
				CLK_COUNTER <= CLK_COUNTER + 1;	 
			else
				if RX_BIT = '0' then -- in half of start bit
					CLK_COUNTER <= 0;
					STATE <= DATA_BITS;
				else
					STATE <= IDLE;
				end if;
			end if;
			
			--- read data bits ---
			when DATA_BITS => 
			if CLK_COUNTER < CLKS_PER_BIT then  -- wait till half of start bit
				CLK_COUNTER <= CLK_COUNTER + 1;
			else
				RX_DATA(BIT_INDEX) <= RX_BIT;
				CLK_COUNTER <= 0;	  
				
				if BIT_INDEX = DATA_LEN-1 then
					BIT_INDEX <= 0;
					STATE <= STOP_BIT;
				else
					BIT_INDEX <= BIT_INDEX + 1;
				end if;			 
			end if;
				
			--- stop bit ---
			when STOP_BIT =>
			if CLK_COUNTER < CLK_HALF_BIT then  -- wait till half of start bit
				CLK_COUNTER <= CLK_COUNTER + 1;
			else
				if RX_BIT = '1' then
					CLK_COUNTER <= 0;
					STATE <= SEND;
				end if;
			end if;	 
			
			when SEND =>	 
				w_EN <= '1';	   
				if CLK_COUNTER < CLK_HALF_BIT then  -- wait till half of start bit
					CLK_COUNTER <= CLK_COUNTER + 1;
				else	
					CLK_COUNTER <= 0; 
					STATE <= NEXT_ADDR;	 
				end if;					
				
			
			when NEXT_ADDR =>
			if ROW < 120 then
				if COL < 160 then
					COL <= COL + 1; 
				else 
					COL <= (others => '0');
					ROW <= ROW + 1;
				end if;
			else
				ROW <= (others => '0');
			end if;	 
			STATE <= IDLE;			
		end case;		
		
	end if;
	end process;   
	
	Q <= RX_DATA when STATE = SEND;
	w_COL <= COL when STATE = SEND;
	w_ROW <= ROW when STATE = SEND;
	
end UART_RX;
