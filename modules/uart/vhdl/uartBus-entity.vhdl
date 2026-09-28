--------------------------------------------------------------------------------
-- $RCSfile: uart_bus_entity.vhdl,v $
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
--           $Source: /home/lapcvs/projects/or1300/modules/uart/vhdl/uart_bus_entity.vhdl,v $
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
--  $Log: uart_bus_entity.vhdl,v $
--  Revision 1.1  2008/05/16 10:43:00  kluter
--  Added UART module
--
--
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;

ENTITY uart_bus IS
   GENERIC ( base_address : std_logic_vector( 31 DOWNTO 0 ) := X"00000000");
   PORT ( clock                  : IN  std_logic;
          clock_50MHz            : IN  std_logic;
          reset                  : IN  std_logic;
          
          irq                    : OUT std_logic;
          
          -- define the bus interface signals
          begin_transaction_in   : IN    std_logic;
          address_data_in        : IN    std_logic_vector( 31 DOWNTO 0 );
          address_data_out       : OUT   std_logic_vector( 31 DOWNTO 0 );
          end_transaction_in     : IN    std_logic;
          end_transaction_out    : OUT   std_logic;
          byte_enables_in        : IN    std_logic_vector(  3 DOWNTO 0 );
          read_n_write_in        : IN    std_logic;
          data_valid_in          : IN    std_logic;
          data_valid_out         : OUT   std_logic;
          busy_in                : IN    std_logic;
          burst_size_in          : IN    std_logic_vector(  2 DOWNTO 0 );
          
          -- Here we specify the actual off-chip interface
          RxD                    : IN  std_logic;
          TxD                    : OUT std_logic );
END uart_bus;
