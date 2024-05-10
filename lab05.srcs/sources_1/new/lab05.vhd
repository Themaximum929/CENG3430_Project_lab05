library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

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
    
    constant move_pixels: integer := 10;
    
    signal new_white_x, new_white_y: integer;
    
    signal collision_detected: std_logic := '0'; -- Latch collision state
    
begin
    --- Generate 50MHz clock
    comp_clk50MHz: clock_divider generic map (N => 1) port map(clk, clk50MHz);
    --- Generate 10Mhz clock
    comp_clk10Hz: clock_divider generic map (N => 5000000) port map (clk, clk10Hz);
    
    --- Movement process: 8 Directions
    white_ball_movement_proc: process (clk10Hz, BTNU, BTNL, BTNR)
        variable direction: integer range 0 to 7 := 0; -- 0 = right, 1 = up-right, 2 = up, ..., 7 = down-right
        variable btnl_pressed, btnr_pressed: std_logic := '0';
    begin
        new_white_x <= white_x;
        new_white_y <= white_y;
            -- Prevent multi-rotation on one click
            if rising_edge(clk10Hz) then
                if BTNL = '1' and btnl_pressed = '0' then
                direction := (direction + 1) mod 8;
                btnl_pressed := '1';
            elsif BTNL = '0' then
                btnl_pressed := '0';
            end if;
    
            if BTNR = '1' and btnr_pressed = '0' then
                direction := (direction - 1) mod 8;
                btnr_pressed := '1';
            elsif BTNR = '0' then
                btnr_pressed := '0';
            end if;
            
            if BTNU = '1' then
                case direction is
                    when 0 =>
                        if white_x + move_pixels < H_END then
                            white_x <= white_x + move_pixels;
                        end if;
                    when 1 =>
                        if white_x + move_pixels < H_END and white_y - move_pixels > V_START then
                            white_x <= white_x + move_pixels;
                            white_y <= white_y - move_pixels;
                        end if;
                    when 2 =>
                        if white_y - move_pixels > V_START then
                            white_y <= white_y - move_pixels;
                        end if;
                    when 3 =>
                        if white_x - move_pixels > H_START and white_y - move_pixels > V_START then
                            white_x <= white_x - move_pixels;
                            white_y <= white_y - move_pixels;
                        end if;
                    when 4 =>
                        if white_x - move_pixels > H_START then
                            white_x <= white_x - move_pixels;
                        end if;
                    when 5 =>
                        if white_x - move_pixels > H_START and white_y + move_pixels < V_END then
                            white_x <= white_x - move_pixels;
                            white_y <= white_y + move_pixels;
                        end if;
                    when 6 =>
                        if white_y + move_pixels < V_END then
                            white_y <= white_y + move_pixels;
                        end if;
                    when 7 =>
                        if white_x + move_pixels < H_END and white_y + move_pixels < V_END then
                            white_x <= white_x + move_pixels;
                            white_y <= white_y + move_pixels;
                        end if;
                    when others => null;
                end case;
            end if;
        end if;
    end process white_ball_movement_proc;
    
    --- Collision detection and handling
        collision_detection_proc: process(clk50MHz)
            variable dx, dy, distance_squared: integer;
        begin
           if rising_edge(clk50MHz) then
               if collision_detected = '0' then
                    Q(1) <= '1';
                    white_x <= new_white_x;
                    white_y <= new_white_y;
                    ball_2x <= ball_2x + ball_2vx;
                    ball_2y <= ball_2y + ball_2vy;
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
    
                    -- Update position of the blue ball by 10 pixels, assuming x direction
                    ball_2x <= ball_2x + 100;
                    

                elsif distance_squared > (2 * BALL_RADIUS) ** 2 then
                    -- No collision or collision has ended
                    collision_detected <= '0'; -- Reset collision detected flag
                end if;
            end if;
        end process collision_detection_proc;
    
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
    data_output_proc: process (hcount, vcount)
    begin
        if ((hcount >= H_START and hcount < H_END) and
            (vcount >= V_START and vcount < V_END)) then
            --- Display Area (draw the square)
    if ( (hcount - white_x) ** 2 + (vcount - white_y) ** 2 <= BALL_RADIUS ** 2) then
                red <= "1111";
                green <= "1111";
                blue <= "1111";
            elsif ( (hcount - ball_2x) ** 2 + (vcount - ball_2y) ** 2 <= BALL_RADIUS ** 2) then
                red <= "0000";
                green <= "0000";
                blue <= "1111";
            else
                red <= "0000"; 
                green <= "0000";
                blue <= "0000";
            end if;
        else
            red <= "0000";
            green <= "0000";
            blue <= "0000"; 
        end if;
    end process data_output_proc;
    
end vga_driver_arch;
