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

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY baud_rate_generator IS
   PORT( clock           : IN  std_logic;
         clock_50MHz     : IN  std_logic;
         reset           : IN  std_logic;
         
         baudDivisor     : IN  std_logic_vector( 15 DOWNTO 0 );
         
         baudRateX16Tick : OUT std_logic;
         baudRateX2Tick  : OUT std_logic);
END baud_rate_generator;
