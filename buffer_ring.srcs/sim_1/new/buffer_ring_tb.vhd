library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use std.env.finish;

entity buffer_ring_tb is
end buffer_ring_tb;

architecture Behavioral of buffer_ring_tb is
    -- Generics
    constant clk_period : time := 10 ns;
    constant RAM_WIDTH : natural := 8;
    constant RAM_DEPTH : natural := 1024; 

    -- DUT signals
    signal    clk : std_logic := '1';
    signal    rst : std_logic := '1'; 

        -- Write port
    signal    wr_en   : std_logic := '0';
    signal    wr_data : std_logic_vector(RAM_WIDTH-1 downto 0) := (others => '0');

        -- Read port
    signal    rd_en    : std_logic := '0';
    signal    rd_valid : std_logic ;
    signal    rd_data  : std_logic_vector(RAM_WIDTH-1 downto 0);

        -- Flags 
    signal    empty      : std_logic; 
    signal    empty_next : std_logic;
    signal    full       : std_logic;
    signal    full_next  : std_logic;

        -- The number of elements in the FIFO
    signal fill_count : integer range RAM_DEPTH-1 downto 0;

begin

    DUT: entity work.buffer_ring(Behavioral)
     generic map(
        RAM_WIDTH => RAM_WIDTH,
        RAM_DEPTH => RAM_DEPTH
    )
     port map(
        clk => clk,
        rst => rst,
        wr_en => wr_en,
        wr_data => wr_data,
        rd_en => rd_en,
        rd_valid => rd_valid,
        rd_data => rd_data,
        empty => empty,
        empty_next => empty_next,
        full => full,
        full_next => full_next,
        fill_count => fill_count
    );

    clk <= not clk after clk_period/2;

    PROCC_SEQUENCER: process
    begin
        wait for 10 * clk_period;
        rst <= '0';
        wait until rising_edge(clk);

        wr_en <= '1';

        while full_next = '0' loop
            wr_data <= std_logic_vector(unsigned(wr_data)+1);
            wait until rising_edge(clk);
        end loop;

        wr_en <= '0';

        rd_en <= '1';
        wait until empty_next = '1';

        wait for 10 * clk_period;
        finish;
    end process PROCC_SEQUENCER;

end Behavioral;
