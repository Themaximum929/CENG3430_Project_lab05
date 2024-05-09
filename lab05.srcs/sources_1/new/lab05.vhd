library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity vga_driver is
    Port ( 
        clk: in std_logic;
        hsync, vsync: out std_logic;
        BTNU, BTND, BTNL, BTNR: in std_logic; 
        red, green, blue: out std_logic_vector(3 downto 0)
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
    
begin
    --- Generate 50MHz clock
    comp_clk50MHz: clock_divider generic map (N => 1) port map(clk, clk50MHz);
    --- Generate 10Mhz clock
    comp_clk10Hz: clock_divider generic map (N => 5000000) port map (clk, clk10Hz);
    
    --- Movement process:
    white_ball_movement_proc: process (clk10Hz, BTNU, BTND, BTNL, BTNR)
    begin
           new_white_x <= white_x;
           new_white_y <= white_y;
    
        if rising_edge(clk10Hz) then
            if BTNU = '1' then 
                if white_y - move_pixels > V_START then
                    white_y <= white_y - move_pixels;
                end if;
            elsif BTND = '1' then
                if white_y + move_pixels < V_END then
                    white_y <= white_y + move_pixels;
                end if;
            elsif BTNL = '1' then
                if white_x - move_pixels > H_START then
                    white_x <= white_x - move_pixels;
                end if;
            elsif BTNR = '1' then
                if white_x + move_pixels < H_END then
                    white_x <= white_x + move_pixels;
                end if; 
            end if;
        end if; 
    end process white_ball_movement_proc;
    
    --- Collision detection
    collision_detection_proc: process(clk50MHz)
        variable dx, dy, distance_squared: integer;
        variable vx_diff, vy_diff: integer;
        variable nx, ny, tx, ty, p: integer;
    begin
        report "Collision detection";
        if rising_edge(clk50MHz) then
            report "White ball x: " & integer'image(white_x) & " Blue ball x: " & integer'image(ball_2x);
            -- Calculate vector differences
            dx := new_white_x - ball_2x;
            dy := new_white_y - ball_2y;
            distance_squared := dx*dx + dy*dy;
    
            if distance_squared <= (2 * BALL_RADIUS) ** 2 then
                -- Balls are colliding
                -- Calculate velocity differences
                vx_diff := white_vx - ball_2vx;
                vy_diff := white_vy - ball_2vy;
                if (dx * vx_diff + dy * vy_diff) < 0 then
                    -- Only calculate new velocities if balls are moving towards each other
                    -- Calculate normal and tangent unit vector components
                    
                    p := (vx_diff * dx + vy_diff * dy) / distance_squared;
                    nx := p * dx;
                    ny := p * dy;
                    tx := white_vx - nx;
                    ty := white_vy - ny;
    
                    -- Update velocities for an elastic collision
                    white_vx <= tx - nx;
                    white_vy <= ty - ny;
                    ball_2vx <= ball_2vx + nx;
                    ball_2vy <= ball_2vy + ny;
                end if;
                
                -- Reset positions to avoid sticking balls together
                new_white_x <= white_x;
                new_white_y <= white_y;
            end if;
            
            -- Update positions
            white_x <= new_white_x;
            white_y <= new_white_y;
            ball_2x <= ball_2x + ball_2vx;
            ball_2y <= ball_2y + ball_2vy;
        end if;
    end process collision_detection_proc;
    
--    --- Update Position
--    position_update_proc: process(clk50MHz)
--    begin
--        if rising_edge(clk50MHz) then
--            white_x <= white_x + white_vx;
--            white_y <= white_y + white_vy;
--            ball_2x <= ball_2x + ball_2vx;
--            ball_2y <= ball_2y + ball_2vy;
--        end if;
--    end process position_update_proc; 
    
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
