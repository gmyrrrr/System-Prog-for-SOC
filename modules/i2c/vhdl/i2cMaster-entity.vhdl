library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.log2;
use ieee.math_real.ceil;

entity i2cMaster is
  generic( CLOCK_FREQUENCY : integer := 12000000;
           I2C_FREQUENCY   : integer := 1000000);
  port( clock      : in    std_logic;
        reset      : in    std_logic;
        startWrite : in    std_logic;
        startRead  : in    std_logic;
        address    : in    std_logic_vector( 6 downto 0 );
        regIn      : in    std_logic_vector( 7 downto 0 );
        dataIn     : in    std_logic_vector( 7 downto 0 );
        dataOut    : out   std_logic_vector( 7 downto 0 );
        ackError   : out   std_logic;
        busy       : out   std_logic;
        SCL        : out   std_logic;
        SDA        : inout std_logic);
end i2cMaster;
