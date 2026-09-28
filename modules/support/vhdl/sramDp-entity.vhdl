library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sramDp is
   generic ( nrOfAddressBits : integer := 12;
             nrOfDataBits    : integer := 8);
   port ( clockA       : in  std_logic;
          writeEnableA : in  std_logic;
          addressA     : in  unsigned( nrOfAddressBits - 1 downto 0 );
          dataInA      : in  std_logic_vector( nrOfDataBits - 1 downto 0 );
          dataOutA     : out std_logic_vector( nrOfDataBits - 1 downto 0 );
          clockB       : in  std_logic;
          writeEnableB : in  std_logic;
          addressB     : in  unsigned( nrOfAddressBits - 1 downto 0 );
          dataInB      : in  std_logic_vector( nrOfDataBits - 1 downto 0 );
          dataOutB     : out std_logic_vector( nrOfDataBits - 1 downto 0 ));
end sramDp;
