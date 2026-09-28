architecture platformIndependent of bios is

  type stateType is (IDLE, INTERPRET, BURST, ENDTRANSACTION, BUSERROR, WRITE);

  signal s_stateMachineReg      : stateType;
  signal s_stateMachineNext     : stateType;
  signal s_romData, s_ramData   : std_logic_vector(31 downto 0);
  signal s_addressReg           : std_logic_vector(31 downto 0);
  signal s_selectSoftLow        : std_logic;
  signal s_biosData             : std_logic_vector(31 downto 0);
  signal s_endTransactionReg    : std_logic;
  signal s_transactionActiveReg : std_logic;
  signal s_dataValidInReg       : std_logic;
  signal s_beginTransactionReg  : std_logic;
  signal s_burstSizeReg         : std_logic_vector( 7 downto 0 );
  signal s_burstCountReg        : unsigned( 8 downto 0 );
  signal s_readNotWriteReg      : std_logic;
  signal s_RomAddressReg        : unsigned(11 downto 0 );
  signal s_dataInReg            : std_logic_vector(31 downto 0 );
  signal s_byteEnablesReg       : std_logic_vector( 3 downto 0 );
  signal s_isMyBurst            : std_logic;
  signal s_burstCountNext       : unsigned( 8 downto 0 );
  signal s_RomAddressNext       : unsigned(11 downto 0 );
  signal s_writeAddressReg      : unsigned(11 downto 0 );
  signal s_we1                  : std_logic;
  signal s_we2                  : std_logic;
  signal s_we3                  : std_logic;
  signal s_we4                  : std_logic;
  signal s_nClock               : std_logic;
  
  component bios_rom is
    port ( address : in  unsigned( 11 downto 0 );
           data    : out std_logic_vector(31 downto 0));
  end component;
   
  component sramDp is
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
  end  component;

begin
  -- Here the outputs are defined
  s_selectSoftLow <= softRomActive xor s_addressReg(14);
  s_biosData      <= s_ramData when s_selectSoftLow = '1' else s_romData;
  
  makeOutputs : process ( clock ) is
  begin
    if (rising_edge(clock)) then
      if (s_stateMachineReg = BUSERROR) then busErrorOut <= not endTransactionIn;
                                        else busErrorOut <= '0';
      end if;
      if (s_stateMachineReg = ENDTRANSACTION) then endTransactionOut <= '1';
                                              else endTransactionOut <= '0';
      end if;
      if (s_stateMachineReg = BURST and
          endTransactionIn = '0') then dataValidOut   <= '1';
                                       addressDataOut <= s_biosData;
                                  else dataValidOut   <= '0';
                                       addressDataOut <= (others => '0');
      end if;
    end if;
  end process makeOutputs;
  
  -- Here the control related signals are defined
  s_nClock         <= not clock;
  s_isMyBurst      <= s_transactionActiveReg when s_addressReg(31 downto 28) = X"F" and s_addressReg(27 DOWNTO 15) = "1"&X"000" else '0';
  s_burstCountNext <= unsigned("0"&s_burstSizeReg) - to_unsigned(1, 9) when s_stateMachineReg = INTERPRET and s_isMyBurst = '1' else
                      s_burstCountReg - to_unsigned(1, 9) when s_stateMachineReg = BURST else s_burstCountReg;
  s_RomAddressNext <= unsigned(s_addressReg(13 downto 2)) when s_stateMachineReg = INTERPRET and s_isMyBurst = '1' else
                      s_RomAddressReg + to_unsigned(1, 11) when s_stateMachineReg = BURST else s_RomAddressReg;
  
  makeControl : process ( clock ) is
  begin
    if (rising_edge( clock )) then
      if (beginTransactionIn = '1') then s_addressReg      <= addressDataIn;
                                         s_burstSizeReg    <= burstSizeIn;
                                         s_readNotWriteReg <= readNotWriteIn;
                                         s_byteEnablesReg  <= byteEnablesIn;
      end if;
      s_endTransactionReg <= not( reset ) and endTransactionIn;
      if (reset = '1' or s_endTransactionReg = '1') then s_transactionActiveReg <= '0';
        elsif (beginTransactionIn = '1') then s_transactionActiveReg <= '1';
      end if;
      if (s_stateMachineReg = IDLE) then s_burstCountReg <= (others => '1');
                                    else s_burstCountReg <= s_burstCountNext;
      end if;
      s_RomAddressReg       <= s_RomAddressNext;
      s_dataValidInReg      <= dataValidIn;
      s_beginTransactionReg <= beginTransactionIn;
      if (s_isMyBurst = '1' and s_readNotWriteReg = '0' and dataValidIn = '1') then 
        s_dataInReg <= addressDataIn;
      end if;
    end if;
  end process makeControl;
  
  -- Here the state machine is defined
  makeNextState : process ( beginTransactionIn, s_isMyBurst, s_readNotWriteReg, s_selectSoftLow,
                            s_addressReg, s_burstSizeReg, endTransactionIn, s_burstCountReg) is
  begin
    case (s_stateMachineReg) is
       when IDLE      => if (beginTransactionIn = '1') then s_stateMachineNext <= INTERPRET;
                                                       else s_stateMachineNext <= IDLE;
                         end if;
       when INTERPRET => if (s_isMyBurst = '0') then s_stateMachineNext <= IDLE;
                         elsif ((s_readNotWriteReg = '0' and s_selectSoftLow = '0') or
                                (s_addressReg( 1 downto 0) /= "00" and s_burstSizeReg /= X"00")) then s_stateMachineNext <= BUSERROR;
                         elsif (s_readNotWriteReg ='0') then s_stateMachineNext <= WRITE;
                                                        else s_stateMachineNext <= BURST;
                         end if;
       when BURST     => if (endTransactionIn = '1') then s_stateMachineNext <= IDLE;
                         elsif (s_burstCountReg(8) = '1') then s_stateMachineNext <= ENDTRANSACTION;
                                                          else s_stateMachineNext <= BURST;
                         end if;
       when BUSERROR  => if (endTransactionIn = '1') then s_stateMachineNext <= IDLE;
                                                     else s_stateMachineNext <= BUSERROR;
                         end if;
       when WRITE     => if (s_isMyBurst = '1') then s_stateMachineNext <= WRITE;
                                                else s_stateMachineNext <= IDLE;
                         end if;
       when others    => s_stateMachineNext <= IDLE;
    end case;
  end process makeNextState;
  
  makeStateReg : process ( clock ) is
  begin
    if (rising_edge( clock )) then
      if (reset = '1') then s_stateMachineReg <= IDLE;
                       else s_stateMachineReg <= s_stateMachineNext;
      end if;
    end if;
  end process makeStateReg;
  
  -- Here are the instructions
  s_we1 <= s_isMyBurst and not(s_readNotWriteReg) and s_dataValidInReg and s_byteEnablesReg(0);
  s_we2 <= s_isMyBurst and not(s_readNotWriteReg) and s_dataValidInReg and s_byteEnablesReg(1);
  s_we3 <= s_isMyBurst and not(s_readNotWriteReg) and s_dataValidInReg and s_byteEnablesReg(2);
  s_we4 <= s_isMyBurst and not(s_readNotWriteReg) and s_dataValidInReg and s_byteEnablesReg(3);
  
  makeWriteAddrReg : process ( clock ) is
  begin
    if (rising_edge( clock )) then
      if (s_beginTransactionReg = '1' and s_isMyBurst = '1') then s_writeAddressReg <= unsigned( s_addressReg(13 downto 2) );
      elsif (s_isMyBurst = '1' and s_readNotWriteReg = '1' and s_dataValidInReg = '1') then s_writeAddressReg <= s_writeAddressReg + to_unsigned(1, 12);
      end if;
    end if;
  end process makeWriteAddrReg;
  
  biosRom : bios_rom
    port map ( address => s_RomAddressReg,
               data    => s_romData);

  softBios1 : sramDp
    generic map ( nrOfAddressBits => 12,
                  nrOfDataBits    => 8)
    port map ( clockA       => s_nClock,
               writeEnableA => '0',
               addressA     => s_RomAddressReg,
               dataInA      => X"00",
               dataOutA     => s_ramData( 7 downto 0 ),
               clockB       => clock,
               writeEnableB => s_we1,
               addressB     => s_writeAddressReg,
               dataInB      => s_dataInReg( 7 downto 0 ),
               dataOutB     => open );

  softBios2 : sramDp
    generic map ( nrOfAddressBits => 12,
                  nrOfDataBits    => 8)
    port map ( clockA       => s_nClock,
               writeEnableA => '0',
               addressA     => s_RomAddressReg,
               dataInA      => X"00",
               dataOutA     => s_ramData( 15 downto 8 ),
               clockB       => clock,
               writeEnableB => s_we2,
               addressB     => s_writeAddressReg,
               dataInB      => s_dataInReg( 15 downto 8 ),
               dataOutB     => open );

  softBios3 : sramDp
    generic map ( nrOfAddressBits => 12,
                  nrOfDataBits    => 8)
    port map ( clockA       => s_nClock,
               writeEnableA => '0',
               addressA     => s_RomAddressReg,
               dataInA      => X"00",
               dataOutA     => s_ramData( 23 downto 16 ),
               clockB       => clock,
               writeEnableB => s_we3,
               addressB     => s_writeAddressReg,
               dataInB      => s_dataInReg( 23 downto 16 ),
               dataOutB     => open );

  softBios4 : sramDp
    generic map ( nrOfAddressBits => 12,
                  nrOfDataBits    => 8)
    port map ( clockA       => s_nClock,
               writeEnableA => '0',
               addressA     => s_RomAddressReg,
               dataInA      => X"00",
               dataOutA     => s_ramData( 31 downto 24 ),
               clockB       => clock,
               writeEnableB => s_we4,
               addressB     => s_writeAddressReg,
               dataInB      => s_dataInReg( 31 downto 24 ),
               dataOutB     => open );

end platformIndependent;
