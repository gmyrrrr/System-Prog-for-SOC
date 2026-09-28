architecture behave of ssram_8k is

  type stateType is ( IDLE, WRITE, READ, ENDTRANS );
  type memType is array( 2047 downto 0 ) of std_logic_vector( 7 downto 0 );

  signal s_beginTransactionInReg, s_transactionActiveReg : std_logic;
  signal s_dataValidReg, s_readNotWriteReg, s_doRead     : std_logic;
  signal s_isMyTransaction                               : std_logic;
  signal s_addressDataInReg                              : std_logic_vector( 31 downto 0 );
  signal s_byteEnablesReg                                : std_logic_vector(  3 downto 0 );
  signal s_burstSizeReg                                  : unsigned(  8 downto 0 );
  signal s_currentStateReg, s_nextState                  : stateType;
  signal s_mem1, s_mem2, s_mem3, s_mem4                  : memType;
  signal s_ramAddressReg, s_ramAddressNext               : unsigned( 10 downto 0 );
  signal s_readDataReg, s_dataOutReg                     : std_logic_vector( 31 downto 0 );
  signal s_dataValidOutReg, s_we1, s_we2, s_we3, s_we4   : std_logic;

begin
  -- here we define the bus registers
  s_isMyTransaction <= s_beginTransactionInReg
                         when s_addressDataInReg(31 downto 13) = baseAddress(31 downto 13)
                         else '0';
  
  makeBusRegs : process ( clock ) is
  begin
    if (rising_edge( clock )) then
      if (reset = '1' or endTransactionIn = '1') then
        s_transactionActiveReg <= '0';
                                                 else
        s_transactionActiveReg <= s_transactionActiveReg or beginTransactionIn;
      end if;
      s_beginTransactionInReg <= beginTransactionIn;
      s_dataValidReg          <= dataValidIn;
      s_addressDataInReg      <= addressDataIn;
      if (beginTransactionIn = '1') then
        s_readNotWriteReg <= readNotWriteIn;
        s_byteEnablesReg  <= byteEnablesIn;
        s_burstSizeReg    <= unsigned('0'&burstSizeIn);
      elsif (s_doRead = '1') then
        s_burstSizeReg    <= s_burstSizeReg - to_unsigned(1, 9);
      end if;
    end if;
  end process makeBusRegs;
  
  -- Here the state machine is defined
  endTransactionOut <= '1' when s_currentStateReg = ENDTRANS else '0';
  s_doRead          <= not(busyIn) and not(s_burstSizeReg(8))
                         when s_currentStateReg = READ else '0';
  
  makeNextState : process ( s_currentStateReg, s_isMyTransaction, s_readNotWriteReg,
                            busErrorIn, s_transactionActiveReg, s_burstSizeReg,
                            busyIn ) is
  begin
    case (s_currentStateReg) is
      when IDLE   => if (s_isMyTransaction = '1' and s_readNotWriteReg = '0') then
                       s_nextState <= WRITE;
                     elsif (s_isMyTransaction = '1' and s_readNotWriteReg = '1') then
                       s_nextState <= READ;
                                                                                 else
                       s_nextState <= IDLE;
                     end if;
      when WRITE  => if (busErrorIn = '1' or s_transactionActiveReg = '0') then
                       s_nextState <= IDLE;
                                                                           else
                       s_nextState <= WRITE;
                     end if;
      when READ   => if (busErrorIn = '1' or (s_burstSizeReg(8) = '1' and
                         busyIn = '0')) then
                       s_nextState <= ENDTRANS;
                                        else
                       s_nextState <= READ;
                     end if;
      when others => s_nextState <= IDLE;
    end case;
  end process makeNextState;
  
  makeStateReg : process ( clock ) is
  begin
    if (rising_edge( clock )) then
      if (reset = '1') then s_currentStateReg <= IDLE;
                       else s_currentStateReg <= s_nextState;
      end if;
    end if;
  end process makeStateReg;
  
  -- here the memory is defined
  s_ramAddressNext <= (others => '0') when reset = '1' else
                      unsigned(s_addressDataInReg(12 downto 2))
                        when s_isMyTransaction = '1' else
                      s_ramAddressReg + to_unsigned(1, 11)
                        when (s_currentStateReg = WRITE and s_dataValidReg = '1') or
                             (s_currentStateReg = READ and s_doRead = '1') else
                      s_ramAddressReg;
  s_we1 <= s_byteEnablesReg(0) 
             when s_currentStateReg = WRITE and s_dataValidReg = '1' else '0';
  s_we2 <= s_byteEnablesReg(1) 
             when s_currentStateReg = WRITE and s_dataValidReg = '1' else '0';
  s_we3 <= s_byteEnablesReg(2) 
             when s_currentStateReg = WRITE and s_dataValidReg = '1' else '0';
  s_we4 <= s_byteEnablesReg(3) 
             when s_currentStateReg = WRITE and s_dataValidReg = '1' else '0';
  dataValidOut   <= s_dataValidOutReg;
  addressDataOut <= s_dataOutReg;
  
  makeMem : process (clock) is
  begin
    if (rising_edge( clock )) then
      s_ramAddressReg <= s_ramAddressNext;
      if (s_we1 = '1') then 
        s_mem1(to_integer(s_ramAddressReg)) <= s_addressDataInReg( 7 downto 0 );
      end if;
      if (s_we2 = '1') then 
        s_mem2(to_integer(s_ramAddressReg)) <= s_addressDataInReg( 15 downto 8 );
      end if;
      if (s_we3 = '1') then 
        s_mem3(to_integer(s_ramAddressReg)) <= s_addressDataInReg( 23 downto 16 );
      end if;
      if (s_we4 = '1') then 
        s_mem4(to_integer(s_ramAddressReg)) <= s_addressDataInReg( 31 downto 24 );
      end if;
      if (s_doRead = '1') then
        s_dataValidOutReg <= '1';
        s_dataOutReg      <= s_readDataReg;
      elsif (busyIn = '0') then
        s_dataValidOutReg <= '0';
        s_dataOutReg      <= (others => '0');
      end if;
    end if;
  end process makeMem;
  
  makeMemRead : process (clock) is
  begin
    if (falling_edge(clock)) then
      s_readDataReg( 7 downto 0 )   <= s_mem1(to_integer(s_ramAddressReg));
      s_readDataReg( 15 downto 8 )  <= s_mem2(to_integer(s_ramAddressReg));
      s_readDataReg( 23 downto 16 ) <= s_mem3(to_integer(s_ramAddressReg));
      s_readDataReg( 31 downto 24 ) <= s_mem4(to_integer(s_ramAddressReg));
    end if;
  end process makeMemRead;
end behave;
