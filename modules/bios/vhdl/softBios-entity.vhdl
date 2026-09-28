library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bios is
  port( clock              : in  std_logic;
        reset              : in  std_logic;
        softRomActive      : in  std_logic;
        addressDataIn      : in  std_logic_vector( 31 downto 0 );
        beginTransactionIn : in  std_logic;
        endTransactionIn   : in  std_logic;
        readNotWriteIn     : in  std_logic;
        busErrorIn         : in  std_logic;
        dataValidIn        : in  std_logic;
        byteEnablesIn      : in  std_logic_vector( 3 downto 0 );
        burstSizeIn        : in  std_logic_vector( 7 downto 0 );
        addressDataOut     : out std_logic_vector(31 downto 0 );
        busErrorOut        : out std_logic;
        dataValidOut       : out std_logic;
        endTransactionOut  : out std_logic );
end bios;
