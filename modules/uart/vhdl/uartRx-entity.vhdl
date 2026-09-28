--------------------------------------------------------------------------------
-- $RCSfile: uart_rx.vhdl,v $
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
--           $Source: /home/lapcvs/projects/or1300/modules/uart/vhdl/uart_rx.vhdl,v $
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
--  $Log: uart_rx.vhdl,v $
--  Revision 1.1  2008/05/16 10:43:00  kluter
--  Added UART module
--
--
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;

ENTITY uart_rx_controler IS
   PORT( clock               : IN  std_logic;
         reset               : IN  std_logic;
         baud_rate_x_16_tick : IN  std_logic;
         
         uart_rx             : IN  std_logic;
         
         control_reg         : IN  std_logic_vector( 5 DOWNTO 0 );
         fifo_full           : IN  std_logic;
         fifo_data           : OUT std_logic_vector( 7 DOWNTO 0 );
         fifo_we             : OUT std_logic;
         
         frame_error         : OUT std_logic;
         break_detected      : OUT std_logic;
         parity_error        : OUT std_logic;
         overrun_error       : OUT std_logic);
END uart_rx_controler;
