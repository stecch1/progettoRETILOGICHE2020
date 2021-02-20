----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 14.08.2020 18:20:43
-- Design Name: 
-- Module Name: project_reti_logiche - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

package constants is

    constant first_wz_base_address : std_logic_vector := "0000000000000000" ;
    constant address_to_encode : std_logic_vector := "0000000000001000" ;
    constant out_encoded_address : std_logic_vector := "0000000000001001" ;

end constants;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL; 
use work.constants.all;

entity project_reti_logiche is
port (
    i_clk : in std_logic;
    i_start : in std_logic;
    i_rst : in std_logic;
    i_data : in std_logic_vector(7 downto 0);
    o_address : out std_logic_vector(15 downto 0);
    o_done : out std_logic;
    o_en : out std_logic;
    o_we : out std_logic;
    o_data : out std_logic_vector (7 downto 0)
    );
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is
    type states is (s0, address_code_state, read_code_state, address_wz_state, read_wz_state,
                    check_wz_number_state, next_address_wz_state, final_address_no_wz_state, 
                    check_address_in_wz_state, check_address_in_wz_state_2, check_address_in_wz_state_3,
                    check_address_in_wz_state_4, final_address_in_wz_state,final_state,waiting_state,
                    wait_start, done_state, wait_ram);
    
    signal current_state, next_state: states;
    
    signal o_done_next, o_en_next, o_we_next : std_logic := '0';
    signal o_data_next : std_logic_vector(7 downto 0) ;
    signal o_address_next : std_logic_vector(15 downto 0) := "0000000000001000";
    signal current_address, current_address_next: std_logic_vector(15 downto 0) := "0000000000000000";
    signal current_wz, current_wz_next: std_logic_vector(7 downto 0) := "00000000";
    signal code_to_encode, code_to_encode_next: std_logic_vector(7 downto 0);
    signal counter, counter_next: std_logic_vector(3 downto 0) := "0000"; 
    signal one_hot, one_hot_next: std_logic_vector(3 downto 0) := "0000";
    signal reset: std_logic := '0';

begin

    SYNC: process(i_clk, i_rst)    
    begin
    
        if (i_rst = '1') then
        
            reset <= '1';
            o_address <= "0000000000001000";
            current_wz <= "00000000";
            counter <= "0000";
            one_hot <= "0000";
            current_state <= wait_start;
            
        elsif rising_edge(i_clk) then
         
            if (reset = '1') then
                
                o_address <= "0000000000001000";
                current_wz <= "00000000";
                counter <= "0000";
                one_hot <= "0000";
                current_state <= wait_start;
                reset <= '0';
            
            else
            
                o_done <= o_done_next;
                o_en <= o_en_next;
                o_we <= o_we_next;
                o_data <= o_data_next;
                o_address <= o_address_next;
        
                current_address <= current_address_next;
                current_wz <= current_wz_next;
                code_to_encode <= code_to_encode_next;
                counter <= counter_next;
                one_hot <= one_hot_next;
                
                current_state <= next_state;
                
            end if;
             
        end if;
          
    end process SYNC;
    
    
    CASES: process(current_state, i_data, i_start, current_address, current_wz,
                  code_to_encode, counter, one_hot)
    begin
        o_done_next <= '0';
        o_en_next <= '0';
        o_we_next <= '0';
        
            current_address_next <= current_address; 
            current_wz_next <= current_wz;
            code_to_encode_next <= code_to_encode;
            counter_next <= counter; 
            one_hot_next <= one_hot;
                
            next_state <= current_state;
            
        case current_state is
            when wait_start =>
                    if (i_start = '1') then
                        next_state <= s0;
                    else 
                        next_state <= wait_start;
                    end if;  
                    
          when s0 =>
            
                if (i_start = '1') then
                    next_state <= address_code_state;
                end if;
          
          when address_code_state =>
                
                o_en_next <= '1';
                o_we_next <= '0';  
                o_address_next <= address_to_encode;
                next_state <= wait_ram;
                
          when wait_ram =>
          
                next_state <= read_code_state;  
                
                
          when read_code_state =>
                
                code_to_encode_next <= i_data;
                next_state <= waiting_state;     
                
           when waiting_state => 
            
                next_state <= address_wz_state;   
                
           when address_wz_state =>
                
                o_en_next <= '1';
                o_we_next <= '0';
                o_address_next <= first_wz_base_address;
                current_address_next <= first_wz_base_address;
                next_state <= check_wz_number_state;   
                
           when check_wz_number_state =>
                
                 if counter <= "0111" then
                                            
                    next_state <= read_wz_state; 
                 else 
                    next_state <= final_address_no_wz_state;                   
                 end if;  
                 
           when read_wz_state =>
                
                current_wz_next <= i_data;
                next_state <= check_address_in_wz_state;  
                
           when next_address_wz_state =>
           
                o_en_next <= '1';
                o_we_next <= '0';     
                o_address_next <= current_address;
                next_state <= check_wz_number_state;  
                
            when check_address_in_wz_state =>
                
                if current_wz = code_to_encode then
                    one_hot_next <= "0001";
                    next_state <= final_address_in_wz_state;
                else
                    current_wz_next <= current_wz + 1;
                    next_state <= check_address_in_wz_state_2;
                end if;  
                
            when check_address_in_wz_state_2 =>
                
                if current_wz = code_to_encode then
                    one_hot_next <= "0010";
                    next_state <= final_address_in_wz_state;
                else
                    current_wz_next <= current_wz + 1;
                    next_state <= check_address_in_wz_state_3;
                end if;
                    
            when check_address_in_wz_state_3 =>
                
                if current_wz = code_to_encode then
                    one_hot_next <= "0100";
                    next_state <= final_address_in_wz_state;
                else
                    current_wz_next <= current_wz + 1;
                    next_state <= check_address_in_wz_state_4;
                end if;    
                    
            when check_address_in_wz_state_4 =>
                
                if current_wz = code_to_encode then
                    one_hot_next <= "1000";
                    next_state <= final_address_in_wz_state;
                else
                    counter_next <= counter +1;
                    current_address_next <= current_address +1;
                    next_state <= next_address_wz_state;                        
                end if;   
                
            when final_address_in_wz_state =>
                
                o_en_next <= '1';
                o_we_next <= '1';
                o_address_next <= out_encoded_address;
                o_data_next <= ('1' & counter(2 downto 0) & one_hot(3 downto 0));
                next_state <= done_state;  
                
            when final_address_no_wz_state =>   
           
                o_en_next <= '1';
                o_we_next <= '1';
                o_address_next <= out_encoded_address;
                o_data_next <= ('0' & code_to_encode(6 downto 0));
                o_done_next <= '1';
                next_state <= done_state;
                
             when done_state =>
             
                o_done_next <= '1';
                next_state <= final_state;
             
             when final_state =>
                
                if (i_start = '0') then
                    current_address_next <= "0000000000001000";
                    o_address_next <= "0000000000001000";
                    current_wz_next <= "00000000";
                    code_to_encode_next <= "00000000";
                    counter_next <= "0000";
                    one_hot_next <= "0000";
                    next_state <= s0;
                end if;                    
                
        end case;
    end process;                                 

end Behavioral;