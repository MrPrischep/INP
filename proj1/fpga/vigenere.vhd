library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

-- rozhrani Vigenerovy sifry
entity vigenere is
   port(
         CLK : in std_logic;
         RST : in std_logic;
         DATA : in std_logic_vector(7 downto 0);
         KEY : in std_logic_vector(7 downto 0);

         CODE : out std_logic_vector(7 downto 0)
    );
end vigenere;

architecture behavioral of vigenere is

	-------- SHIFTING SIGNALS --------
	signal shift: std_logic_vector(7 downto 0);
	signal goToRight: std_logic_vector(7 downto 0);
	signal goToLeft:  std_logic_vector(7 downto 0);
	
	-------- FSM --------
	type tState is (add, sub);
	signal presentState: tState := add;
	signal nextState: tState := sub;
	signal fsmOutput: std_logic_vector(1 downto 0);
	signal hashTag: std_logic_vector(7 downto 0) := "00100011";

begin
	---------- FSM PROCESS BLOCK ----------

	--- present state
	present_state: process (CLK, RST) is
	begin
		if RST = '1' then 
			presentState <= add;
		elsif (CLK'event) and (CLK='1') then
			presentState <= nextState;
		end if;
	end process;
	
	--- next state and output
	next_state: process (presentState, DATA, RST) is
	begin
		nextState <= sub;
		case presentState is 
			when add =>
				nextState <= sub;
				fsmOutput <= "01";
				if (RST = '1') then 
					nextState <= sub;
					fsmOutput <= "00";
				end if;
			when sub =>
				nextState <= add;
				fsmOutput <= "10";
			when others => null;
		end case;

		if (DATA > 47 and DATA < 58) then
			fsmOutput <=  "00";
		end if;

		if (RST = '1') then 
			nextState <= sub;
			fsmOutput <= "00";
		end if;
		
	end process;
	---------- END FSM PROCESS BLOCK ----------

	---------- MULTIPLEXOR BLOCK ----------

	--- multiplexor
	Multiplexor: process (fsmOutput, goToRight, goToLeft, hashTag) is
	begin
		case fsmOutput is
			when "01" => CODE <= goToRight;
			when "10" => CODE <= goToLeft;
			when others => CODE <= hashTag;
		end case;
	end process;	

	---------- END MULTIPLEXOR BLOCK ----------


	---------- SHIFTING BLOCK ----------

	--- value to shift
	shifting_proces: process (DATA, KEY) is
	begin
		shift <= KEY - 64;
	end process;
	
	--- shift symbol to right
	AddProces: process (shift, DATA) is
		variable shiftingSymbol: std_logic_vector(7 downto 0);
	begin
		shiftingSymbol := DATA + shift;
		if (shiftingSymbol > 90) then
			shiftingSymbol := shiftingSymbol - 26;
		end if;

		goToRight <= shiftingSymbol;
	end process;

	--- shift symbol to left
	SubProces: process (shift, DATA) is
		variable shiftingSymbol: std_logic_vector(7 downto 0);
	begin
		shiftingSymbol := DATA - shift;
		if (shiftingSymbol < 65) then
			shiftingSymbol := shiftingSymbol + 26;
		end if;

		goToLeft <= shiftingSymbol;
	end process;
	---------- END SHIFTING ----------
end behavioral;
