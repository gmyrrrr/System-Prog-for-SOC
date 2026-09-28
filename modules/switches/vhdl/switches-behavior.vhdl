architecture behave of switches is

  constant scanDivideValue : integer := cpuFrequencyInHz/1000;
  constant nrOfBits        : integer := integer(ceil(log2(real(scanDivideValue))));

  signal s_busDataOutValidReg, s_transactionActiveReg    : std_logic;
  signal s_readNotWriteReg, s_beginTransactionReg        : std_logic;
  signal s_dataInValidReg, s_endTransactionReg           : std_logic;
  signal s_byteEnablesReg                                : std_logic_vector(3 downto 0);
  signal s_burstSizeReg                                  : std_logic_vector(7 downto 0);
  signal s_busAddressReg, s_dataInReg                    : std_logic_vector(31 downto 0);
  signal s_isMyTransaction, s_busErrorOut                : std_logic;
  signal s_tickCounterReg                                : unsigned(nrOfBits-1 downto 0);
  signal s_tick                                          : std_logic;
  signal s_dipSwitchPressedIrqMaskReg                    : std_logic_vector( 7 downto 0 );
  signal s_dipSwitchReleasedIrqMaskReg                   : std_logic_vector( 7 downto 0 );
  signal s_joystickPressedIrqMaskReg                     : std_logic_vector( 9 downto 0 );
  signal s_joystickReleasedIrqMaskReg                    : std_logic_vector( 9 downto 0 );
  signal s_irqDipReg, s_irqJoyReg                        : std_logic_vector( 1 downto 0 );
  signal s_dipswitchPressedIrqs, s_dipSwitchReleasedIrqs : std_logic_vector( 7 downto 0 );
  signal s_joystickPressedIrqs, s_joystickReleasedIrqs   : std_logic_vector( 9 downto 0 );
  signal s_clearAllIrqMasks                              : std_logic;
  signal s_weDipSwitchPressedIrqMask                     : std_logic;
  signal s_weDipSwitchReleasedIrqMask                    : std_logic;
  signal s_clearDipSwitchPressedIrqs                     : std_logic;
  signal s_clearDipSwitchReleasedIrqMask                 : std_logic;
  signal s_weJoystickPressedIrqMask                      : std_logic;
  signal s_weJoystickReleasedIrqMask                     : std_logic;
  signal s_clearJoystickPressedIrqs                      : std_logic;
  signal s_clearJoystickReleasedIrqMask                  : std_logic;
  signal s_weRegister                                    : std_logic;
  signal s_reRegister                                    : std_logic;
  signal s_countActiveReg, s_startCount, s_stopCount     : std_logic;
  signal s_delayCounterReg                               : unsigned( 31 downto 0 );
  signal s_dipswitchState                                : std_logic_vector( 7 downto 0 );
  signal s_joystickState                                 : std_logic_vector( 9 downto 0 );
  signal s_busDataOutReg, s_busDataOutNext               : std_logic_vector(31 downto 0 );
  signal s_endTransactionOutReg, s_isMyRead              : std_logic;
  
  component debouncerWithIrq is
    port ( clock            : in  std_logic;
           reset            : in  std_logic;
           nButtonIn        : in  std_logic;
           scanTick         : in  std_logic;
           enablePressIrq   : in  std_logic;
           enableReleaseIrq : in  std_logic;
           resetPressIrq    : in  std_logic;
           resetReleaseIrq  : in  std_logic;
           pressIrq         : out std_logic;
           releaseIrq       : out std_logic;
           currentState     : out std_logic);
  end component;

begin
  -- Here the bus input interface is defined
  s_isMyTransaction <= s_transactionActiveReg 
                         when s_busAddressReg(31 downto 5) = baseAddress(31 downto 5) else
                       '0';
  s_busErrorOut     <= '1' when s_isMyTransaction = '1' and 
                                (s_byteEnablesReg /= X"F" or 
                                 s_burstSizeReg /= X"00") else '0';
  
  makeBusInRegs : process ( clock ) is
  begin
    if (rising_edge(clock)) then
      if (reset = '1' or s_endTransactionReg = '1') then 
        s_transactionActiveReg <= '0';
                                                    else
        s_transactionActiveReg <= s_transactionActiveReg or beginTransactionIn;
      end if;
      if (beginTransactionIn = '1') then
        s_busAddressReg   <= addressDataIn;
        s_readNotWriteReg <= readNotWriteIn;
        s_byteEnablesReg  <= byteEnablesIn;
        s_burstSizeReg    <= burstSizeIn;
      end if;
      s_beginTransactionReg <= beginTransactionIn;
      s_dataInValidReg      <= dataValidIn;
      s_endTransactionReg   <= endTransactionIn;
      if (dataValidIn = '1') then
        s_dataInReg <= addressDataIn;
      end if;
      if (reset = '1' or endTransactionIn = '1') then busErrorOut <= '0';
                                                 else busErrorOut <= s_busErrorOut;
      end if;
    end if;
  end process makeBusInRegs;
  
  -- Here we define the one kHz tick timer
  s_tick <= '1' when s_tickCounterReg = to_unsigned(0, nrOfBits) else '0';
  
  makeTickCounter : process ( clock ) is
  begin
    if (rising_edge( clock )) then
      if (reset = '1' or s_tick = '1') then
        s_tickCounterReg <= to_unsigned( scanDivideValue - 1, nrOfBits);
                                       else
        s_tickCounterReg <= s_tickCounterReg - to_unsigned(1, nrOfBits);
      end if;
      oneKHzTick <= s_tick;
    end if;
  end process makeTickCounter;
  
  -- Here we define the IRQ enable masks
  irqDip       <= s_irqDipReg(0);
  irqJoy       <= s_irqJoyReg(0);
  s_weRegister <= not(s_busErrorOut) when s_isMyTransaction ='1' and 
                                          s_dataInValidReg = '1' and
                                          s_readNotWriteReg = '0' else '0';
  s_reRegister <= not(s_busErrorOut) when s_isMyTransaction ='1' and 
                                          s_busDataOutValidReg = '1' and
                                          s_readNotWriteReg = '1' else '0';
  s_clearAllIrqMasks              <= '1' when s_reRegister = '1' and
                                              s_busAddressReg(4 downto 2) = "111" else 
                                     '0';
  s_weDipSwitchPressedIrqMask     <= '1' when s_weRegister = '1' and
                                              s_busAddressReg(4 downto 2) = "001" else
                                     '0';
  s_weDipSwitchReleasedIrqMask    <= '1' when s_weRegister = '1' and
                                              s_busAddressReg(4 downto 2) = "010" else 
                                     '0';
  s_clearDipSwitchPressedIrqs     <= '1' when (s_reRegister = '1' and
                                               s_busAddressReg(4 downto 2) = "001") or
                                              s_clearAllIrqMasks = '1' else '0';
  s_clearDipSwitchReleasedIrqMask <= '1' when (s_reRegister = '1' and
                                               s_busAddressReg(4 downto 2) = "010") or
                                              s_clearAllIrqMasks = '1' else '0';
  s_weJoystickPressedIrqMask      <= '1' when s_weRegister = '1' and
                                              s_busAddressReg(4 downto 2) = "100" else
                                     '0';
  s_weJoystickReleasedIrqMask     <= '1' when s_weRegister = '1' and
                                              s_busAddressReg(4 downto 2) = "101" else
                                     '0';
  s_clearJoystickPressedIrqs      <= '1' when (s_reRegister = '1' and
                                               s_busAddressReg(4 downto 2) = "100") or
                                              s_clearAllIrqMasks = '1' else '0';
  s_clearJoystickReleasedIrqMask  <= '1' when (s_reRegister = '1' and
                                               s_busAddressReg(4 downto 2) = "101") or
                                              s_clearAllIrqMasks = '1' else '0';
  
  makeIrqRegs : process ( clock ) is
  begin
    if (rising_edge( clock )) then
      if (reset = '1' or s_clearAllIrqMasks = '1') then
         s_dipSwitchPressedIrqMaskReg  <= (others => '0');
         s_dipSwitchReleasedIrqMaskReg <= (others => '0');
         s_joystickPressedIrqMaskReg   <= (others => '0');
         s_joystickReleasedIrqMaskReg  <= (others => '0');
                                                   else
         if (s_weDipSwitchPressedIrqMask = '1') then
           s_dipSwitchPressedIrqMaskReg <= s_dataInReg( 7 downto 0 );
         end if;
         if (s_weDipSwitchReleasedIrqMask = '1') then
           s_dipSwitchReleasedIrqMaskReg <= s_dataInReg( 7 downto 0 );
         end if;
         if (s_weJoystickPressedIrqMask = '1') then
           s_joystickPressedIrqMaskReg <= s_dataInReg( 9 downto 0 );
         end if;
         if (s_weJoystickReleasedIrqMask = '1') then
           s_joystickReleasedIrqMaskReg <= s_dataInReg( 9 downto 0 );
         end if;
      end if;
      if (s_dipswitchPressedIrqs /= X"00" or s_dipSwitchReleasedIrqs /= X"00") then
        s_irqDipReg(0) <= '1';
                                                                               else
        s_irqDipReg(0) <= '0';
      end if;
      s_irqDipReg(1) <= not(reset) and s_irqDipReg(0);
      if (s_joystickPressedIrqs /="00"&X"00" or s_joystickReleasedIrqs /="00"&X"00") then
        s_irqJoyReg(0) <= '1';
                                                                                     else
        s_irqJoyReg(0) <= '0';
      end if;
      s_irqJoyReg(1) <= not(reset) and s_irqJoyReg(0);
    end if;
  end process makeIrqRegs;
  
  -- Here we define the irq responce delay counter
  s_startCount <= (s_irqDipReg(0) and not (s_irqDipReg(1))) or
                  (s_irqJoyReg(0) and not (s_irqJoyReg(1)));
  s_stopCount  <= (s_irqDipReg(1) and not (s_irqDipReg(0))) or
                  (s_irqJoyReg(1) and not (s_irqJoyReg(0)));
  
  makeDelayCount : process ( clock ) is
  begin
    if (rising_edge( clock )) then
      if (reset = '1' or s_stopCount = '1') then 
        s_countActiveReg <= '0';
                                            else 
        s_countActiveReg <= s_countActiveReg or s_startCount;
      end if;
      if (reset = '1' or s_startCount = '1') then 
        s_delayCounterReg <= (others => '0');
      elsif (s_delayCounterReg /= X"FFFFFFFF" and s_countActiveReg <= '1') then
        s_delayCounterReg <= s_delayCounterReg + to_unsigned(1, 32);
      end if; 
    end if;
  end process makeDelayCount;
  
  -- here we insert the anti-dender modules
  genDips : for n in 7 downto 0 generate
    dipsw : debouncerWithIrq
      port map ( clock            => clock,
                 reset            => reset,
                 nButtonIn        => nDipSwitch(n),
                 scanTick         => s_tick,
                 enablePressIrq   => s_dipSwitchPressedIrqMaskReg(n),
                 enableReleaseIrq => s_dipSwitchReleasedIrqMaskReg(n),
                 resetPressIrq    => s_clearDipSwitchPressedIrqs,
                 resetReleaseIrq  => s_clearDipSwitchReleasedIrqMask,
                 pressIrq         => s_dipswitchPressedIrqs(n),
                 releaseIrq       => s_dipSwitchReleasedIrqs(n),
                 currentState     => s_dipswitchState(n));

  end generate genDips;

  genSwitches : for n in 5 downto 0 generate
    joystick : debouncerWithIrq
      port map ( clock            => clock,
                 reset            => reset,
                 nButtonIn        => nJoystick(n),
                 scanTick         => s_tick,
                 enablePressIrq   => s_joystickPressedIrqMaskReg(n),
                 enableReleaseIrq => s_joystickReleasedIrqMaskReg(n),
                 resetPressIrq    => s_clearJoystickPressedIrqs,
                 resetReleaseIrq  => s_clearJoystickReleasedIrqMask,
                 pressIrq         => s_joystickPressedIrqs(n),
                 releaseIrq       => s_joystickReleasedIrqs(n),
                 currentState     => s_joystickState(n));
    buttons : debouncerWithIrq
      port map ( clock            => clock,
                 reset            => reset,
                 nButtonIn        => nButtons(n),
                 scanTick         => s_tick,
                 enablePressIrq   => s_joystickPressedIrqMaskReg(n+5),
                 enableReleaseIrq => s_joystickReleasedIrqMaskReg(n+5),
                 resetPressIrq    => s_clearJoystickPressedIrqs,
                 resetReleaseIrq  => s_clearJoystickReleasedIrqMask,
                 pressIrq         => s_joystickPressedIrqs(n+5),
                 releaseIrq       => s_joystickReleasedIrqs(n+5),
                 currentState     => s_joystickState(n+5));
  end generate genSwitches;
  
  -- Here the bus output signals are defined
  endTransactionOut <= s_endTransactionOutReg;
  dataValidOut      <= s_busDataOutValidReg;
  addressDataOut    <= s_busDataOutReg;
  s_isMyRead        <= s_isMyTransaction and s_readNotWriteReg and s_beginTransactionReg;
  
  makeDataOut : process ( s_dipswitchState, s_dipswitchPressedIrqs, s_busAddressReg,
                          s_dipSwitchReleasedIrqs, s_joystickState, s_joystickPressedIrqs,
                          s_joystickReleasedIrqs, s_delayCounterReg ) is
  begin
    case (s_busAddressReg( 4 downto 2)) is
      when "000"  => s_busDataOutNext <= X"000000"&s_dipswitchState;
      when "001"  => s_busDataOutNext <= X"000000"&s_dipswitchPressedIrqs;
      when "010"  => s_busDataOutNext <= X"000000"&s_dipSwitchReleasedIrqs;
      when "011"  => s_busDataOutNext <= "00"&X"00000"&s_joystickState;
      when "100"  => s_busDataOutNext <= "00"&X"00000"&s_joystickPressedIrqs;
      when "101"  => s_busDataOutNext <= "00"&X"00000"&s_joystickReleasedIrqs;
      when "110"  => s_busDataOutNext <= std_logic_vector(s_delayCounterReg);
      when others => s_busDataOutNext <= (others => '0');
    end case;
  end process makeDataOut;
  
  makeOutputRegs : process ( clock ) is
  begin
    if (rising_edge( clock )) then
      if (s_isMyRead = '1') then s_busDataOutReg      <= s_busDataOutNext;
                                 s_busDataOutValidReg <= '1';
      elsif (busyIn = '0') then s_busDataOutReg      <= (others => '0');
                                s_busDataOutValidReg <= '0';
      end if;
      if (s_busDataOutValidReg = '1' and busyIn = '0') then 
        s_endTransactionOutReg <= '1';
                                                        else
        s_endTransactionOutReg <= '0';
      end if;
    end if;
  end process makeOutputRegs;
end behave;
