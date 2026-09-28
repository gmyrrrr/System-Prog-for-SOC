library ieee;
use ieee.std_logic_1164.all;

entity i2cCustomInstr is
  generic( CLOCK_FREQUENCY : integer := 12000000;
           I2C_FREQUENCY   : integer := 100000;
           CUSTOM_ID       : std_logic_vector( 7 downto 0 ) := X"00");
  port( clock    : in    std_logic;
        reset    : in    std_logic;
        ciStart  : in    std_logic;
        ciCke    : in    std_logic;
        ciN      : in    std_logic_vector( 7 downto 0 );
        ciOppA   : in    std_logic_vector(31 downto 0 );
        ciDone   : out   std_logic;
        ciResult : out   std_logic_vector(31 downto 0 );
        SDA      : inout std_logic;
        SCL      : out   std_logic);
end i2cCustomInstr;
