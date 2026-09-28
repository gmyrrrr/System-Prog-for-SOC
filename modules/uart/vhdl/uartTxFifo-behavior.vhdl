--------------------------------------------------------------------------------
-- $RCSfile: uart_fifo.vhdl,v $
--
-- DESC    : OpenRisk 1300 single and multi-processor emulation platform on
--           the UMPP Xilinx FPA based hardware
--
-- EPFL    : LAP
--
-- AUTHORS : T.J.H. Kluter
--
-- CVS     : $Revision: 1.1 $
--           $Date: 2008/05/16 10:43:00 $
--           $Author: kluter $
--           $Source: /home/lapcvs/projects/or1300/modules/uart/vhdl/uart_fifo.vhdl,v $
--
--------------------------------------------------------------------------------
--
-- Copyright (C) 2007/2008 Theo Kluter <ties.kluter@epfl.ch> EPFL-ISIM-LAP
--
--  This file is subject to the terms and conditions of the GNU General Public
--  License.
--
--------------------------------------------------------------------------------
--
--  HISTORY :
--
--  $Log: uart_fifo.vhdl,v $
--  Revision 1.1  2008/05/16 10:43:00  kluter
--  Added UART module
--
--
--------------------------------------------------------------------------------

ARCHITECTURE platform_independent OF uart_fifo IS

  COMPONENT sramLutRam is
    generic( nrOfAddressBits : integer := 5;
             nrOfDataBits    : integer := 32 );
    port ( clock        : in  std_logic;
           writeEnable  : in  std_logic;
           writeAddress : in  unsigned( nrOfAddressBits - 1 downto 0 );
           readAddress  : in  unsigned( nrOfAddressBits - 1 downto 0 );
           writeData    : in  std_logic_vector( nrOfDataBits - 1 downto 0 );
           readData     : out std_logic_vector( nrOfDataBits - 1 downto 0 ));
   end COMPONENT;

   SIGNAL s_full_reg        : std_logic;
   SIGNAL s_empty_reg       : std_logic;
   SIGNAL s_write_addr_reg  : std_logic_vector( 3 DOWNTO 0 );
   SIGNAL s_write_addr_next : std_logic_vector( 3 DOWNTO 0 );
   SIGNAL s_read_addr_reg   : std_logic_vector( 3 DOWNTO 0 );
   SIGNAL s_read_addr_next  : std_logic_vector( 3 DOWNTO 0 );
   SIGNAL s_fifo_we         : std_logic;
   
BEGIN
-- Assign outputs
   fifo_full         <= s_full_reg;
   fifo_empty        <= s_empty_reg;
   
-- Assign control signals
   s_write_addr_next <= unsigned(s_write_addr_reg) + 1;
   s_read_addr_next  <= unsigned(s_read_addr_reg) + 1;
   s_fifo_we         <= '1' WHEN (fifo_re = '0' AND
                                  fifo_we = '1' AND
                                  s_full_reg = '0') OR
                                 (fifo_re = '1' AND
                                  fifo_we = '1') ELSE '0';

-- Assign processes
   make_full : PROCESS( reset , clock , fifo_we , fifo_re ,
                        s_read_addr_reg , s_write_addr_next )
   BEGIN
      IF (clock'event AND (clock = '1')) THEN
         IF (reset = '1' OR 
             (fifo_re = '1' AND fifo_we = '0')) THEN s_full_reg <= '0';
         ELSIF (fifo_we = '1' AND
                fifo_re = '0' AND
                s_write_addr_next = s_read_addr_reg) THEN s_full_reg <= '1';
         END IF;
      END IF;
   END PROCESS make_full;
   
   make_empty : PROCESS( reset , clock , fifo_we , fifo_re ,
                         s_read_addr_next , s_write_addr_reg )
   BEGIN
      IF (clock'event AND (clock = '1')) THEN
         IF (reset = '1' OR
             (fifo_re = '1' AND
              fifo_we = '0' AND
              s_read_addr_next = s_write_addr_reg)) THEN s_empty_reg <= '1';
         ELSIF (fifo_we = '1' AND
                fifo_re = '0') THEN s_empty_reg <= '0';
         END IF;
      END IF;
   END PROCESS make_empty;
   
   make_write_addr_reg : PROCESS( reset , clock , fifo_we , fifo_re ,
                                  s_full_reg , s_write_addr_next )
   BEGIN
      IF (clock'event AND (clock = '1')) THEN
         IF (reset = '1') THEN s_write_addr_reg <= (OTHERS => '0');
         ELSIF ((fifo_we = '1' AND
                 fifo_re = '0' AND
                 s_full_reg = '0') OR
                (fifo_we = '1' AND
                 fifo_re = '1')) THEN s_write_addr_reg <= s_write_addr_next;
         END IF;
      END IF;
   END PROCESS make_write_addr_reg;
   
   make_read_addr_reg : PROCESS( reset , clock , fifo_we , fifo_re ,
                                 s_empty_reg , s_read_addr_next )
   BEGIN
      IF (clock'event AND (clock = '1')) THEN
         IF (reset = '1') THEN s_read_addr_reg <= (OTHERS => '0');
         ELSIF ((fifo_re = '1' AND
                 fifo_we = '0' AND
                 s_empty_reg = '0') OR
                (fifo_re = '1' AND
                 fifo_we = '1')) THEN s_read_addr_reg <= s_read_addr_next;
         END IF;
      END IF;
   END PROCESS make_read_addr_reg;

-- assign components
   fifo_mem : sramLutRam
      GENERIC MAP ( nrOfAddressBits => 4,
                    nrOfDataBits    => 8)
      PORT MAP ( clock        => clock,
                 writeData    => data_in,
                 writeAddress => s_write_addr_reg,
                 WriteEnable  => s_fifo_we,
                 readAddress  => s_read_addr_reg,
                 readData     => data_out);
END platform_independent;
