library ieee;
use ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

entity sramLutRam is
  generic( nrOfAddressBits : integer := 5;
           nrOfDataBits    : integer := 32 );
  port ( clock        : in  std_logic;
         writeEnable  : in  std_logic;
         writeAddress : in  unsigned( nrOfAddressBits - 1 downto 0 );
         readAddress  : in  unsigned( nrOfAddressBits - 1 downto 0 );
         writeData    : in  std_logic_vector( nrOfDataBits - 1 downto 0 );
         readData     : out std_logic_vector( nrOfDataBits - 1 downto 0 ));
end sramLutRam;
