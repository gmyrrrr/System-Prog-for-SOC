--------------------------------------------------------------------------------
-- $RCSfile: uart_tx.vhdl,v $
--
-- DESC    : OpenRisk 1300 single and multi-processor emulation platform on
--           the UMPP Xilinx FPA based hardware
--
-- EPFL    : LAP
--
-- AUTHORS : T.J.H. Kluter
--
-- CVS     : $Revision: 1.2 $
--           $Date: 2008/05/16 10:51:34 $
--           $Author: kluter $
--           $Source: /home/lapcvs/projects/or1300/modules/uart/vhdl/uart_tx.vhdl,v $
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
--  $Log: uart_tx.vhdl,v $
--  Revision 1.2  2008/05/16 10:51:34  kluter
--  Fixed typo
--
--  Revision 1.1  2008/05/16 10:43:00  kluter
--  Added UART module
--
--
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;

ENTITY uart_tx_controller IS
   PORT( clock               : IN  std_logic;
         reset               : IN  std_logic;
         baud_rate_x_2_tick  : IN  std_logic;
         
         control_reg         : IN  std_logic_vector( 6 DOWNTO 0 );
         fifo_data           : IN  std_logic_vector( 7 DOWNTO 0 );
         fifo_empty          : IN  std_logic;
         fifo_read_ack       : OUT std_logic;
         
         uart_tx             : OUT std_logic;
         busy                : OUT std_logic);
END uart_tx_controller;
