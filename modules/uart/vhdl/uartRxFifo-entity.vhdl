--------------------------------------------------------------------------------
-- $RCSfile: uart_rx_fifo.vhdl,v $
--
-- DESC    : OpenRisk 1300 single and multi-processor emulation platform on
--           the UMPP Xilinx FPA based hardware
--
-- EPFL    : LAP
--
-- AUTHORS : T.J.H. Kluter
--
-- CVS     : $Revision: 1.2 $
--           $Date: 2008/06/11 11:09:29 $
--           $Author: kluter $
--           $Source: /home/lapcvs/projects/or1300/modules/uart/vhdl/uart_rx_fifo.vhdl,v $
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
--  $Log: uart_rx_fifo.vhdl,v $
--  Revision 1.2  2008/06/11 11:09:29  kluter
--  Cleaned up code.
--  Changed memory map.
--  Removed LCD-controller as due to harware problem on UMPP board.
--
--  Revision 1.1  2008/05/16 10:43:00  kluter
--  Added UART module
--
--
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;

ENTITY uart_rx_fifo IS
   PORT ( reset            : IN  std_logic;
          clock            : IN  std_logic;
          
          fifo_re          : IN  std_logic;
          clear_error      : IN  std_logic;
          fifo_we          : IN  std_logic;
          fifo_full        : OUT std_logic;
          fifo_empty       : OUT std_logic;
          frame_error_in   : IN  std_logic;
          parity_error_in  : IN  std_logic;
          break_in         : IN  std_logic;
          data_in          : IN  std_logic_vector( 7 DOWNTO 0 );
          frame_error_out  : OUT std_logic;
          parity_error_out : OUT std_logic;
          break_out        : OUT std_logic;
          fifo_error       : OUT std_logic;
          nr_of_entries    : OUT std_logic_vector( 4 DOWNTO 0 );
          data_out         : OUT std_logic_vector( 7 DOWNTO 0 ));
END uart_rx_fifo;
