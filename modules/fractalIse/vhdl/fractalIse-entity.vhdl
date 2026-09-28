LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY fractal IS
   GENERIC( FRACTAL_CI : std_logic_vector( 7 DOWNTO 0 ) := X"20";
            NMAX_CI    : std_logic_vector( 7 DOWNTO 0 ) := X"21");
   PORT ( clock       : IN  std_logic;
          reset       : IN  std_logic;
          ci_a        : IN  std_logic_vector( 31 DOWNTO 0 );
          ci_b        : IN  std_logic_vector( 31 DOWNTO 0 );
          ci_start    : IN  std_logic;
          ci_cke      : IN  std_logic;
          ci_n        : IN  std_logic_vector(  7 DOWNTO 0 );
          ci_done     : OUT std_logic;
          ci_result   : OUT std_logic_vector( 31 DOWNTO 0 ));
END fractal;
