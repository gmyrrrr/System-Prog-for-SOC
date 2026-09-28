library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.log2;
use ieee.math_real.ceil;

entity delayIse is
  generic ( refferenceClockFrequencyInHz : integer := 12000000;
            customInstructionId         : std_logic_vector( 7 downto 0 ) );
  port ( clock           : in  std_logic;
         refferenceClock : in  std_logic;
         reset           : in  std_logic;
         ciStart         : in  std_logic;
         ciCke           : in  std_logic;
         ciN             : in  std_logic_vector( 7 downto 0 );
         ciValueA        : in  std_logic_vector(31 downto 0 );
         ciValueB        : in  std_logic_vector(31 downto 0 );
         ciDone          : out std_logic;
         ciResult        : out std_logic_vector(31 downto 0 ));
end delayIse;

