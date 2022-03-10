-- cpu.vhd: Simple 8-bit CPU (BrainF*ck interpreter)
-- Copyright (C) 2020 Brno University of Technology,
--                    Faculty of Information Technology
-- Author(s): Kozhevnikov Dmitrii
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

-- ----------------------------------------------------------------------------
--                        Entity declaration
-- ----------------------------------------------------------------------------
entity cpu is
 port (
   CLK   : in std_logic;  -- hodinovy signal
   RESET : in std_logic;  -- asynchronni reset procesoru
   EN    : in std_logic;  -- povoleni cinnosti procesoru
 
   -- synchronni pamet ROM
   CODE_ADDR : out std_logic_vector(11 downto 0); -- adresa do pameti
   CODE_DATA : in std_logic_vector(7 downto 0);   -- CODE_DATA <- rom[CODE_ADDR] pokud CODE_EN='1'
   CODE_EN   : out std_logic;                     -- povoleni cinnosti
   
   -- synchronni pamet RAM
   DATA_ADDR  : out std_logic_vector(9 downto 0); -- adresa do pameti
   DATA_WDATA : out std_logic_vector(7 downto 0); -- ram[DATA_ADDR] <- DATA_WDATA pokud DATA_EN='1'
   DATA_RDATA : in std_logic_vector(7 downto 0);  -- DATA_RDATA <- ram[DATA_ADDR] pokud DATA_EN='1'
   DATA_WE    : out std_logic;                    -- cteni (0) / zapis (1)
   DATA_EN    : out std_logic;                    -- povoleni cinnosti 
   
   -- vstupni port
   IN_DATA   : in std_logic_vector(7 downto 0);   -- IN_DATA <- stav klavesnice pokud IN_VLD='1' a IN_REQ='1'
   IN_VLD    : in std_logic;                      -- data platna
   IN_REQ    : out std_logic;                     -- pozadavek na vstup data
   
   -- vystupni port
   OUT_DATA : out  std_logic_vector(7 downto 0);  -- zapisovana data
   OUT_BUSY : in std_logic;                       -- LCD je zaneprazdnen (1), nelze zapisovat
   OUT_WE   : out std_logic                       -- LCD <- OUT_DATA pokud OUT_WE='1' a OUT_BUSY='0'
 );
end cpu;


-- ----------------------------------------------------------------------------
--                      Architecture declaration
-- ----------------------------------------------------------------------------
architecture behavioral of cpu is

----- PC -----
	signal pc_reg : std_logic_vector (11 downto 0);
	signal pc_inc : std_logic;
	signal pc_dec : std_logic;
	signal pc_load : std_logic;
----- PC -----

----- RAS -----
	signal ras_reg : std_logic_vector (191 downto 0);
	signal ras_push : std_logic;
	signal ras_pop : std_logic;
----- RAS -----

----- PTR -----
	signal ptr_reg : std_logic_vector (9 downto 0);
	signal ptr_inc : std_logic;
	signal ptr_dec : std_logic;
----- PTR -----

----- CNT -----
	signal cnt_reg : std_logic_vector (4 downto 0);
	signal cnt_inc : std_logic;
	signal cnt_dec : std_logic; 
----- CNT -----

----- STATES -----
	type fsm_state is (
		s_start,	-- startovy stav
		s_next_instr,	-- cteni instrukce
		s_decode,	-- decodovani instrukce

		s_sell_inc_0,	-- inkrementace hodnoty bunky
		s_sell_inc_1,
		s_sell_inc_2,

		s_sell_dec_0,	-- dekrementace hodnoty bunky
		s_sell_dec_1,
		s_sell_dec_2,

		s_pointer_inc,	-- inkrementace hodnoty ukazatele
		s_pointer_dec,	-- dekrementace hodnoty ukazatele

		s_while_start_0,	-- zacatek cyklu
		s_while_start_1,
		s_while_start_2,
		s_while_start_3,
		s_while_start_4,

		s_while_end_0,	-- konec cyklu
		s_while_end_1,

		s_write,	-- tisk hodnoty bunky
		s_write_done,

		s_get,		-- nacteni hodnoty do bunky
		s_get_done,

		s_null,		-- zastav vykonavani programu
		s_others	-- ostatni
	);
	signal pState : fsm_state := s_start;
	signal nState : fsm_state;
----- STATES -----

----- MULTIPLEXOR -----
	signal mult_sel : std_logic_vector (1 downto 0);
	signal mult_out : std_logic_vector (7 downto 0);
----- MULTIPLEXOR -----

begin

	----- PC -----

	pc: process (CLK, RESET, pc_inc, pc_dec, pc_load) is
	begin
		if RESET = '1' then
			pc_reg <= (others => '0');
		elsif CLK'event and CLK = '1' then
			if pc_inc = '1' then
				pc_reg <= pc_reg + 1;
			elsif pc_dec = '1' then
				pc_reg <= pc_reg - 1;
			elsif pc_load = '1' then
				pc_reg <= ras_reg(191 downto 180);
			end if; 
		end if;

	end process;
	CODE_ADDR <= pc_reg; 

	----- PC -----



	----- RAS -----

	ras: process (CLK, RESET, ras_push, ras_pop) is
	begin
		if RESET = '1' then
			ras_reg <= (others => '0');
		elsif CLK'event and CLK = '1' then
			if ras_push = '1' then
				ras_reg <= pc_reg & ras_reg(191 downto 12);
			elsif ras_pop = '1' then
				ras_reg <= ras_reg(179 downto 0) & "000000000000";
			end if;
		end if;
	end process;
			
	----- RAS -----



	----- CNT -----

	cnt: process (CLK, RESET, cnt_inc, cnt_dec)
	begin
		if RESET = '1' then
			cnt_reg <= (others => '0');
		elsif CLK'event and CLK = '1' then
			if cnt_inc = '1' then
				cnt_reg <= cnt_reg + 1;
			elsif cnt_dec = '1' then
				cnt_reg <= cnt_reg - 1;
			end if;
		end if;
	end process;
	OUT_DATA <= DATA_RDATA;

	----- CNT -----



	----- PTR -----

	ptr: process (CLK, RESET, ptr_inc, ptr_dec) is
	begin
		if RESET = '1' then
			ptr_reg <= (others => '0');
		elsif CLK'event and CLK = '1' then
			if ptr_inc = '1' then
				ptr_reg <= ptr_reg + 1;
			elsif ptr_dec = '1' then
				ptr_reg <= ptr_reg - 1;
			end if; 
		end if;

	end process;
	DATA_ADDR <= ptr_reg;

	----- PTR -----




	----- MULTIPLEXOR -----

	mux: process (CLK, RESET, mult_sel) is
	begin
		if RESET = '1' then
			mult_out <= (others => '0');
		elsif CLK'event and CLK = '1' then
			case mult_sel is
				when "00" => 
					mult_out <= IN_DATA;
				when "01" =>
					mult_out <= DATA_RDATA + 1;
				when "10" =>
					mult_out <= DATA_RDATA - 1;
				when others =>
					mult_out <= (others => '0');
			end case;
		end if;
	end process;
	DATA_WDATA <= mult_out;

 	----- MULTIPLEXOR -----



	----- FSM -----

	-- aktualni stav
	pState_logic : process (CLK, RESET, EN) is
	begin
		if RESET = '1' then
			pState <= s_start;
		elsif CLK'event and CLK = '1' then
			if EN = '1' then
				pState <= nState;
			end if;
		end if;
	end process;

	-- nasledujici stav
	fsm: process (pState, OUT_BUSY, IN_VLD, CODE_DATA, cnt_reg, DATA_RDATA) is 
	begin
		----- initialization -----
		pc_inc <= '0';
		pc_dec <= '0';
		pc_load <= '0';
		ras_push <= '0';
		ras_pop <= '0';
		ptr_inc <= '0';
		ptr_dec <= '0';
		cnt_inc <= '0';
		cnt_dec <= '0';

		mult_sel <= "00";

		CODE_EN <= '0';
		DATA_EN <= '0';
		DATA_WE <= '0';
		IN_REQ <= '0';
		OUT_WE <= '0';

		case pState is 
			when s_start =>
				nState <= s_next_instr;
			when s_next_instr =>
				CODE_EN <= '1';
				nState <= s_decode;
			when s_decode =>
				case CODE_DATA is
					when X"3E" => 
						nState <= s_pointer_inc;	-- inkrementace hodnoty ukazatele
					when X"3C" => 
						nState <= s_pointer_dec;	-- dekrementace hodnoty ukazatele
					when X"2B" => 
						nState <= s_sell_inc_0;		-- inkrementace hodnoty bunky
					when X"2D" => 
						nState <= s_sell_dec_0;		-- dekrementace hodnoty bunky
					when X"5B" => 
						nState <= s_while_start_0;	-- zacatek cyklu
					when X"5D" => 
						nState <= s_while_end_0;		-- konec cyklu
					when X"2E" => 
						nState <= s_write;		-- tisk hodnoty bunky
					when X"2C" => 
						nState <= s_get;		-- nacteni hodnoty do bunky
					when X"00" => 
						nState <= s_null;		-- zastaveni vykonavani programu
					when others =>
						nState <= s_others;
				end case;

			--- inkrementace hodnoty ukazatele ---
			when s_pointer_inc =>
				ptr_inc <= '1';		-- ptr += 1
				pc_inc <= '1';		-- pc += 1
				nState <= s_next_instr;
			--------------------------------------

			--- dekrementace hodnoty ukazatele ---
			when s_pointer_dec =>
				ptr_dec <= '1';		-- ptr -= 1
				pc_inc <= '1';		-- pc += 1
				nState <= s_next_instr;
			--------------------------------------

			--- inkrementace hodnoty bunky ---
			when s_sell_inc_0 =>
				-- DATA_RDATA <- ram[PTR]
				DATA_EN <= '1';
				DATA_WE <= '0';
				nState <= s_sell_inc_1;
			
			when s_sell_inc_1 => 
				mult_sel <= "01";
				nState <= s_sell_inc_2;
				
			when s_sell_inc_2 =>
				DATA_EN <= '1';
				DATA_WE <= '1';
				pc_inc <= '1';		-- pc += 1
				nState <= s_next_instr;
			---------------------------------

			--- dekrementace hodnoty bunky ---
			when s_sell_dec_0 =>
				DATA_EN <= '1';
				DATA_WE <= '0';
				nState <= s_sell_dec_1;

			when s_sell_dec_1 => 
				mult_sel <= "10";
				nState <= s_sell_dec_2;

			when s_sell_dec_2 =>
				DATA_EN <= '1';
				DATA_WE <= '1';
				pc_inc <= '1';
				nState <= s_next_instr;
			----------------------------------

			------- tisk hodnoty bunky -------
			when s_write =>
				DATA_EN <= '1';
				DATA_WE <= '0';
				nState <= s_write_done;

			when s_write_done =>
				if OUT_BUSY = '1' then
					DATA_EN <= '1';
					DATA_WE <= '0';
					nState <= s_write_done;
				else 
					OUT_WE <= '1';
					pc_inc <= '1';
					nState <= s_next_instr;
				end if;
			-----------------------------------

			----- nacteni hodnoty do bunky -----
			when s_get =>
				IN_REQ <= '1';
				mult_sel <= "00";
				nState <= s_get_done;

			when s_get_done =>
				if IN_VLD /= '1' then 
					IN_REQ <= '1';
					mult_sel <= "00";
					nState <= s_get_done;
				else 
					DATA_EN <= '1';
					DATA_WE <= '1';
					pc_inc <= '1';
					nState <= s_next_instr;
				end if;
			------------------------------------

			---------- zacatek cyklu -----------
			when s_while_start_0 =>
				pc_inc <= '1';
				DATA_EN <= '1';
				DATA_WE <= '0';
				nState <= s_while_start_1;

			when s_while_start_1 =>
				if DATA_RDATA /= (DATA_RDATA'range => '0') then
					ras_push <= '1';
					nState <= s_next_instr;
				else 
					cnt_inc <= '1';		-- CNT += 1
					CODE_EN <= '1';
					nState <= s_while_start_2;
				end if;

			when s_while_start_2 =>
				if cnt_reg = (cnt_reg'range => '0') then
					nState <= s_next_instr;
				else 
					nState <= s_while_start_3;
				end if;

			when s_while_start_3 =>
				if CODE_DATA = X"5B" then
					cnt_inc <= '1';
				elsif CODE_DATA = X"5D" then
					cnt_dec <= '1';
				end if;
				pc_inc <= '1';
				nState <= s_while_start_4;

			when s_while_start_4 =>
				CODE_EN <= '1';
				nState <= s_while_start_2;
			------------------------------------

			------------ konec cyklu -----------
			when s_while_end_0 =>
				DATA_EN <= '1';
				DATA_WE <= '0';
				nState <= s_while_end_1;

			when s_while_end_1 =>
				if DATA_RDATA = (DATA_RDATA'range => '0') then
					ras_pop <= '1';
					pc_inc <= '1';
					nState <= s_next_instr;
				else
					pc_load <= '1';
					nState <= s_next_instr;
				end if;
			------------------------------------

			--------------- null ---------------
			when s_null =>
				nState <= s_null;
			------------------------------------

			------------- ostatni --------------
			when s_others =>
				pc_inc <= '1';
				nState <= s_next_instr;
			------------------------------------

			--------- nedifinovany stav --------
			when others =>
				null;
			
		end case;

	end process;
	----- FSM -----

end behavioral;
 

