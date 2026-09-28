architecture behave of swapByte is

  signal s_isMyCustomInstruction : std_logic;
  signal s_swappedData           : std_logic_vector( 31 DOWNTO 0 );

begin
  s_isMyCustomInstruction <= ciCke and ciStart when ciN = customIntructionNr else '0';
  s_swappedData <= ciDataA(7 downto 0)&ciDataA(15 downto 8)&
                   ciDataA(23 downto 16)&ciDataA(31 downto 24) when ciDataB(0) = '0' else
                   ciDataA(23 downto 16)&ciDataA(31 downto 24)&
                   ciDataA(7 downto 0)&ciDataA(15 downto 8);
  ciDone   <= s_isMyCustomInstruction;
  ciResult <= s_swappedData when s_isMyCustomInstruction = '1' else (others => '0');
end behave;
