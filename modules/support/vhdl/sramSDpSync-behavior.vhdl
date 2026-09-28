architecture platformIndependant of sramSDpSync is

  type memoryType is array( (2**nrOfAddressBits) - 1 downto 0 ) of std_logic_vector( nrOfDataBits - 1 downto 0 );
  
  signal s_memory : memoryType;

begin

  makeRam : process( clock) is
  begin
    if (rising_edge( clock )) then
      if (writeEnable = '1') then 
        s_memory(to_integer(writeAddress)) <= writeData;
      end if;
      readDataW <= s_memory(to_integer(writeAddress));
      readDataR <= s_memory(to_integer(readAddress));
    end if;
  end process makeRam;
end platformIndependant;
