--------------------------------------------------------------------------------
-- $RCSfile: baud_generator.vhdl,v $
--
-- DESC    : OpenRisk 1300 single and multi-processor emulation platform on
--           the UMPP Xilinx FPA based hardware
--
-- EPFL    : LAP
--
-- AUTHORS : T.J.H. Kluter
--
-- CVS     : $Revision: 1.2 $
--           $Date: 2008/05/16 10:52:56 $
--           $Author: kluter $
--           $Source: /home/lapcvs/projects/or1300/modules/uart/vhdl/baud_generator.vhdl,v $
--
--------------------------------------------------------------------------------
--
-- Copyright (C) 2007/2008 Theo Kluter <ties.kluter@epfl.ch> EPFL-ISIM-LAP
--
--  This file is subject to the terms and conditions of the GNU General Public
--  License.
--
--------------------------------------------------------------------------------
--
--  HISTORY :
--
--  $Log: baud_generator.vhdl,v $
--  Revision 1.2  2008/05/16 10:52:56  kluter
--  Fixed typo
--
--  Revision 1.1  2008/05/16 10:42:59  kluter
--  Added UART module
--
--
--------------------------------------------------------------------------------

architecture behav of baud_rate_generator is

  signal s_counterReg      : unsigned(15 downto 0);
  signal s_counterNext     : unsigned(15 downto 0);
  signal s_counterResetReg : std_logic;
  signal s_counterLoad     : std_logic;
  signal s_baudDivReg      : unsigned( 2 downto 0);
  signal s_baudDivNext     : unsigned( 2 downto 0);
  signal s_baudDivIsZero   : std_logic;
  signal s_baudRateX16Tick : std_logic;
  signal s_baudRateX2Tick  : std_logic;
  
  component synchroFlop is
    port ( clockIn  : in  std_logic;
           clockOut : in  std_logic;
           reset    : in  std_logic;
           D        : in  std_logic;
           Q        : out std_logic);
  end component;

begin
  s_counterLoad     <= '1' when s_counterReg(15 downto 1) = to_unsigned(0, 15) else '0';
  s_counterNext     <= unsigned(baudDivisor) when reset = '1' or s_counterLoad = '1' else s_counterReg - to_unsigned(1, 16);
  s_baudDivNext     <= to_unsigned(7, 3) when reset = '1' else
                       s_baudDivReg - to_unsigned(1, 3) when s_counterLoad = '1' else s_baudDivReg;
  s_baudDivIsZero   <= '1' when s_baudDivReg = to_unsigned(0, 3) else '0';
  s_baudRateX16Tick <= s_counterLoad and not(s_counterResetReg);
  s_baudRateX2Tick  <= s_counterLoad and s_baudDivIsZero and not(s_counterResetReg);
  
  makeFlops : process( clock_50MHz )
  begin
    if (rising_edge( clock_50MHz )) then
      s_counterResetReg <= reset;
      s_counterReg      <= s_counterNext;
      s_baudDivReg      <= s_baudDivNext;
    end if;
  end process makeFlops;
  
  baud16 : synchroFlop
    port map ( clockIn  => clock_50MHz,
               clockOut => clock,
               reset    => reset,
               D        => s_baudRateX16Tick,
               Q        => baudRateX16Tick);

  baud2 : synchroFlop
    port map ( clockIn  => clock_50MHz,
               clockOut => clock,
               reset    => reset,
               D        => s_baudRateX2Tick,
               Q        => baudRateX2Tick);
end behav;
