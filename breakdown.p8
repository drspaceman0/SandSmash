pico-8 cartridge // http://www.pico-8.com
version 41
__lua__

--- breakdown.p8

SCREEN_SIZE = 64

game_states = {
    splash = 0,
    game = 1,
    gameover = 2
}

state = game_states.splash

MIN_X = 0
MIN_Y = 0
MAX_X = SCREEN_SIZE - 1
MAX_Y = SCREEN_SIZE - 1

bm = {}
Entity = {}
Entity.__index = Entity

cool_colors = { 8, 9, 10, 11, 12, 13, 14 }
cool_colors_index = 0

printh("START")
score = 0
function change_state(new_state)
    if new_state == game_states.splash then
        state = game_states.splash
        init_spash()
    elseif new_state == game_states.game then
        state = game_states.game
        init_game()
    elseif new_state == game_states.gameover then
        state = game_states.gameover
        init_gameover()
    end
end

function restart()
    change_state(game_states.game)
end

--particles
effects = {}

--effects settings
trail_width = 1.5
trail_colors = { 12, 13, 1 }
trail_amount = 2

fire_width = 3
fire_colors = { 8, 9, 10, 5 }
fire_amount = 3

explode_size = 2
explode_colors = { 8, 9, 6, 5 }
explode_amount = 2

max_effects = 680
function add_fx(x, y, die, dx, dy, grav, grow, shrink, r, c_table)
    local fx = {
        x = x,
        y = y,
        t = 0,
        die = die,
        dx = dx,
        dy = dy,
        grav = grav,
        grow = grow,
        shrink = shrink,
        r = r,
        c = 0,
        c_table = c_table
    }
    add(effects, fx)
end

function draw_fx()
    for fx in all(effects) do
        --draw pixel for size 1, draw circle for larger
        if fx.r <= 1 then
            pset(fx.x, fx.y, fx.c)
        else
            circfill(fx.x, fx.y, fx.r, fx.c)
        end
    end
end

function update_fx()
    for fx in all(effects) do
        --lifetime
        fx.t += 1
        if fx.t > fx.die then del(effects, fx) end

        --color depends on lifetime
        if fx.t / fx.die < 1 / #fx.c_table then
            fx.c = fx.c_table[1]
        elseif fx.t / fx.die < 2 / #fx.c_table then
            fx.c = fx.c_table[2]
        elseif fx.t / fx.die < 3 / #fx.c_table then
            fx.c = fx.c_table[3]
        else
            fx.c = fx.c_table[4]
        end

        --physics
        if fx.grav then fx.dy += .5 end
        if fx.grow then fx.r += .1 end
        if fx.shrink then fx.r -= .1 end

        --move
        fx.x += fx.dx
        fx.y += fx.dy
    end
end

-- motion trail effect
function trail(x, y, w, c_table, num)
    for i = 0, num do
        --settings
        add_fx(
            x + rnd(w) - w / 2, -- x
            y + rnd(w) - w / 2, -- y
            40 + rnd(30), -- die
            0, -- dx
            0, -- dy
            false, -- gravity
            false, -- grow
            false, -- shrink
            1, -- radius
            c_table -- color_table
        )
    end
end

-- explosion effect
function explode(x, y, r, c_table, num)
    for i = 0, num do
        --settings
        add_fx(
            x, -- x
            y, -- y
            30 + rnd(25), -- die
            rnd(2) - 1, -- dx
            rnd(2) - 1, -- dy
            false, -- gravity
            false, -- grow
            true, -- shrink
            r, -- radius
            c_table -- color_table
        )
    end
end

-- fire effect
function fire(x, y, w, c_table, num)
    for i = 0, num do
        --settings
        add_fx(
            x + rnd(w) - w / 2, -- x
            y + rnd(w) - w / 2, -- y
            30 + rnd(10), -- die
            0, -- dx
            -.5, -- dy
            false, -- gravity
            false, -- grow
            true, -- shrink
            2, -- radius
            c_table -- color_table
        )
    end
end

-- Entities (aka Player, enemies, etc)
function Entity.create(arg)
    -- x, y, w, h, c, update, draw, speed
    local new_entity = {}
    setmetatable(new_entity, Entity)

    new_entity.x = arg.x or 0
    new_entity.y = arg.y or 0
    new_entity.h = arg.h or 1
    new_entity.w = arg.w or 1
    new_entity.dx = arg.dx or 0
    new_entity.dy = arg.dy or 0
    new_entity.time = arg.time or 100
    new_entity.c = arg.c or 7
    new_entity.speed = arg.speed or 1
    new_entity.update = arg.update or nil
    new_entity.draw = arg.draw or nil
    new_entity.center_x = 0 or 0

    return new_entity
end

function Entity:collide(other_entity)
    return other_entity.x < self.x + self.w and self.x < other_entity.x + other_entity.w
            and other_entity.y < self.y + self.h and self.y < other_entity.y + other_entity.h
end

function update_player(o)
    -- left
    player.dx = 0
    if btn(0) then
        player.x = max(player.x - o.speed, MIN_X)
        player.dx = -o.speed
    end
    -- right
    if btn(1) then
        player.x = min(player.x + o.speed, MAX_X - player.w + 1)
        player.dx = o.speed
    end
    if stat(34) == 1 then
        local mouse_x = stat(32)
        if mouse_x < MAX_X / 2 then
            player.x = max(player.x - o.speed, MIN_X)
            player.dx = -o.speed
        else
            player.x = min(player.x + o.speed, MAX_X - player.w + 1)
            player.dx = o.speed
        end
    end

    o.center_x = o.x + flr(o.w / 2)
    if t() % player_color_change_interval == 0 then
        player.c = bm_new_layer_color
    end
end

function draw_player(o)
    rectfill(o.x, o.y, o.x + o.w - 1, o.y + o.h, o.c)
end

player_color_change_interval = 5
player_y = MAX_Y - 3
player_w_min = 12
player = {}
default_player_speed = 2
player_speed = default_player_speed

function init_player()
    player = Entity.create { x = MIN_X + 32, y = player_y, h = 1, w = player_w_min, c = 8, update = update_player, draw = draw_player, speed = player_speed }
    player.collision = false
end

-- Pico8 game funtions

function _init()
    poke(0x5f2c, 3)
    -- 64 bit mode
    poke(0x5F2D, 1)
    -- enable mouse
    cls()
    state = game_states.splash
    init_spash()
    -- state = game_states.game
    -- init_game()
end

-- function _update()
function _update()
    if state == game_states.splash then
        update_splash()
    elseif state == game_states.game then
        update_game()
    elseif state == game_states.gameover then
        update_gameover()
    end
end

function _draw()
    cls()
    if state == game_states.splash then
        draw_splash()
    elseif state == game_states.game then
        draw_game()
    elseif state == game_states.gameover then
        draw_gameover()
    end
end

time_at_init_game = 0
ready_start_timer = 30
function init_game()
    printh("NEW STATE: game")
    bm = {}
    init_bitmap { include_blocks = true }
    init_player()
    effects = {}
    balls = {}
    pickups = {}
    score = 0
    total_balls = 0
    total_xp = 0
    new_big_ball()
    time_at_init_game = t()
    start_ceiling_drop = false
    start_ceiling_drop_timer = 120

    ready_start_timer = 30
    -- test_ball_bounce()
    -- confetti()
end

-- SPLASH
splash_timer = 0
function init_spash()
    printh("NEW STATE: splash")
    init_bitmap { include_blocks = false }
    splash_timer = 0
    balls = {}
    init_player()
    player.y = 300
end

transition_stop_drawing_splash = false
max_circles = 0
function update_splash()
    if btnp(5) and not enable_transition then
        enable_transition = true
        for i = MIN_X, MAX_X, 4 do
            for j = MIN_Y, MAX_Y, 4 do
                local c = cool_colors[min(#cool_colors, max(1, flr(j / 7)))]
                new_circle(i, j, c, (i + j) / 10)
            end
        end
        max_circles = #circles
    end

    if splash_timer % 4 == 0 then
        add_layer {}
    end

    if splash_timer > 30 and #balls == 0 then
        new_big_ball()
        balls[1].x = flr(rnd(MAX_X) + 8)
        balls[1].y = 40
        balls[1].dy = -1
    end

    if enable_transition then
        update_object_table(circles)
        if #circles < max_circles and not transition_stop_drawing_splash then
            transition_stop_drawing_splash = true
        elseif #circles <= 0 then
            printh("CHANGE TO GAME")
            change_state(game_states.game)
            return
        end
    end

    update_object_table(balls)
    splash_timer += 1
end

function new_circle(x, y, c, t)
    add(circles, { x = x, y = y, r = 0, step = 0.4, c = c, update = update_circle, draw = draw_circle, start_timer = t })
end

function draw_circle(c)
    if c.r > 1 then
        circfill(c.x, c.y, c.r, c.c)
    end
end

function update_circle(c)
    c.start_timer -= 1
    if c.start_timer > 0 then return true end
    c.r += c.step
    if c.r >= 4 then
        c.step *= -1
    end
    return c.r >= 0
end

blink_text = false
function draw_splash()
    if not transition_stop_drawing_splash then
        draw_bitmap()
        -- draw_table(balls)
        local text = "color"
        write(text, text_x_pos(text), 20, 7)
        text = "cascade"
        write(text, text_x_pos(text), 27, 7)

        if t() % 1 == 0 then blink_text = not blink_text end

        if blink_text then write("press z", 16, 54, 7) end
    end
    if enable_transition then
        draw_transition()
    end
end

-- GAME

enable_transition = false

circles = {}
function draw_transition()
    draw_table(circles)
end

function draw_game()
    -- rect(0, 0, SCREEN_SIZE - 1, SCREEN_SIZE - 1, 8)
    draw_bitmap()
    player:draw()

    draw_table(balls)
    draw_table(pickups)

    draw_fx()
    if activate_ma_lazah then draw_lazer() end
    doshake()
    -- draw_xp_bar()

    draw_levelup()
    draw_sticky()

    if ready_start_timer > 0 then
        local text = "ready?"
        if ready_start_timer < 10 then
            text = "go!"
        end
        write(text, text_x_pos(text), 20, 7)
    end

    -- early_start()
end

function early_start()
    bm_new_layer_frequency = 2
    start_ceiling_drop = true
end

-- GAME OVER

function update_gameover()
    if btnp(4) or btnp(5) then
        restart()
    end

    -- player:update() --- dont update player
    -- update_objects()

    update_bitmap()
    if activate_ma_lazah then update_lazer() end

    update_object_table(balls)
    update_object_table(pickups)

    update_fx()
end

function init_gameover()
    printh("NEW STATE: gameover")
    player.y = 400
    score = total_balls
end

function draw_gameover()
    draw_game()
    -- write(text, text_x_pos(text), 28, 7)
    write("game over", text_x_pos("game over"), 20, 7)
    local score_text = "★ " .. score
    write(score_text, text_x_pos(score_text) - 2, 30, 7)
end

-- Utils

-- calculate center position in X axis
-- this is asuming the text uses the system font which is 4px wide
function text_x_pos(text)
    local letter_width = 4

    -- first calculate how wide is the text
    local width = #text * letter_width

    -- if it's wider than the screen then it's multiple lines so we return 0
    if width > SCREEN_SIZE then
        return 0
    end

    return SCREEN_SIZE / 2 - flr(width / 2)
end

-- prints black bordered text
function write(text, x, y, color)
    for i = 0, 2 do
        for j = 0, 2 do
            print(text, x + i, y + j, 0)
        end
    end
    print(text, x + 1, y + 1, color)
end
------- DEBUG FUNCTIONS

function quote(t, sep)
    if type(t) ~= "table" then
        return tostr(t)
    end

    local s = "{"
    for k, v in pairs(t) do
        s ..= tostr(k) .. "=" .. quote(v)
        s ..= sep or ","
    end
    return s .. "}"
end

function get_next_cool_color()
    cool_colors_index += 1
    if cool_colors_index > #cool_colors then cool_colors_index = 1 end
    return cool_colors[cool_colors_index]
end

function get_rand_cool_color()
    return cool_colors[flr(rnd(#cool_colors)) + 1]
end

--------- START

function init_bitmap(arg)
    bm = {}
    bm_new_layer_frequency = bm_new_layer_frequency_default
    bm_layer_count = 0
    for i = MIN_X, MAX_X + 1 do
        bm[i] = {}
        for j = MIN_Y, MAX_Y + 1 do
            bm[i][j] = 0
        end
    end

    if arg.include_blocks then
        for i = 0, 4 do
            bitmap_brick { x = 10 + 8 * i, y = 10, w = 6, h = 3, c1 = 13, c2 = 12 }
        end
        for i = 0, 4 do
            bitmap_brick { x = 10 + 8 * i, y = 15, w = 6, h = 3, c1 = 9, c2 = 10 }
        end
        for i = 0, 4 do
            bitmap_brick { x = 10 + 8 * i, y = 20, w = 6, h = 3, c1 = 8, c2 = 14 }
        end
    end
end

function bitmap_brick(arg)
    x, y, w, h, c1, c2 = arg.x, arg.y, arg.w, arg.h, arg.c1, arg.c2

    for i = 0, w do
        for j = 0, h do
            bm[x + i][y + j] = c1
        end
    end

    for i = 1, w - 1 do
        for j = 1, h - 1 do
            bm[x + i][y + j] = c2
        end
    end
end

bm_layer_count = 0
bm_new_layer_color = 11
bm_new_layer_frequency_default = 18
-- bm_new_layer_frequency_default = 5
bm_new_layer_frequency = bm_new_layer_frequency_default

bm_new_layer_frequency_decrease = 0.5
bm_new_layer_frequency_min = 4
bm_new_layer_timer = bm_new_layer_frequency
bm_new_layer_frequency_per_layers = #cool_colors

start_ceiling_drop = false
start_ceiling_drop_timer = 120

function update_bitmap()
    if not start_ceiling_drop then
        start_ceiling_drop_timer -= 1
        if start_ceiling_drop_timer <= 0 then start_ceiling_drop = true end
        return
    end
    bm_new_layer_timer -= 1
    if bm_new_layer_timer <= 0 then
        bm_new_layer_timer = bm_new_layer_frequency
        if sticky_mode_activated then
            return
        end
        add_layer {}
        if bm_layer_count % bm_new_layer_frequency_per_layers == 0 then
            bm_new_layer_frequency = max(bm_new_layer_frequency - bm_new_layer_frequency_decrease, bm_new_layer_frequency_min)
        end

        if is_game_over() then
            printh("game over!!")
            if state == game_states.game then change_state(game_states.gameover) end
        end
    end
    -- check for game over
end

function is_game_over()
    for i = MIN_X, MAX_X do
        if bm[i][MAX_Y] != 0 then return true end
    end
    return false
end

layer_randomness = 0.2
edge_width = 3
edge_randomness = 0.6
layer_max_height_at_x = {}
for i = MIN_X, MAX_X do
    layer_max_height_at_x[i] = 0
end
-- layer_max_height_total = 0
layer_height_avg = 0
function add_layer(arg)
    if bm_layer_count % 4 == 0 then
        bm_new_layer_color = get_next_cool_color()
    end

    -- for i = MIN_X, MAX_X do
    --     layer_max_height_at_x[i] = 0
    -- end
    -- layer_max_height_total = 0
    for i = MIN_X, MAX_X do
        if rnd(1) > layer_randomness then
            local prev_color = arg.color or bm_new_layer_color
            for j = MIN_Y, MAX_Y + 1 do
                local c = bm[i][j]
                bm[i][j] = prev_color
                prev_color = c
                if bm[i][j] > 0 then
                    layer_max_height_at_x[i] = j
                    -- layer_max_height_total = max(j, layer_max_height_total)
                end
            end
        end
    end
    layer_height_avg = 0
    for i = MIN_X, MAX_X do
        layer_height_avg += layer_max_height_at_x[i]
    end
    layer_height_avg /= MAX_X
    printh(layer_height_avg)
    -- loosen_some_sand {}
    bm_layer_count += 1
end

function loosen_some_sand(arg)
    -- local n = arg.amount or flr(rnd(14))

    local x = arg.x or flr(rnd(MAX_X) + 1)
    local s = get_max_sand_at_x(x)
    local c = arg.c or s.c
    new_ball { x = x, y = s.y + 1, w = 1, h = 1, dx = 0, dy = 1, c = c }
    -- for i = 0, n do
    --     local x = flr(rnd(MAX_X) + 1)
    --     local s = get_max_sand_at_x(x)
    --     new_ball { x = x, y = s.y + 1, w = 1, h = 1, dx = 0, dy = 1, c = s.c }
    -- end
end

function get_max_sand_at_x(x)
    printh(x)
    local y = layer_max_height_at_x[x] or MIN_Y
    return { x = x, y = y, c = bm[x][y] }
end

function draw_bitmap()
    for i = MIN_X, MAX_X do
        for j = MAX_Y, MIN_Y, -1 do
            pset(i, j, bm[i][j])
        end
    end

    -- draw max
    -- for i = MIN_X, MAX_X do
    --     local j = layer_max_height_at_x[i]
    --     pset(i, j, 7)
    -- end
end

function test_ball_bounce()
    for x = 0, player.w - 1 do
        new_ball { x = player.x + x, y = player.y - 20, w = 1, h = 1, dx = 0, dy = 1, c = get_rand_cool_color() }
    end
end

function confetti()
    for x = MIN_X + 32, MAX_X do
        for y = MIN_Y + 8, 17 do
            new_ball { x = x, y = y * 2, w = 1, h = 1, dx = 0, dy = 0.2 + rnd(0.5), c = x + y % 16 }
        end
    end
end

total_xp = 0
xp_before_pickup = 200
function absorb_xp()
    total_xp += 1
    xp_ratio = total_xp / xp_required
    -- if total_xp % xp_before_pickup == 0 then
    --     new_pickup {}
    -- end
    -- printh("XP: " .. total_xp)
end

big_ball_pierce_limit = 4
function update_big_ball(b)
    b.times_hit_sand = 0
    b.x += b.dx * b.speed
    b.y += b.dy * b.speed
    if b.x > MAX_X - b.w - 1 or b.x < MIN_X then
        b.x = max(min(b.x, MAX_X - b.w), MIN_X)
        b.dx *= -1
    end
    if b.y < MIN_Y then
        b.y = max(b.y, MIN_Y)
        b.dy *= -1
    end
    if b.y > MAX_Y then return false end

    if b:collide(player) then
        if b.x + b.w / 2 < player.center_x then b.dx = -1 end
        if b.x + b.w / 2 > player.center_x then b.dx = 1 end

        b.y = player.y - 4
        b.dy = -1
    end

    for i = 0, b.w do
        for j = 0, b.h do
            local x, y = flr(b.x) + i, flr(b.y) + j
            if y < MAX_Y and bm[x][y] != 0 then
                new_ball { x = x, y = y, w = 1, h = 1, dx = 0, dy = 1, c = bm[x][y] }
                bm[x][y] = 0
                b.n_pierced -= 1
                if b.n_pierced <= 0 then
                    b.dy *= -1
                    b.n_pierced = big_ball_pierce_limit
                end
            end
        end
    end

    return true
    -- b.time -= 1
    -- return b.time > 0
end

function draw_big_ball(b)
    for c in all(b.prev_pos) do
        rectfill(c[1], c[2], c[1] + 4, c[2] + 4, 7)
    end
    spr(0, b.x, b.y)
end

xp_y_start = MAX_Y - 2
xp_required = 200
xp_ratio = 0
function draw_xp_bar()
    for i = MIN_X, min(MAX_X, flr(MAX_X * xp_ratio)) do
        pset(i, MAX_Y, player.c)
    end
end

--  { 8, 9, 10, 11, 12, 13, 14 }
function draw_ball(b)
    pset(b.x, b.y, b.c)
end

function get_relative_color(b)
    return cool_colors[min(#cool_colors, max(1, flr(b.y / 7)))]
end

function update_ball(b)
    local x, y
    -- printh(quote(b))
    b.x += b.dx * b.speed
    b.y += b.dy * b.speed

    if b.x > MAX_X or b.x < MIN_X then
        x, y = flr(b.x), flr(b.y)
        if b.x < MIN_X then
            -- sometimes skips edge sand.
            if bm[MIN_X + 1][y] != 0 then
                new_ball { x = x, y = y, w = 1, h = 1, dx = 0, dy = 1, c = bm[MIN_X + 1][y] }
                bm[MIN_X + 1][y] = 0
            end
            b.x *= -1
        else
            -- sometimes skips edge sand.
            if bm[MAX_X][y] != 0 then
                new_ball { x = x, y = y, w = 1, h = 1, dx = 0, dy = 1, c = bm[MAX_X][y] }
                bm[MAX_X][y] = 0
            end
            b.x = 2 * MAX_X - b.x
        end
        -- b.x = max(min(b.x, MAX_X), MIN_X)
        b.dx *= -1
    end
    if b.y < MIN_Y then
        b.y = max(b.y, MIN_Y)
        b.dy *= -1
    end
    if b.y > MAX_Y then return false end

    -- player collision
    if b:collide(player) then
        player.collision = true
        if b.c == player.c then
            absorb_xp()
        end

        -- b.c = player.c

        -- b.dx = player.dx / 2 + (b.x - player.center_x) / 4.5

        if sticky_mode_activated then
            add_sticky(flr(b.x) - player.x, b.c)
            return false
        end

        calculate_player_reflect(b)
    end

    -- bitmap collision
    x, y = flr(b.x), flr(b.y)
    if bm[x][y] != 0 then
        b.dy = 1
        new_ball { x = x, y = y, w = 1, h = 1, dx = 0, dy = 1, c = bm[x][y] }

        bm[x][y] = 0
    end

    b.time -= 1
    return b.time > 0
end

reflect_magnitude = 100
player_speed_dampining = 2
function calculate_player_reflect(b)
    -- x

    local b_offset = b.x - player.center_x
    b.dx = b_offset / reflect_magnitude + player.dx / player_speed_dampining

    -- if player.dx != 0 then
    --     b.dx = player.dx / 2
    -- else
    --     if b.x + 2 < player.center_x then b.dx = -1 end
    --     if b.x - 2 > player.center_x then b.dx = 1 end
    -- end

    -- y
    b.dy *= -1
    b.y = player.y - 1
end

function new_big_ball()
    local b = new_ball {
        x = 52, y = 40, w = 4, h = 4, dx = -1, dy = 1, c = 7,
        update = update_big_ball, draw = draw_big_ball
    }
    b.n_pierced = big_ball_pierce_limit
end

default_ball_time = 1200
default_ball_speed = 1
ball_speed = default_ball_speed
balls = {}
max_balls = 1280
total_balls = 0
function new_ball(arg)
    total_balls += 1
    if #balls >= 1280 then return end
    -- x, y, w, h, dx, dy, c
    local b = Entity.create {
        x = arg.x, y = arg.y, h = arg.h, w = arg.w,
        dx = arg.dx, dy = arg.dy, time = default_ball_time, c = arg.c, update = arg.update or update_ball,
        draw = arg.draw or draw_ball, speed = ball_speed
    }
    add(balls, b)
    if #balls % 100 == 0 then printh("#balls: " .. #balls) end
    -- printh("# of balls: " .. #balls)
    return b
end

pickups = {}
lazer_spr = 2
sticky_spr = 18
lazer_c = 12
pickup_types = { "lazer", "sticky" }
last_pickup = -1
function new_pickup(arg)
    local w = 6
    local h = 5
    local x = MIN_X + 4 + flr(rnd(MAX_X - w - 4))
    local o = Entity.create {
        x = x, y = 0, h = h, w = w,
        dx = 0, dy = 1, time = 9999, c = lazer_c, update = update_pickup,
        draw = draw_pickup, speed = 2
    }
    local rand_type = pickup_types[flr(rnd(#pickup_types)) + 1]
    while rand_type == last_pickup do
        rand_type = pickup_types[flr(rnd(#pickup_types)) + 1]
    end
    last_pickup = rand_type
    o.pickup_type = rand_type
    if rand_type == "lazer" then
        o.spr = lazer_spr
    elseif rand_type == "sticky" then
        o.spr = sticky_spr
    else
        printh("i dont know what pickup type that was")
    end

    add(pickups, o)
    spawned_pickup_timer = spawned_pickup_timer_wait
end

function update_pickup(o)
    o.x += o.dx
    o.y += o.dy
    if o:collide(player) then
        if o.pickup_type == "lazer" then
            activate_lazer()
        elseif o.pickup_type == "sticky" then
            activate_sticky()
        else
            printh("i dont know what pickup type that was: " .. o.pickup_type)
        end
        return false
    end
    return o.y < MAX_Y
end

function draw_pickup(o)
    spr(o.spr, o.x, o.y)
end

function draw_table(table)
    for o in all(table) do
        o:draw()
    end
end

function is_a_powerup_activated()
    return activate_ma_lazah or sticky_mode_activated
end

lazer_w = 8
lazer_border_color = 6
lazer_color = 7
lazer_x = 0

lazer_duration = 30
lazer_timer = lazer_duration
lazer_residue = {}

function activate_lazer()
    activate_ma_lazah = true
    lazer_timer = lazer_duration
    local rnd_x = rnd(5) - 2
    lazer_x = flr(player.center_x - lazer_w / 2 + rnd_x)
    lazer_range = { lazer_x, lazer_x + lazer_w }

    lazer_residue = {}
end

function update_lazer()
    if not activate_ma_lazah then return end
    local rnd_x = rnd(5) - 2
    lazer_x = flr(player.center_x - lazer_w / 2 + rnd_x)

    for i = max(MIN_X, lazer_x - 1), min(MAX_X, lazer_x + lazer_w + 1) do
        for j = MIN_Y, MAX_Y do
            if bm[i][j] != 0 then
                if rnd(1) > 0.4 then add(lazer_residue, { x = i, y = flr(rnd(MAX_Y)), c = lazer_color }) end

                if #effects < max_effects then
                    explode(i, j, explode_size, explode_colors, bm[i][j])
                end
                bm[i][j] = 0
                shake = min(shake + 0.2, max_shake)
            end
        end
    end

    lazer_timer -= 1
    if lazer_timer <= 0 then
        for o in all(lazer_residue) do
            new_ball { x = o.x, y = o.y, w = 1, h = 1, dx = 0, dy = 1, c = o.c }
        end

        activate_ma_lazah = false
        lazer_residue = {}
    end
end

function draw_lazer()
    for o in all(lazer_residue) do
        pset(o.x, o.y, o.c)
    end
    rectfill(lazer_x, MIN_Y, lazer_x + lazer_w, player.y - 1, lazer_border_color)
    rectfill(lazer_x + 1, MIN_Y, lazer_x + lazer_w - 1, player.y - 1, lazer_color)
end

ball_speed_increase = 1.2
function increase_current_ball_speed()
    local i, j = 1, 1
    while balls[i] do
        balls[i].dx *= ball_speed_increase
        balls[i].dy *= ball_speed_increase
        i += 1
    end
end

function update_objects()
end

function update_object_table(table)
    local i, j = 1, 1
    while table[i] do
        if table[i]:update() then
            if (i != j) table[j] = table[i] table[i] = nil
            j += 1
        else
            table[i] = nil
        end
        i += 1
    end
end

function rand_sign()
    return rnd() < 0.5 and 1 or -1
end

shake = 0
shake_amount = 1
max_shake = 3
function doshake()
    local shakex = shake_amount - rnd(shake_amount * 2)
    local shakey = shake_amount - rnd(shake_amount * 2)

    shakex *= shake
    shakey *= shake

    camera(shakex, shakey)

    shake = shake * 0.75
    if (shake < 0.05) shake = 0
end

show_levelup = false
started_levelup = false
levelup_input_stopped = false
choice_1 = nil
choice_2 = nil
lazer_choice = "lazer"
width_choice = "+1 width"
speed_choice = "+1 speed"
levelup_choices = { lazer_choice, width_choice, speed_choice }

function get_rand_choice(not_choice)
    printh("get rand choice")
    printh(not_choice)
    printh("---------------")
    local c = levelup_choices[flr(rnd(#levelup_choices)) + 1]
    printh(c)
    printh(not_choice)
    while c == not_choice do
        c = levelup_choices[flr(rnd(#levelup_choices)) + 1]
    end
    return c
end

function reset_levelup()
    show_levelup = false
    started_levelup = false
    choice_1 = nil
    choice_2 = nil
end

function reset_levelup_choices()
    ball_speed = default_ball_speed
    player_speed = default_player_speed
end

function apply_levelup(choice)
    if choice == lazer_choice then
        activate_lazer()
    elseif choice == width_choice then
        player.w += 2
    elseif choice == speed_choice then
        ball_speed += 0.25
        -- update current balls
        local i, j = 1, 1
        while balls[i] do
            balls[i].speed = ball_speed
            i += 1
        end
    else
        printh("idk what choice that was")
        printh(choice)
    end
end

function update_levelup()
    if not started_levelup then
        started_levelup = true
        levelup_input_stopped = false
        levelup_timer = levelup_timer_wait
        levelup_step = levelup_steps.start
        levelup_effects_started = false
        choice_1 = get_rand_choice(nil)
        choice_2 = get_rand_choice(choice_1)
        printh(choice_1)
        printh(choice_2)
    end

    if levelup_step == levelup_steps.start then
        return
    elseif levelup_step == levelup_steps.decision then
        if not levelup_input_stopped then
            if btn(0) or btn(1) then return end
            levelup_input_stopped = true
        end
        if btnp(0) then
            apply_levelup(choice_1)
            reset_levelup()
        end
        if btnp(1) then
            apply_levelup(choice_2)
            reset_levelup()
        end
    end
end

levelup_timer_wait = MAX_Y / 2
levelup_timer = levelup_timer_wait
levelup_h = 8
levelup_y = flr(MAX_Y / 2)
levelup_steps = { start = 1, decision = 2, finish = 3 }
levelup_step = levelup_steps.start

levelup_effects_started = false

function draw_levelup()
    if not show_levelup or not started_levelup then return end
    if levelup_step == levelup_steps.start then
        if not levelup_effects_started then
            levelup_effects_started = true
            for i = 0, MAX_X, 4 do
                explode(i, MAX_Y / 2, explode_size, { 6, 7 }, 14)
            end
        end

        local n = levelup_timer_wait - levelup_timer

        rectfill(MIN_X, MIN_Y + n, MAX_X, MAX_Y - n, 7)
        rectfill(MIN_X, levelup_y - levelup_h / 2, MAX_X, levelup_y + levelup_h / 2, 7)
        printh("n: " .. n .. "  t: " .. levelup_timer)

        levelup_timer -= 4
        if levelup_timer < 0 then
            levelup_step = levelup_steps.decision
            levelup_timer = 0
        end
    elseif levelup_step == levelup_steps.decision then
        -- draw left choice
        rectfill(MIN_X, levelup_y - levelup_h / 2 - 8, MAX_X, levelup_y + levelup_h / 2 - 8, 7)
        print("⬅️ " .. choice_1, 2, levelup_y - 10, 0)
        -- draw right choice
        rectfill(MIN_X, levelup_y - levelup_h / 2 + 8, MAX_X, levelup_y + levelup_h / 2 + 8, 7)
        print("➡️ " .. choice_2, 2, levelup_y + 6, 0)
    elseif levelup_step == levelup_steps.finish then
    else
        printh("weird levelup step???")
    end
end

activate_ma_lazah = false
function update_game()
    if ready_start_timer > 0 then
        ready_start_timer -= 1

        return
    end
    -- if show_levelup then
    --     update_fx()
    --     update_levelup()
    --     return
    -- end
    player:update()
    if btnp(4) then
        -- loosen_some_sand {}
        -- shake += 1
        -- add_layer {}
        -- test_ball_bounce()
        -- show_levelup = true
    end
    if btnp(5) then
        -- activate_lazer()
        -- increase_current_ball_speed()
        -- test_ball_bounce()
        new_pickup {}
    end
    update_bitmap()

    if t() * 10 % 10 == 0 then
        -- do more expensive calculations in here?
        if #balls == 0 and state == game_states.game and not start_ceiling_drop then
            new_big_ball()
            -- loosen_some_sand { amount = 1 }
        end

        if should_spawn_pickup() then
            new_pickup {}
        end
    end

    update_lazer()
    update_sticky()

    update_object_table(balls)
    update_object_table(pickups)
    update_fx()

    if not is_a_powerup_activated then
        spawned_pickup_timer -= 1
    end
end

danger_height = 32
spawned_pickup_timer = 900
spawned_pickup_timer_wait = 300
function should_spawn_pickup()
    if layer_height_avg >= danger_height and spawned_pickup_timer <= 0 then
        return true
    end
    return false
end

sticky_mode_activated = false
sticky_bm = {}
prev_player_width = 0
sticky_width_increase = 4

sticky_wait_time = 240
sticky_timer = sticky_wait_time

loosened_sand_dir = 0
loosen_sand_x = 32
function activate_sticky()
    if sticky_mode_activated then return end

    printh("sticky mode activate")
    sticky_mode_activated = true
    prev_player_width = player.w
    player.w = player.w + sticky_width_increase
    player.x = max(MIN_X, player.x - sticky_width_increase / 2)
    sticky_timer = sticky_wait_time
    loosened_sand_dir = rand_sign()
    loosen_sand_x = flr(4 + rnd(50))

    printh("sticky table: i=0," .. tostr(player.w - 1) .. " , j=" .. tostr(MIN_Y) .. "," .. player.y)
    for i = 0, player.w - 1 do
        sticky_bm[i] = {}
        for j = MIN_Y, player.y do
            sticky_bm[i][j] = 0
        end
    end
end

function add_sticky(tx, c)
    local x = max(0, min(tx, player.w - 1))
    for j = player.y, MIN_Y, -1 do
        printh(quote({ x, j }))
        if sticky_bm[x][j] == 0 then
            sticky_bm[x][j] = c
            return
        end
        --     if rnd(1) > layer_randomness then
        --     local prev_color = arg.color or bm_new_layer_color
        --     for j = MIN_Y, MAX_Y + 1 do
        --         local c = bm[i][j]
        --         bm[i][j] = prev_color
        --         prev_color = c
        --     end
        -- end
    end
end

function update_sticky()
    if not sticky_mode_activated then return end

    -- spawn sand to catch
    loosen_sand_x += loosened_sand_dir
    if loosen_sand_x < MIN_X or loosen_sand_x > MAX_X then
        loosened_sand_dir *= -1
        loosen_sand_x += loosened_sand_dir
    end
    loosen_some_sand { x = loosen_sand_x }

    sticky_timer -= 1
    if sticky_timer <= 0 or btnp(4) then
        shoot_sticky()
    end
end

sticky_player_y_offset = 1
function draw_sticky()
    if not sticky_mode_activated then return end
    if sticky_timer < 30 then
        player.y += sticky_player_y_offset
        sticky_player_y_offset *= -1
    end

    -- if start_shaking then r = rand_sign() end
    for i = 0, player.w - 1 do
        for j = MIN_Y, player.y do
            if sticky_bm[i][j] != 0 then
                pset(player.x + i, j, sticky_bm[i][j])
            end
        end
    end
end

sticky_speed = 1
function shoot_sticky()
    for i = 0, player.w - 1 do
        for j = MIN_Y, player.y do
            if sticky_bm[i][j] != 0 then
                new_ball { update = update_sticky_ball, x = player.x + i, y = j, w = 1, h = 1, dx = player.dx * sticky_speed, dy = -1 * sticky_speed, c = sticky_bm[i][j] }
                sticky_bm[i][j] = 0
            end
        end
    end
    player.w = prev_player_width
    sticky_mode_activated = false
end

function update_sticky_ball(b)
    -- b.c = get_relative_color(b)
    return update_ball(b)
end

function rand_dir()
    local r = rnd()
    if r < 0.34 then
        return -1
    elseif r < 0.67 then
        return 0
    else
        return 1
    end
end

__gfx__
0ee0000060000000077770000cccccc0000000000000000000000000000000000000000000000000000000000000000066000000600000066000000600000000
e77e00006600000077c77700cccccccc000000000000000000000000000000000000000000000000000000000000000060660000600000066000000600000000
e77e00006760000077cc7700cccccccc000000000000000000000000000000000000000000000000000000000000000060006600600000066000000600000000
0ee0000067760000c7777c00cccccccc000000000000000000000000000000000000000000000000000000000000000060000066600000066000000600000000
00000000677760000cccc000cccccccc000000000000000000000000000000000000000000000000000000000000000060000006600000066000000600000000
0000000067776000000000000cccccc0000000000000000000000000000000000000000000000000000000000000000060000006600000066000000600000000
00000000677760000000000000000000000000000000000000000000000000000000000000000000000000000000000060000006600000066000000600000000
00000000677760000000000000000000000000000000000000000000000000000000000000000000000000000000000060000006600000066666666600000000
0000000067776000077b700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000006777600077b7770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000067776000777b770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000067776000b7b77b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000677760000bbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000677760000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000677760000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000677760000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000677760000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000677760000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000677760000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000677760000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000677760000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000677760000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000677760000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
