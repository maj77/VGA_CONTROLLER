-------------------------------------------------------------------------------
--
-- Title       : Image generator for VGA
-- Design      : VGA
-- Author      : Marcin Maj
-- Company     : AGH Kraków
--
-------------------------------------------------------------------------------
--
-- Description : 
-- generates image 640x480 px video image
--
-- image = agh logo	160x120 px
-- http://tinyvga.com/vga-timing/640x480@60Hz
-------------------------------------------------------------------------------	

library ieee;
use ieee.std_logic_1164.all;   
use ieee.std_logic_unsigned.all;

entity IMAGE_GENERATOR is
	port( 
		DISP_EN		: in STD_LOGIC;
		IMG		: in STD_LOGIC_VECTOR(7 downto 0);	-- 8bit color value from memory
		RED		: out STD_LOGIC_VECTOR(2 downto 0);
		GREEN		: out STD_LOGIC_VECTOR(2 downto 0);
		BLUE		: out STD_LOGIC_VECTOR(1 downto 0)	
		);
end IMAGE_GENERATOR;


architecture IMAGE_GENERATOR of IMAGE_GENERATOR is
begin  	
	-- receive pixel value form ROM and send it to output --
	process(IMG, DISP_EN)
	begin	
		RED <= "000";
		GREEN <= "000";
		BLUE <= "00";
		if DISP_EN = '1' then
			RED <= IMG(7 downto 5);
			GREEN <= IMG(4 downto 2);
			BLUE <= IMG(1 downto 0);			
		end if;
	end process;
end IMAGE_GENERATOR;
