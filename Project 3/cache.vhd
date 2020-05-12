library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cache is
generic(
	ram_size : INTEGER := 32768
);
port(
	clock : in std_logic;
	reset : in std_logic;
	
	-- Avalon interface --
	s_addr : in std_logic_vector (31 downto 0);
	s_read : in std_logic;
	s_readdata : out std_logic_vector (31 downto 0);
	s_write : in std_logic;
	s_writedata : in std_logic_vector (31 downto 0);
	s_waitrequest : out std_logic; 
    
	m_addr : out integer range 0 to ram_size-1;
	m_read : out std_logic;
	m_readdata : in std_logic_vector (7 downto 0);
	m_write : out std_logic;
	m_writedata : out std_logic_vector (7 downto 0);
	m_waitrequest : in std_logic
);
end cache;

architecture arch of cache is

-- declare signals here
type state_type is (init, read_state, write_state, r_memread, r_memwrite, r_memwait, w_memwrite);
type cache_type is array (0 to 31) of std_logic_vector (152 downto 0);

-- Address Structure
-- 23 bits of tag
-- 5 bits of index
-- 4 bits of offset

-- Cache Structure
-- 1 bit valid
-- 1 bit dirty
-- 23 bits tag
-- 128 bits data (4 words * 32 bits)

signal state : state_type;
signal next_state : state_type;
signal cache_signal : cache_type;

-- make circuits here
begin
	process (clock, reset)
	begin
		if reset = '1' then
			state <= init;
		elsif (rising_edge(clock) and clock = '1') then
			state <= next_state;
		end if;
	end process;	
	
	process (s_read, s_write, m_waitrequest, state)
		variable index : INTEGER;	
		variable offset : INTEGER := 0;
		variable count : INTEGER := 0;
		variable addr : std_logic_vector (14 downto 0);

	begin
		index := to_integer(unsigned(s_addr(8 downto 4)));
		offset :=  to_integer(unsigned(s_addr(3 downto 2)));
	
		case state is
		
			when init =>
				s_waitrequest <= '1'; -- set waitrequest high by default
				if s_read = '1' then -- Read
					next_state <= read_state;
				elsif s_write = '1' then -- Write
					next_state <= write_state;
				else
					next_state <= init;
				end if;
				
			when read_state =>
				if cache_signal(index)(152) = '1' and cache_signal(index)(150 downto 128) = s_addr (31 downto 9) then -- Cache Hit
					s_readdata <= cache_signal(index)(127 downto 0) ((32*(offset + 1)) - 1 downto 32*offset);
					s_waitrequest <= '0';
					next_state <= init;
				elsif cache_signal(index)(151) = '0' or  cache_signal(index)(151) = 'U' then -- Cache Miss (Clean)
					next_state <= r_memread;
				elsif cache_signal(index)(151) = '1' then -- Cache Miss (Dirty)
					next_state <= r_memwrite;
				else
					next_state <= read_state;
				end if;


			when write_state =>
				if cache_signal(index)(151) = '1' and next_state /= init and ( cache_signal(index)(152) /= '1' or cache_signal(index)(150 downto 128) /= s_addr (31 downto 9)) then --DIRTY AND MISS
					next_state <= w_memwrite;
				else
					cache_signal(index)(152) <= '1'; -- Valid Bit
					cache_signal(index)(151) <= '1'; -- Dirty Bit
					cache_signal(index)(150 downto 128) <= s_addr (31 downto 9); -- Tag Bits
					cache_signal(index)(127 downto 0)((32*(offset + 1)) - 1 downto 32*offset) <= s_writedata; -- Data Bits				
					s_waitrequest <= '0';
					next_state <= init;
						
				end if;
				

			when r_memwrite =>
				if count < 4 and next_state /= r_memread and m_waitrequest = '1' then 
					addr := cache_signal(index)(133 downto 128) & s_addr (8 downto 0);
					m_addr <= to_integer(unsigned(addr)) + count;
					m_write <= '1';
					m_read <= '0';
					m_writedata <= cache_signal(index)(127 downto 0) ( (8*count + 32*offset + 7) downto  (8*count + 32*offset) );
					count := count + 1;
					next_state <= r_memwrite;

				-- Read from memory
				elsif count = 4 then 
					count := 0;
					next_state <= r_memread;
				else
					m_write <= '0';
					next_state <= r_memwrite;
				end if;
			
				
			when r_memread =>
				if m_waitrequest = '1' then -- Read from memory
					m_addr <= to_integer(unsigned(s_addr (14 downto 0))) + count;
					m_read <= '1';
					m_write <= '0';
					next_state <= r_memwait;
				else
					next_state <= r_memread;
				end if;
				

			when r_memwait =>
				if count <= 3 and m_waitrequest = '0' then
					cache_signal(index)(127 downto 0) ( (8*count + 32*offset + 7) downto  (8*count + 32*offset) ) <= m_readdata;
					m_read <= '0';
					count := count + 1;
					if count = 3 then
						next_state <= r_memwait;
					else
						next_state <= r_memread;
					end if;
				elsif count = 4 then 
					s_readdata <= cache_signal(index)(127 downto 0) ((32*(offset + 1)) - 1 downto 32*offset);
					cache_signal(index)(152) <= '1'; -- Valid
					cache_signal(index)(151) <= '0'; -- Clean
					cache_signal(index)(150 downto 128) <= s_addr (31 downto 9); --Tag

					m_read <= '0';
					m_write <= '0';
					s_waitrequest <= '0';
					count := 0;
					next_state <= init;
				else
					next_state <= r_memwait;
				end if;	

			
			when w_memwrite => 	
				if count < 4 and m_waitrequest = '1' then 
					addr := cache_signal(index)(133 downto 128) & s_addr (8 downto 0);
					m_addr <= to_integer(unsigned (addr)) + count ;
					m_write <= '1';
					m_read <= '0';
					m_writedata <= cache_signal(index)(127 downto 0) ( (8*count + 32*offset + 7) downto  (8*count + 32*offset) );
					count := count + 1;
					next_state <= w_memwrite;
				elsif count = 4 then 
					cache_signal(index)(152) <= '1'; -- Valid Bit
					cache_signal(index)(151) <= '1'; -- Dirty Bit
					cache_signal(index)(150 downto 128) <= s_addr (31 downto 9); -- Tag Bits
				 	cache_signal(index)(127 downto 0) ((32*(offset + 1)) - 1 downto 32*offset) <= s_writedata (31 downto 0); -- Data Bits 			
					count := 0;
					s_waitrequest <= '0';
					m_write <= '0';
					next_state <=init;
				else
					m_write <= '0';
					next_state <= w_memwrite;
				end if;


		end case;
	end process;
	


end arch;