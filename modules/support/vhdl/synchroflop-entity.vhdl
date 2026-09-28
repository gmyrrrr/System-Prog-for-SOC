library ieee;
use ieee.std_logic_1164.all;

entity synchroFlop is
  port ( clockIn  : in  std_logic;
         clockOut : in  std_logic;
         reset    : in  std_logic;
         D        : in  std_logic;
         Q        : out std_logic);
end synchroFlop;
