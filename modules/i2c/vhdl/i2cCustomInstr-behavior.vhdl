architecture behave of i2cCustomInstr is

  signal s_startedI2cReg, s_doneReg, s_oldBusyReg          : std_logic;
  signal s_inDataReg                                       : std_logic_vector(31 downto 0 );
  signal s_i2cData                                         : std_logic_vector( 7 downto 0 );
  signal s_busy, s_ackError, s_isMyCi, s_doneNext          : std_logic;
  signal s_startedI2cNext, s_startI2cRead, s_startI2cWrite : std_logic;
  
  component i2cMaster is
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
  end component;

begin
  ciDone   <= s_doneReg;
  ciResult <= s_ackError&"000"&X"00000"&s_i2cData when s_doneReg = '1' else (others => '0');
  s_isMyCi <= ciStart and ciCke and not(s_startedI2cReg) when ciN = CUSTOM_ID else '0';
  s_startedI2cNext <= '0' when reset = '1' or s_doneReg = '1' else
                      '1' when s_isMyCi = '1' else s_startedI2cReg;
  s_doneNext       <= not(reset) and s_oldBusyReg and not(s_busy);
  s_startI2cRead   <= ciOppA(24) and s_isMyCi;
  s_startI2cWrite  <= not(ciOppA(24)) and s_isMyCi;
  
  makeRegs : process ( clock ) is
  begin
    if (rising_edge( clock )) then
      s_startedI2cReg <= s_startedI2cNext;
      s_oldBusyReg    <= s_busy and not(reset);
      s_doneReg       <= s_doneNext;
      if (s_isMyCi = '1') then
        s_inDataReg     <= ciOppA;
      end if;
    end if;
  end process makeRegs;
  
  master : i2cMaster
    generic map ( CLOCK_FREQUENCY => CLOCK_FREQUENCY,
                  I2C_FREQUENCY   => I2C_FREQUENCY)
    port map ( clock      => clock,
               reset      => reset,
               startWrite => s_startI2cWrite,
               startRead  => s_startI2cRead,
               address    => s_inDataReg( 31 downto 25 ),
               regIn      => s_inDataReg( 15 downto 8 ),
               dataIn     => s_inDataReg( 7 downto 0 ),
               dataOut    => s_i2cData,
               ackError   => s_ackError,
               busy       => s_busy,
               SCL        => SCL,
               SDA        => SDA);

end behave;
