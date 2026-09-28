--------------------------------------------------------------------------------
-- $RCSfile: $
--
-- DESC    : OpenRisk 1420 
--
-- AUTHOR  : Dr. Theo Kluter
--
-- CVS     : $Revision: $
--           $Date: $
--           $Author: $
--           $Source: $
--
--------------------------------------------------------------------------------
--
--  HISTORY :
--
--  $Log: 
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY bios IS
   PORT ( clock                : IN  std_logic;
          reset                : IN  std_logic;
          
          -- Here the bus interface signals are defined
          address_data_in      : IN  std_logic_vector( 31 DOWNTO 0 );
          begin_transaction_in : IN  std_logic;
          end_transaction_in   : IN  std_logic;  
          read_n_write_in      : IN  std_logic;
          burst_size_in        : IN  std_logic_vector(  7 DOWNTO 0 );
          address_data_out     : OUT std_logic_vector( 31 DOWNTO 0 );
          bus_error_out        : OUT std_logic;
          end_transaction_out  : OUT std_logic;
          data_valid_out       : OUT std_logic);
END bios;
