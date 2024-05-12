library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity vga_driver is
    Port ( 
        clk: in std_logic;
        hsync, vsync: out std_logic;
        BTNU, BTND, BTNL, BTNR: in std_logic; 
        red, green, blue: out std_logic_vector(3 downto 0);
       
        Q: out std_logic_vector(7 downto 0) := "00000000"
        );
end vga_driver;

architecture vga_driver_arch of vga_driver is
    signal clk50MHz: std_logic; 
    signal clk10Hz: std_logic;
    signal hcount, vcount: integer := 0;
    
    --- row and column constants ---
    constant H_TOTAL:integer:=1344-1;
    constant H_SYNC:integer:=48-1;
    constant H_BACK:integer:=240-1;
    constant H_START:integer:=48+240-1;
    constant H_ACTIVE:integer:=1024-1;
    constant H_END:integer:=1344-32-1;
    constant H_FRONT:integer:=32-1;
    
    constant V_TOTAL:integer:=625-1;
    constant V_SYNC:integer:=3-1;
    constant V_BACK:integer:=12-1;
    constant V_START:integer:=3+12-1;
    constant V_ACTIVE:integer:=600-1;
    constant V_END:integer:=625-10-1;
    constant V_FRONT:integer:=10-1;
  
    --- Declare clock divider
    component clock_divider is
    generic (N : integer);
    port (
        clk : in std_logic;
        clk_out : out std_logic
    );
    end component;
    
    --- Constants of the square
    --- constant LENGTH: integer := 100;
    --- signal H_TOP_LEFT: integer := (H_START + H_END)/2 - LENGTH/2;
    --- signal V_TOP_LEFT: integer := (V_START + V_END)/2 - LENGTH/2;
    
    --- Constants of the balls
    constant BALL_RADIUS: integer := 20;
    signal white_x: integer := 512;
    signal white_y: integer := 300; 
    signal white_vx: integer := 0;
    signal white_vy: integer := 0; --initial white ball pos, velocity
    
    signal ball_2x: integer := 712;
    signal ball_2y: integer := 300; 
    signal ball_2vx: integer := 0;
    signal ball_2vy: integer := 0;  --initial ball 2 pos, v 
    
    constant move_pixels: integer := 15;
    
    signal new_white_x, new_white_y: integer;
    signal new_ball2_x, new_ball2_y: integer;
    
    signal collision_detected: std_logic := '0'; -- Latch collision state
    
    constant BEAM_LENGTH: integer := 200; -- For beam visualization
    
    signal direction: integer range 0 to 7 := 0; --- White ball direction
    
    signal update_velocities: std_logic;
    signal ball_2x_next, ball_2y_next: integer;
    
    shared variable updated_white_vx, updated_white_vy : integer := 0;
    shared variable updated_ball2_x: integer := 712; 
    shared variable updated_ball2_y: integer := 300; 
    shared variable updated_ball2_vx, updated_ball2_vy : integer := 0;
    
begin
    --- Generate 50MHz clock
    comp_clk50MHz: clock_divider generic map (N => 1) port map(clk, clk50MHz);
    --- Generate 10Mhz clock
    comp_clk10Hz: clock_divider generic map (N => 5000000) port map (clk, clk10Hz);
    
    --- Movement process: 8 Directions
    white_ball_movement_proc: process (clk10Hz, BTNU, BTNL, BTNR)
        --- variable direction: integer range 0 to 7 := 0; -- 0 = right, 1 = up-right, 2 = up, ..., 7 = down-right
        variable btnl_pressed, btnr_pressed: std_logic := '0';
    begin
        new_white_x <= white_x;
        new_white_y <= white_y;
--        new_ball2_x <= ball_2x;
--        new_ball2_y <= ball_2y;
            -- Prevent multi-rotation on one click
            if rising_edge(clk10Hz) then
                if BTNL = '1' and btnl_pressed = '0' then
                    direction <= (direction + 1) mod 8;
                    btnl_pressed := '1';
                elsif BTNL = '0' then
                    btnl_pressed := '0';
                end if;
    
                if BTNR = '1' and btnr_pressed = '0' then
                    direction <= (direction - 1) mod 8;
                    btnr_pressed := '1';
                elsif BTNR = '0' then
                    btnr_pressed := '0';
                end if;
            -- Update ball
            if BTNU = '0' then
                -- Update position based on velocity
                white_x <= white_x + white_vx;
                white_y <= white_y + white_vy;
                
                -- Collision detection wtih wall
                if (white_x < H_START + 100) then
                    white_x <= H_START + 100 + BALL_RADIUS;
                    updated_white_vx := -updated_white_vx;
                elsif (white_x > H_END - 100) then
                    white_x <= H_END - 100 -  BALL_RADIUS;
                    updated_white_vx := -updated_white_vx;
                end if;
                if (white_y < V_START + 60) then
                    white_y <= V_START + BALL_RADIUS + 60;
                    updated_white_vy := -white_vy;
                elsif (white_y > V_END - 100) then
                    white_y <= V_END - BALL_RADIUS - 100;
                    updated_white_vy := -white_vy;
                end if;
                                
--                updated_ball2_x := updated_ball2_x+ ball_2vx;
--                updated_ball2_y := updated_ball2_y + ball_2vy;
                
                -- Apply friction (deceleration)
                if white_vx > 0 then
                    updated_white_vx := white_vx - 1;
                elsif white_vx < 0 then
                    updated_white_vx := white_vx + 1;
                end if;
                if white_vy > 0 then
                    updated_white_vy := white_vy - 1;
                elsif white_vy < 0 then
                    updated_white_vy := white_vy + 1;
                end if;               
                
            else
            --- if BTNU = '1' then
            case direction is
                when 0 =>  -- Right
                    updated_white_vx := move_pixels;
                    updated_white_vy := 0;
                when 1 =>  -- Up-Right
                    updated_white_vx := move_pixels;
                    updated_white_vy := -move_pixels;
                when 2 =>  -- Up
                    updated_white_vx := 0;
                    updated_white_vy := -move_pixels;
                when 3 =>  -- Up-Left
                    updated_white_vx := -move_pixels;
                    updated_white_vy := -move_pixels;
                when 4 =>  -- Left
                    updated_white_vx := -move_pixels;
                    updated_white_vy := 0;
                when 5 =>  -- Down-Left
                    updated_white_vx := -move_pixels;
                    updated_white_vy := move_pixels;
                when 6 =>  -- Down
                    updated_white_vx := 0;
                    updated_white_vy := move_pixels;
                when 7 =>  -- Down-Right
                    updated_white_vx := move_pixels;
                    updated_white_vy := move_pixels;
                when others => null;
            end case;
            end if;
        end if;
    end process white_ball_movement_proc;
    
    --- Collision detection
collision_detection_proc: process(clk10Hz)
    variable dx, dy, distance_squared: integer;
begin
    if rising_edge(clk10Hz) then
        if collision_detected = '0' then
            Q(0) <= '0';
            Q(1) <= '1';
            white_x <= new_white_x;
            white_y <= new_white_y;
        end if;

        -- Calculate vector differences
        dx := new_white_x - ball_2x;
        dy := new_white_y - ball_2y;
        distance_squared := dx*dx + dy*dy;

        -- Check for collision and whether it has been processed
        if distance_squared <= (2 * BALL_RADIUS) ** 2 and collision_detected = '0' then
            -- Balls are colliding and collision has not been processed
            collision_detected <= '1'; -- Set collision detected flag
            Q(0) <= '1';
            Q(1) <= '0';

            updated_ball2_vx := white_vx * 2;
            updated_ball2_vy := white_vy * 2;
        elsif distance_squared > (2 * BALL_RADIUS) ** 2 then
            -- No collision or collision has ended
            collision_detected <= '0'; -- Reset collision detected flag
        end if;

        -- Update blue ball position and velocity
        updated_ball2_x := updated_ball2_x + updated_ball2_vx;
        updated_ball2_y := updated_ball2_y + updated_ball2_vy;

        -- Wall detection for blue ball
        if (updated_ball2_x < H_START + 100) then
            updated_ball2_x := H_START + 100 + BALL_RADIUS;
            updated_ball2_vx := -updated_ball2_vx;
        elsif (updated_ball2_x > H_END - 100) then
            updated_ball2_x := H_END - 100 - BALL_RADIUS;
            updated_ball2_vx := -updated_ball2_vx;
        end if;

        if (updated_ball2_y < V_START + 60) then
            updated_ball2_y := V_START + BALL_RADIUS + 60;
            updated_ball2_vy := -updated_ball2_vy;
        elsif (updated_ball2_y > V_END - 100) then
            updated_ball2_y := V_END - BALL_RADIUS - 100;
            updated_ball2_vy := -updated_ball2_vy;
        end if;

        -- Apply friction (deceleration) for blue ball
        if updated_ball2_vx > 0 then
            updated_ball2_vx := updated_ball2_vx - (move_pixels / 10);
        elsif updated_ball2_vx < 0 then
            updated_ball2_vx := updated_ball2_vx + (move_pixels / 10);
        end if;

        if updated_ball2_vy > 0 then
            updated_ball2_vy := updated_ball2_vy - (move_pixels / 10);
        elsif updated_ball2_vy < 0 then
            updated_ball2_vy := updated_ball2_vy + (move_pixels / 10);
        end if;
    end if;
end process collision_detection_proc;
    
    update_white_velocity_proc: process (clk10Hz)
    begin
        if rising_edge(clk10Hz) then
            white_vx <= updated_white_vx;
            white_vy <= updated_white_vy;
        end if;
    end process update_white_velocity_proc;
    
    update_ball_velocity_proc: process (clk10Hz)
    begin
        if rising_edge(clk10Hz) then
            ball_2x <= updated_ball2_x;
            ball_2y <= updated_ball2_y;
            ball_2vx <= updated_ball2_vx;
            ball_2vy <= updated_ball2_vy;
        end if;
    end process update_ball_velocity_proc;
    
    --- Horizontal Divider
    hcount_proc: process(clk50MHz)
    begin
        if (rising_edge(clk50MHz))
        then
            if(hcount = H_TOTAL) then
                hcount <= 0;
            else
                hcount <= hcount + 1;
            end if;
        end if;
    end process hcount_proc;
    
    --- Vertical Counter
    vcount_proc: process(clk50MHz)
    begin
        if (rising_edge(clk50MHz)) then
            if (hcount = H_TOTAL) then
                if (vcount = V_TOTAL) then
                    vcount <= 0;
                else
                    vcount <= vcount + 1;
                end if;
            end if;
        end if;
    end process vcount_proc;
    
    --- Generate hsync
    hsync_gen_proc: process(hcount)     
    begin
        if (hcount < H_SYNC) then
            hsync <= '0';
        else
            hsync <= '1';
        end if;         
    end process hsync_gen_proc;
    
    --- Generate vsync
    vsync_gen_proc: process(vcount)
    begin
        if (vcount < V_SYNC) then
            vsync <= '0';
        else
            vsync <= '1';
        end if;
    end process vsync_gen_proc;
    
    --- Generate RGB signals for 1024x600 display area
data_output_proc: process (hcount, vcount, white_x, white_y, white_vx, white_vy, ball_2x, ball_2y)
begin
    if ((hcount >= H_START and hcount < H_END) and
        (vcount >= V_START and vcount < V_END)) then
         -- Display Area
        red <= "0000";
        green <= "0000";
        blue <= "0000";
        
        -- Display Area (draw the first and second ball and the beam for the first ball)
        if ((hcount - white_x)**2 + (vcount - white_y)**2 <= BALL_RADIUS**2) then
            -- Draw first ball in white
            red <= "1111";
            green <= "1111";
            blue <= "1111";
        elsif ((hcount - ball_2x)**2 + (vcount - ball_2y)**2 <= BALL_RADIUS**2) then
            -- Draw second ball in blue
            red <= "0000";
            green <= "0000";
            blue <= "1111";
        
        else
            -- Draw the beam based on the direction
            case direction is
                when 0 =>  -- Right
                    if hcount > white_x and hcount <= white_x + BEAM_LENGTH and abs(vcount - white_y) <= 2 then
                        red <= "1111";
                        green <= "0000";
                        blue <= "0000";
                    end if;
                when 7 =>  -- Down-Right
                    if hcount > white_x and vcount > white_y and
                       abs((hcount - white_x) - (vcount - white_y)) <= 2 and
                       (hcount - white_x) <= BEAM_LENGTH and (vcount - white_y) <= BEAM_LENGTH then
                        red <= "1111";
                        green <= "0000";
                        blue <= "0000";
                    end if;
                when 6 =>  -- Down
                    if vcount > white_y and vcount <= white_y + BEAM_LENGTH and abs(hcount - white_x) <= 2 then
                        red <= "1111";
                        green <= "0000";
                        blue <= "0000";
                    end if;
                when 5 =>  -- Down-Left
                    if hcount < white_x and vcount > white_y and
                       abs((white_x - hcount) - (vcount - white_y)) <= 2 and
                       (white_x - hcount) <= BEAM_LENGTH and (vcount - white_y) <= BEAM_LENGTH then
                        red <= "1111";
                        green <= "0000";
                        blue <= "0000";
                    end if;
                when 4 =>  -- Left
                    if hcount < white_x and hcount >= white_x - BEAM_LENGTH and abs(vcount - white_y) <= 2 then
                        red <= "1111";
                        green <= "0000";
                        blue <= "0000";
                    end if;
                when 3 =>  -- Up-Left
                    if hcount < white_x and vcount < white_y and
                       abs((white_x - hcount) - (white_y - vcount)) <= 2 and
                       (white_x - hcount) <= BEAM_LENGTH and (white_y - vcount) <= BEAM_LENGTH then
                        red <= "1111";
                        green <= "0000";
                        blue <= "0000";
                    end if;
                when 2 =>  -- Up
                    if vcount < white_y and vcount >= white_y - BEAM_LENGTH and abs(hcount - white_x) <= 2 then
                        red <= "1111";
                        green <= "0000";
                        blue <= "0000";
                    end if;
                when 1 =>  -- Up-Right
                    if hcount > white_x and vcount < white_y and
                       abs((hcount - white_x) - (white_y - vcount)) <= 2 and
                       (hcount - white_x) <= BEAM_LENGTH and (white_y - vcount) <= BEAM_LENGTH then
                        red <= "1111";
                        green <= "0000";
                        blue <= "0000";
                    end if;
            end case;
        end if;
    else
        -- Outside display area
        red <= "0000";
        green <= "0000";
        blue <= "0000"; 
    end if;
end process data_output_proc;
    
end vga_driver_arch;