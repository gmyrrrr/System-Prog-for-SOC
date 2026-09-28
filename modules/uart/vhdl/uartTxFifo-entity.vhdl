--------------------------------------------------------------------------------
-- $RCSfile: uart_fifo.vhdl,v $
--
-- DESC    : OpenRisk 1300 single and multi-processor emulation platform on
--           the UMPP Xilinx FPA based hardware
--
-- EPFL    : LAP
--
-- AUTHORS : T.J.H. Kluter
--
-- CVS     : $Revision: 1.1 $
--           $Date: 2008/05/16 10:43:00 $
--           $Author: kluter $
--           $Source: /home/lapcvs/projects/or1300/modules/uart/vhdl/uart_fifo.vhdl,v $
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
--  $Log: uart_fifo.vhdl,v $
--  Revision 1.1  2008/05/16 10:43:00  kluter
--  Added UART module
--
--
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;

ENTITY uart_fifo IS
   PORT ( reset            : IN  std_logic;
          clock            : IN  std_logic;
          
          fifo_re          : IN  std_logic;
          fifo_we          : IN  std_logic;
          fifo_full        : OUT std_logic;
          fifo_empty       : OUT std_logic;
          data_in          : IN  std_logic_vector( 7 DOWNTO 0 );
          data_out         : OUT std_logic_vector( 7 DOWNTO 0 ));
END uart_fifo;
