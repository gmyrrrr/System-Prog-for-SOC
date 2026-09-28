library ieee;
use ieee.std_logic_1164.all;

entity swapByte is
  generic ( customIntructionNr : std_logic_vector( 7 downto 0 ) := X"00" );
  port ( ciN      : in  std_logic_vector( 7 downto 0 );
         ciDataA  : in  std_logic_vector(31 downto 0 );
         ciDataB  : in  std_logic_vector(31 downto 0 );
         ciStart  : in  std_logic;
         ciCke    : in  std_logic;
         ciDone   : out std_logic;
         ciResult : out std_logic_vector(31 downto 0 ));
end swapByte;
