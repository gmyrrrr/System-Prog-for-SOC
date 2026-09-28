architecture platformIndependant of sramDp is

  type memType is array ((2**nrOfAddressBits) - 1 downto 0) of std_logic_vector( nrOfDataBits - 1 downto 0 );
  signal s_memContents : memType;

begin
  portA : process (clockA) is
  begin
    if (rising_edge( clockA )) then
      if (writeEnableA = '1') then
        s_memContents( to_integer( addressA ) ) <= dataInA;
      end if;
      dataOutA <= s_memContents( to_integer( addressA ) );
    end if;
  end process portA;

  portB : process (clockB) is
  begin
    if (rising_edge( clockB )) then
      if (writeEnableB = '1') then
        s_memContents( to_integer( addressB ) ) <= dataInB;
      end if;
      dataOutB <= s_memContents( to_integer( addressB ) );
    end if;
  end process portB;
end platformIndependant;
