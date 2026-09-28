library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.log2;
use ieee.math_real.ceil;

entity switches is
  generic ( cpuFrequencyInHz : integer := 4285800;
            baseAddress      : std_logic_vector( 31 downto 0 ) := X"50000000" );
  port ( clock              : in  std_logic;
         reset              : in  std_logic;
         oneKhzTick         : out std_logic;
         irqDip             : out std_logic;
         irqJoy             : out std_logic;
         
         nButtons           : in  std_logic_vector( 4 downto 0 );
         nDipSwitch         : in  std_logic_vector( 7 downto 0 );
         nJoyStick          : in  std_logic_vector( 4 downto 0 );
         
         -- here the bus interface is defined
         beginTransactionIn : in  std_logic;
         endTransactionIn   : in  std_logic;
         readNotWriteIn     : in  std_logic;
         dataValidIn        : in  std_logic;
         busyIn             : in  std_logic;
         addressDataIn      : in  std_logic_vector( 31 downto 0 );
         byteEnablesIn      : in  std_logic_vector( 3 downto 0 );
         burstSizeIn        : in  std_logic_vector( 7 downto 0 );
         endTransactionOut  : out std_logic;
         dataValidOut       : out std_logic;
         busErrorOut        : out std_logic;
         addressDataOut     : out std_logic_vector( 31 downto 0 ));
end switches;
