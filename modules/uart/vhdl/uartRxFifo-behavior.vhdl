--------------------------------------------------------------------------------
-- $RCSfile: uart_rx_fifo.vhdl,v $
--
-- DESC    : OpenRisk 1300 single and multi-processor emulation platform on
--           the UMPP Xilinx FPA based hardware
--
-- EPFL    : LAP
--
-- AUTHORS : T.J.H. Kluter
--
-- CVS     : $Revision: 1.2 $
--           $Date: 2008/06/11 11:09:29 $
--           $Author: kluter $
--           $Source: /home/lapcvs/projects/or1300/modules/uart/vhdl/uart_rx_fifo.vhdl,v $
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
--  $Log: uart_rx_fifo.vhdl,v $
--  Revision 1.2  2008/06/11 11:09:29  kluter
--  Cleaned up code.
--  Changed memory map.
--  Removed LCD-controller as due to harware problem on UMPP board.
--
--  Revision 1.1  2008/05/16 10:43:00  kluter
--  Added UART module
--
--
--------------------------------------------------------------------------------

ARCHITECTURE platform_independent OF uart_rx_fifo IS

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

   SIGNAL s_full_reg          : std_logic;
   SIGNAL s_empty_reg         : std_logic;
   SIGNAL s_write_addr_reg    : std_logic_vector( 3 DOWNTO 0 );
   SIGNAL s_write_addr_next   : std_logic_vector( 3 DOWNTO 0 );
   SIGNAL s_read_addr_reg     : std_logic_vector( 3 DOWNTO 0 );
   SIGNAL s_read_addr_next    : std_logic_vector( 3 DOWNTO 0 );
   SIGNAL s_fifo_we           : std_logic;
   SIGNAL s_frame_error_reg   : std_logic_vector( 15 DOWNTO 0 );
   SIGNAL s_parity_error_reg  : std_logic_vector( 15 DOWNTO 0 );
   SIGNAL s_break_reg         : std_logic_vector( 15 DOWNTO 0 );
   SIGNAL s_clear_error       : std_logic_vector( 15 DOWNTO 0 );
   SIGNAL s_write_error       : std_logic_vector( 15 DOWNTO 0 );
   SIGNAL s_nr_of_entries_reg : std_logic_vector(  4 DOWNTO 0 );
   
BEGIN
-- Assign outputs
   fifo_full         <= s_full_reg;
   fifo_empty        <= s_empty_reg;
   frame_error_out   <= s_frame_error_reg( conv_integer(unsigned(s_read_addr_reg)) );
   parity_error_out  <= s_parity_error_reg( conv_integer(unsigned(s_read_addr_reg)) );
   break_out         <= s_break_reg( conv_integer(unsigned(s_read_addr_reg)) );
   nr_of_entries     <= s_nr_of_entries_reg;
   
-- Assign control signals
   s_write_addr_next <= unsigned(s_write_addr_reg) + 1;
   s_read_addr_next  <= unsigned(s_read_addr_reg) + 1;
   s_fifo_we         <= '1' WHEN (fifo_re = '0' AND
                                  fifo_we = '1' AND
                                  s_full_reg = '0') OR
                                 (fifo_re = '1' AND
                                  fifo_we = '1') ELSE '0';
   gen_clear_error : FOR n IN 15 DOWNTO 0 GENERATE
      s_clear_error(n)  <= '1' WHEN conv_integer( unsigned(s_read_addr_reg) ) = n AND
                                    ((fifo_re = '1' AND
                                     fifo_we = '0') OR
                                     (fifo_re = '1' AND
                                      fifo_we = '1' AND
                                      conv_integer( unsigned(s_write_addr_reg) ) /= n) OR
                                     clear_error = '1') ELSE '0';
      s_write_error(n)  <= '1' WHEN conv_integer( unsigned(s_write_addr_reg) ) = n AND
                                    fifo_we = '1' AND
                                    s_full_reg = '0' ELSE '0';
   END GENERATE gen_clear_error;
   

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
   
   make_frame_error_reg : PROCESS( reset , clock , s_clear_error , s_write_error ,
                                   frame_error_in )
   BEGIN
      IF (clock'event AND (clock = '1')) THEN
         genloop: FOR n IN 15 DOWNTO 0 LOOP
            IF (s_clear_error(n) = '1' OR
                reset = '1') THEN s_frame_error_reg(n) <= '0';
            ELSIF (s_write_error(n) = '1') THEN s_frame_error_reg(n) <= frame_error_in;
            END IF;
         END LOOP genloop;
      END IF;
   END PROCESS make_frame_error_reg;

   make_parity_error_reg : PROCESS( reset , clock , s_clear_error , s_write_error ,
                                    parity_error_in )
   BEGIN
      IF (clock'event AND (clock = '1')) THEN
        genloop: FOR n IN 15 DOWNTO 0 LOOP
            IF (s_clear_error(n) = '1' OR
                reset = '1') THEN s_parity_error_reg(n) <= '0';
            ELSIF (s_write_error(n) = '1') THEN s_parity_error_reg(n) <= parity_error_in;
            END IF;
         END LOOP genloop;
      END IF;
   END PROCESS make_parity_error_reg;

   make_break_reg : PROCESS( reset , clock , s_clear_error , s_write_error ,
                             break_in )
   BEGIN
      IF (clock'event AND (clock = '1')) THEN
         genloop: FOR n IN 15 DOWNTO 0 LOOP
            IF (s_clear_error(n) = '1' OR
                reset = '1') THEN s_break_reg(n) <= '0';
            ELSIF (s_write_error(n) = '1') THEN s_break_reg(n) <= break_in;
            END IF;
         END LOOP genloop;
      END IF;
   END PROCESS make_break_reg;

   make_fifo_error : PROCESS( reset , clock , s_frame_error_reg , s_parity_error_reg , 
                              s_break_reg )
   BEGIN
      IF (reset = '1') THEN fifo_error <= '0';
      ELSIF (clock'event AND (clock = '1')) THEN
         IF (s_frame_error_reg = "0000000000000000" AND
             s_parity_error_reg = "0000000000000000" AND
             s_break_reg = "0000000000000000") THEN fifo_error <= '0';
                                               ELSE fifo_error <= '1';
         END IF;
      END IF;
   END PROCESS make_fifo_error;
   
   make_nr_of_entries_reg : PROCESS( reset , clock , fifo_we , fifo_re , s_full_reg ,
                                     s_empty_reg )
   BEGIN
      IF (reset = '1') THEN s_nr_of_entries_reg <= (OTHERS => '0');
      ELSIF (clock'event AND (clock = '1')) THEN
         IF (fifo_we = '0' AND
             fifo_re = '1' AND
             s_empty_reg = '0') THEN s_nr_of_entries_reg <= unsigned(s_nr_of_entries_reg) - 1;
         ELSIF (fifo_we = '1' AND
                fifo_re = '0' AND
                s_full_reg = '0') THEN s_nr_of_entries_reg <= unsigned(s_nr_of_entries_reg) + 1;
         END IF;
      END IF; 
   END PROCESS make_nr_of_entries_reg;

-- assign components
   fifo_mem : sramLutRam
      generic map ( nrOfAddressBits => 4,
                    nrOfDataBits    => 8)
      PORT MAP ( clock        => clock,
                 writeData    => data_in,
                 writeAddress => s_write_addr_reg,
                 WriteEnable  => s_fifo_we,
                 readAddress  => s_read_addr_reg,
                 readData     => data_out);
END platform_independent;
