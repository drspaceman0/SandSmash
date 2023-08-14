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
        init_splash()
    elseif new_state == game_states.game then
        state = game_states.game
        init_game()
        cls()
    elseif new_state == game_states.gameover then
        state = game_states.gameover
        init_gameover()
    end
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
    if btn(0) or stat(28, 4) then
        player.x = max(player.x - player.speed, MIN_X)
        player.dx = -player.speed
    elseif btn(1) or stat(28, 7) then
        -- right arrow or d key
        player.x = min(player.x + player.speed, MAX_X - player.w + 1)
        player.dx = player.speed
    else
        -- stop
        player.dx = 0
    end
    -- if stat(34) == 1 then
    --     mouse_x = stat(32)
    --     mouse_y = stat(33)
    --     -- left right side controls
    --     -- if mouse_x < MAX_X / 2 then
    --     --     player.x = max(player.x - o.speed, MIN_X)
    --     --     player.dx = -o.speed
    --     -- else
    --     --     player.x = min(player.x + o.speed, MAX_X - player.w + 1)
    --     --     player.dx = o.speed
    --     -- end

    --     -- move torwards mouse
    --     -- if player.center_x > min(mouse_x, MAX_X - player.h / 2) then
    --     --     player.x = max(player.x - o.speed, MIN_X)
    --     --     player.dx = -o.speed
    --     -- elseif player.center_x < max(mouse_x, player.h / 2) then
    --     --     player.x = min(player.x + o.speed, MAX_X - player.w + 1)
    --     --     player.dx = o.speed
    --     -- end

    --     player.x = min(MAX_X - player.w, max(MIN_X, mouse_x + 1 - player.w / 2))
    --     local x_diff = player.x - player.prev_x

    --     x_diff = max(-1, min(1, x_diff))
    --     player.dx = x_diff * player.speed
    --     player.prev_x = player.x
    -- end

    o.center_x = o.x + flr(o.w / 2)
    if t() % player_color_change_interval == 0 then
        player.c = bm_new_layer_color
    end
end

function draw_player(o)
    rectfill(o.x, o.y, o.x + o.w - 1, o.y + o.h, o.c)
    -- if stat(34) == 1 then
    --     spr(4, mouse_x, mouse_y)
    -- end
end

player_color_change_interval = 5
player_y = MAX_Y - 3
player_w_min = 12
player = {}
default_player_speed = 2
player_speed = default_player_speed

function init_player()
    player = Entity.create { x = MIN_X + 26, y = player_y, h = 1, w = player_w_min, c = 8, update = update_player, draw = draw_player, speed = player_speed }
    player.collision = false
    player.prev_x = x
end

-- Pico8 game funtions

function _init()
    poke(0x5f2c, 3)
    -- 64 bit mode
    poke(0x5F2D, 1)
    -- enable wasd

    cls()
    if debug_mode then
        quick_start()
        return
    end
    state = game_states.splash
    init_splash()
    -- state = game_states.game
    -- init_game()
end

debug_mode = false
function quick_start()
    state = game_states.game
    init_game()
    start_ceiling_drop = true
    ready_start_timer = 0
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
    -- cls()
    if clear_screen then cls() end
    if state == game_states.splash then
        draw_splash()
    elseif state == game_states.game then
        draw_game()
    elseif state == game_states.gameover then
        draw_gameover()
    end
    -- if true then
    --     local mid_x = flr(MAX_X / 2)
    --     local mid_y = flr(MAX_Y / 2)
    --     rect(MIN_X, MIN_Y, MAX_X, MAX_Y, 11)
    --     line(MIN_X, MIN_Y, MAX_X, MAX_Y, 11)
    --     line(MAX_X, MIN_Y, MIN_X, MAX_Y, 11)
    --     line(mid_x, MIN_Y, mid_x, MAX_Y, 11)
    --     line(mid_x + 1, MIN_Y, mid_x + 1, MAX_Y, 11)
    --     rect(MIN_X, mid_y, MAX_X, mid_y, 11)
    --     rect(MIN_X, mid_y + 1, MAX_X, mid_y + 1, 11)
    -- end
    -- line(MIN_X, layer_max_height_total, MAX_X, layer_max_height_total, 7)
end

time_at_init_game = 0
ready_start_timer = 30
function init_game()
    printh("NEW STATE: game")
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
function init_splash()
    printh("NEW STATE: splash")
    init_bitmap { include_blocks = false }
    splash_timer = 0
    balls = {}
    init_player()
    player.y = 300
    num_running_circles = 0
end

circle_distance = 6
function activate_transition()
    enable_transition = true
    transition_completed = false
    circles = {}
    for i = MIN_X, MAX_X + 5, circle_distance do
        for j = MIN_Y, MAX_Y + 5, 5 do
            local c = cool_colors[min(#cool_colors, max(1, flr(j / 7)))]
            new_circle(i, j, c, (i + j) / 10)
        end
    end
    num_running_circles = #circles
    sfx(5)
end

function update_transition()
    if not enable_transition then return end

    update_object_table(circles)
    if num_running_circles <= 0 then
        printh("#circles <= 0")
        enable_transition = false
        transition_completed = true
    end
end

function update_splash()
    if btnp(4) and not enable_transition then
        activate_transition()
    end

    update_transition()
    if transition_completed then
        printh("CHANGE TO GAME")
        change_state(game_states.game)
    end

    if splash_timer % 4 == 0 and not transition_completed then
        add_layer {}
    end

    -- if splash_timer > 30 and #balls == 0 then
    --     new_big_ball()
    --     balls[1].x = flr(rnd(MAX_X) + 8)
    --     balls[1].y = 40
    --     balls[1].dy = -1
    -- end

    -- update_object_table(balls)
    splash_timer += 1
end

function new_circle(x, y, c, t)
    add(circles, { x = x, y = y, r = 0, step = 0.4, c = c, update = update_circle, draw = draw_circle, start_timer = t, state = "expand" })
end

function draw_circle(c)
    if c.state == "shrink" or c.state == "done" then
        circfill(c.x - 4, c.y - 4, circle_distance, 0) -- draw black background
    end
    if c.r > 1 then
        circfill(c.x, c.y, c.r, c.c)
    end
end

function update_circle(c)
    c.start_timer -= 1
    if c.start_timer > 0 or c.state == "done" then return true end
    c.r += c.step

    if c.r >= circle_distance - 1 then
        c.step *= -1
        c.state = "shrink"
    end
    if c.state == "shrink" and c.r < 1 then
        c.c = 0
        -- c.r = 4
        c.state = "done"
        num_running_circles -= 1
    end
    return true
    -- return c.r >= 0
end

blink_text = false
function draw_splash()
    draw_bitmap()
    -- draw_table(balls)
    local text = "sand trap"

    write(text, text_x_pos(text) - 1, 28, 7)
    -- text = "trap"
    -- write(text, text_x_pos(text), 27, 7)

    if t() % 1 == 0 then blink_text = not blink_text end

    if blink_text then write("press z", 17, 54, 7) end
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
    draw_bitmap()
    player:draw()

    draw_table(balls)
    draw_table(pickups)

    draw_fx()
    if activate_ma_lazah then draw_lazer() end
    doshake()

    draw_sticky()

    if ready_start_timer > 0 then
        local text = "ready?"
        if ready_start_timer < 10 then
            text = "go!"
        end
        write(text, text_x_pos(text), 28, 7)
    end
end

-- GAME OVER

function update_gameover()
    if (btnp(4) or btnp(5)) and not enable_transition then
        activate_transition()
    end

    update_transition()
    if transition_completed then
        printh("CHANGE TO GAME")
        change_state(game_states.game)
    end

    update_bitmap()
    if activate_ma_lazah then update_lazer() end

    update_object_table(balls)
    update_object_table(pickups)

    update_fx()
end

highscore = -1
is_highscore = false
function init_gameover()
    printh("NEW STATE: gameover")
    player.y = 400
    score = bm_layer_count
    is_highscore = score > highscore and highscore != -1
    highscore = max(score, highscore)

    enable_transition = false
    transition_completed = false
    num_running_circles = 0
end

highscore_text_index_timer = 0
function draw_gameover()
    draw_game()
    -- write(text, text_x_pos(text), 28, 7)
    write("game over", text_x_pos("game over"), 20, 7)
    local score_text = "★ " .. score

    if is_highscore then
        local x_start = text_x_pos(score_text) - 6
        local y_start = 30
        local text_height = 2
        local text_speed = 30
        for i = 0, #score_text, 1 do
            local c = cool_colors[i % #cool_colors]
            write(
                sub(score_text, i, i),
                x_start + i * 4,
                y_start + sin((highscore_text_index_timer + i) / text_speed) * text_height, c
            )
        end
        highscore_text_index_timer += 1
    else
        write(score_text, text_x_pos(score_text) - 2, 30, 7)
    end

    if enable_transition then
        draw_transition()
        return
    end
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
    bm_new_layer_frequency = bm_new_layer_frequency_default
    bm_new_layer_timer = bm_new_layer_frequency
    bm_layer_count = 0
    bm = {}
    for i = MIN_X, MAX_X + 1 do
        bm[i] = {}
        for j = MIN_Y, MAX_Y + 1 do
            bm[i][j] = 0
        end
    end

    block_x = 10
    block_y = 10
    block_w = 7
    block_h = 4
    block_y_gap = block_h + 2
    local purple = { 12, 13, 2 }
    local red = { 15, 8, 2 }
    local green = { 6, 11, 3 }
    if arg.include_blocks then
        for i = 0, 4 do
            bitmap_brick { x = block_x + 9 * i, y = block_y, w = block_w, h = block_h, colors = purple }
        end

        for i = 0, 4 do
            bitmap_brick { x = block_x + 9 * i, y = block_y + block_y_gap, w = block_w, h = block_h, colors = green }
        end

        for i = 0, 4 do
            bitmap_brick { x = block_x + 9 * i, y = block_y + block_y_gap * 2, w = block_w, h = block_h, colors = red }
        end
    end
end

function bitmap_brick(arg)
    x, y, w, h, colors = arg.x, arg.y, arg.w, arg.h, arg.colors
    local c1, c2, c3 = colors[1], colors[2], colors[3]
    -- top left
    for i = 0, w do
        for j = 0, h do
            bm[x + i][y + j] = c1
        end
    end

    -- middle
    for i = 1, w - 1 do
        for j = 1, h - 1 do
            bm[x + i][y + j] = c2
        end
    end

    -- middle right
    for i = 0, w - 1 do
        bm[x + i][y + h] = c3
    end
    for j = 1, h do
        bm[x + w][y + j] = c3
    end
end

bm_layer_count = 0
bm_new_layer_color = 11
bm_new_layer_frequency_default = 18
-- bm_new_layer_frequency_default = 2
bm_new_layer_frequency = bm_new_layer_frequency_default

bm_new_layer_frequency_decrease = 0.5
bm_new_layer_frequency_min = 5
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
            if state == game_states.game then
                sfx(6)
                activate_game_over()
            end
        end
    end
end

function activate_game_over()
    printh("game over!!")
    if state == game_states.game then change_state(game_states.gameover) end
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
    -- printh(layer_height_avg)
    bm_layer_count += 1
end

function loosen_some_sand(arg)
    -- local n = arg.amount or flr(rnd(14))

    local x = arg.x or flr(rnd(MAX_X) + 1)
    local s = get_max_sand_at_x(x) or { x = x, y = 1, c = get_rand_cool_color() }
    local c = arg.c or s.c
    if c == 0 then
        c = get_rand_cool_color()
    end
    new_ball { x = x, y = s.y + 1, w = 1, h = 1, dx = 0, dy = 1, c = c }
    if rand_sign() == 1 then
        new_ball { x = x + rand_sign(), y = s.y + 1 + rand_sign(), w = 1, h = 1, dx = 0, dy = 1, c = c }
    end
end

function get_max_sand_at_x(x)
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
        play_sand_note(b)
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

    if b.y + 1 >= player.y then
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

            play_sand_note(b)
            calculate_player_reflect(b)
        end
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

function play_sand_note(b)
    -- sfx(0, -1, flr(b.x / 2), 1)
    sfx(0, -1, flr(b.x / 2), 1)
end

reflect_magnitude = 100
player_speed_dampining = 2
function calculate_player_reflect(b)
    -- x

    -- local b_offset = b.x - player.center_x
    -- b.dx = b_offset / reflect_magnitude + player.dx / player_speed_dampining
    -- b.dx = max(-1, min(1, b.dx))

    b.dx = player.dx / player_speed_dampining

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
        x = 47, y = 40, w = 4, h = 4, dx = -1, dy = 1, c = 7,
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
    -- sfx(1, 2)
    sfx(4)
    lazer_residue = {}
end

function update_lazer()
    if not activate_ma_lazah then return end
    local rnd_x = rnd(5) - 2
    lazer_x = flr(player.center_x - lazer_w / 2 + rnd_x)

    for i = max(MIN_X, lazer_x - 1), min(MAX_X, lazer_x + lazer_w + 1) do
        for j = MIN_Y, MAX_Y do
            if bm[i][j] != 0 then
                if rnd(1) > 0.95 then add(lazer_residue, { x = i, y = flr(rnd(MAX_Y)), c = lazer_color }) end

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

        sfx(-1, 2)
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
clear_screen = false
function doshake()
    if shake <= 0 then return end
    clear_screen = true
    local shakex = shake_amount - rnd(shake_amount * 2)
    local shakey = shake_amount - rnd(shake_amount * 2)

    shakex *= shake
    shakey *= shake

    camera(shakex, shakey)

    shake = shake * 0.75
    if shake < 0.05 then
        shake = 0
        camera(0, 0)
        clear_screen = false
    end
end

activate_ma_lazah = false
function update_game()
    if ready_start_timer > 0 then
        ready_start_timer -= 1
        return
    end

    player:update()
    if btnp(4) then
        -- activate_game_over()
        -- for i = MIN_X, MAX_X do
        --     loosen_some_sand { x = i }
        --     loosen_some_sand { x = i }
        --     loosen_some_sand { x = i }
        -- end

        -- shake += 1
        -- add_layer {}
        -- test_ball_bounce()
    end
    if btnp(5) then
        -- activate_lazer()
        -- increase_current_ball_speed()
        -- test_ball_bounce()
        -- new_pickup {}
    end
    update_bitmap()

    if #balls == 0 and state == game_states.game and not start_ceiling_drop then
        new_big_ball()
        -- loosen_some_sand { amount = 1 }
    end

    if should_spawn_pickup() then
        new_pickup {}
    end

    update_lazer()
    update_sticky()

    update_object_table(balls)
    update_object_table(pickups)
    update_fx()

    if not is_a_powerup_activated() then
        spawned_pickup_timer -= 1
    end
end

danger_height = 26
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

sticky_wait_time = 180
sticky_timer = sticky_wait_time

loosened_sand_dir = 0
loosen_sand_x = 32
loosen_sand_timer = 20
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
    loosen_sand_timer = 20
    num_sticky_sand = 0

    printh("sticky table: i=0," .. tostr(player.w - 1) .. " , j=" .. tostr(MIN_Y) .. "," .. player.y)
    for i = 0, player.w - 1 do
        sticky_bm[i] = {}
        for j = MIN_Y, player.y do
            sticky_bm[i][j] = 0
        end
    end
end

num_sticky_sand = 0
function add_sticky(tx, c)
    local x = max(0, min(tx, player.w - 1))
    for j = player.y, MIN_Y, -1 do
        if sticky_bm[x][j] == 0 then
            sticky_bm[x][j] = c
            num_sticky_sand += 1
            sfx(3, -1, min(flr(num_sticky_sand / 8), 30), 1)
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
    if loosen_sand_x < MIN_X or loosen_sand_x > MAX_X or loosen_sand_timer <= 0 then
        loosened_sand_dir *= -1
        loosen_sand_x += loosened_sand_dir
        loosen_sand_timer = flr(10 + rnd(60))
    end
    loosen_some_sand { x = loosen_sand_x }

    loosen_sand_timer -= 1
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
    sfx(4)
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
0ee0000060000000077770000cccccc0070000000000000000000000000000000000000000000000000000000000000066000000600000066000000600000000
e77e00006600000077c77700cccccccc707000000000000000000000000000000000000000000000000000000000000060660000600000066000000600000000
e77e00006760000077cc7700cccccccc070000000000000000000000000000000000000000000000000000000000000060006600600000066000000600000000
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
__label__
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccbbcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccbbcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccbbccccccccccccccccbbccccccbbccccccbbccccccbbccccccccccbbccccbbccccccccccccccccccccccccccccccccccccccccccccbbcccc
ccccccccccccccccbbccccccccccccccccbbccccccbbccccccbbccccccbbccccccccccbbccccbbccccccccccccccccccccccccccccccccccccccccccccbbcccc
ccbbccbbccbbccccbbccccccccccbbbbbbbbbbccccbbbbccccbbbbccbbbbccbbbbccbbbbccccbbccccccccbbbbbbbbbbccccccccccbbccbbbbbbbbbbbbbbcccc
ccbbccbbccbbccccbbccccccccccbbbbbbbbbbccccbbbbccccbbbbccbbbbccbbbbccbbbbccccbbccccccccbbbbbbbbbbccccccccccbbccbbbbbbbbbbbbbbcccc
bbbbbbbbbbbbbbbbaabbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbaabbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbaa
bbbbbbbbbbbbbbbbaabbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbaabbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbaa
bbbbbbbbbbaabbbbaabbbbbbbbbbbbbbbbbbaabbbbbbbbbbbbaabbbbbbaabbbbbbbbbbaabbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbaabbbbbbaa
bbbbbbbbbbaabbbbaabbbbbbbbbbbbbbbbbbaabbbbbbbbbbbbaabbbbbbaabbbbbbbbbbaabbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbaabbbbbbaa
aaaabbaabbaabbbbaabbbbbbbbbbbbaaaaaaaabbbbaabbbbaaaaaaaaaaaabbbbaabbbbaabbbbaabbbbbbbbbbbbbbaabbbbaabbbbbbbbaaaabbbbbbaabbaabbaa
aaaabbaabbaabbbbaabbbbbbbbbbbbaaaaaaaabbbbaabbbbaaaaaaaaaaaabbbbaabbbbaabbbbaabbbbbbbbbbbbbbaabbbbaabbbbbbbbaaaabbbbbbaabbaabbaa
aaaabbaabbaaaaaaaabbbbbbaabbaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa99bbaaaabbaaaaaabbaabbaabbaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaabbaa
aaaabbaabbaaaaaaaabbbbbbaabbaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa99bbaaaabbaaaaaabbaabbaabbaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaabbaa
aaaaaaaaaa99aaaa99aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa9999aaaaaa99aaaa99aaaa99aaaaaaaaaaaaaaaaaa99aaaa99aaaaaaaaaaaaaaaaaaaaaaaaaaaa99
aaaaaaaaaa99aaaa99aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa9999aaaaaa99aaaa99aaaa99aaaaaaaaaaaaaaaaaa99aaaa99aaaaaaaaaaaaaaaaaaaaaaaaaaaa99
9999aaaaaa99aaaa99aaaaaaaaaaaaaa999999aaaa99aaaa9999aa99aa88aaaa99aaaa99aaaaaaaaaaaaaaaaaa99aaaa999999aa99aa99aaaaaaaa99aa99aa99
9999aaaaaa99aaaa99aaaaaaaaaaaaaa999999aaaa99aaaa9999aa99aa88aaaa99aaaa99aaaaaaaaaaaaaaaaaa99aaaa999999aa99aa99aaaaaaaa99aa99aa99
9999aa99aa99aaaa99aaaaaaaaaaaa99999999aaaa99aaaa999999999988aaaa99aa9999aa9999aaaaaaaaaaaa9999999999999999999999aa9999999999aa99
9999aa99aa99aaaa99aaaaaaaaaaaa99999999aaaa99aaaa999999999988aaaa99aa9999aa9999aaaaaaaaaaaa9999999999999999999999aa9999999999aa99
9988aa99998899999999aa99999999998899999999999999888899999988aa9999aa9999999999aa99aa99999988999999889999889999999999999999999988
9988aa99998899999999aa99999999998899999999999999888899999988aa9999aa9999999999aa99aa99999988999999889999889999999999999999999988
8888999999889999889999999999999988889999998899998888999999ee99998899888899999999999999999988999988889999889999999999998899889988
99999988999988999988998899999999999999999999998899889999999988999988999999998888999988999999999988999999998899998899999999999999
99999988999988999988998899999999999999999999998899889999999988999988999999998888999988999999999988999999998899998899999999999999
888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888ee888888888888888888888888888888
888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888ee888888888888888888888888888888
88ee8888888888888888888888888888888888ee88ee888888888888888888888888ee88888888888888888888888888ee88888888888888ee88888888888888
88ee8888888888888888888888888888888888ee88ee888888888888888888888888ee88888888888888888888888888ee88888888888888ee88888888888888
88eeeeee88ee88888888ee888888888888ee88ee88ee88eeeeee88888888ee8888eeee888888ee8888888888eeeeee88ee88ee8888ee88eeeeee88888888ee88
88eeeeee88ee88888888ee888888888888ee88ee88ee88eeeeee88888888ee8888eeee888888ee8888888888eeeeee88ee88ee8888ee88eeeeee88888888ee88
eeddeeee88eeeeee88eeeeeeeeee8888eeee88ddeeeeeeddeeeeeeee88eeeeee88eeee888888eeeeee88eeeeeeeeee88ddeeeeeeeeee88eeeeeeeeee88eeee88
eeddeeee88eeeeee88eeeeeeeeee8888eeee88ddeeeeeeddeeeeeeee88eeeeee88eeee888888eeeeee88eeeeeeeeee88ddeeeeeeeeee88eeeeeeeeee88eeee88
eeddeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeddeeddeeddeeddeeeeeeeeeeeeeeeeeeeeeeeeddeeeeeeeeeeeeddeeeeddeeddeeeeeeeeeeeeeeeeeeeeeeeeee
eeddeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeddeeddeeddeeddeeeeeeeeeeeeeeeeeeeeeeeeddeeeeeeeeeeeeddeeeeddeeddeeeeeeeeeeeeeeeeeeeeeeeeee
eeddeeddeeeeeeddeeeeddeeeeddeeeeeeeeeeddeeddeeddeeddddeeeeeeddeeeeeeddeeeeeeddeeddeeddeeddddeeeeddeeddddeeeeeeddddddeeeeeeeeddee
eeddeeddeeeeeeddeeeeddeeeeddeeeeeeeeeeddeeddeeddeeddddeeeeeeddeeeeeeddeeeeeeddeeddeeddeeddddeeeeddeeddddeeeeeeddddddeeeeeeeeddee
eeddddddeeddeeddeeddddeeddddeeeeddddeeddeeddddddddddddeeeeddddddeeddddeeeeeeddeeddeeddeeddddddeeddeeddddeeddeeddddddddeeeeddddee
eeddddddeeddeeddeeddddeeddddeeeeddddeeddeeddddddddddddeeeeddddddeeddddeeeeeeddeeddeeddeeddddddeeddeeddddeeddeeddddddddeeeeddddee
ddccddddeeddddddddddddddddddeeeeddddddccddccddccddddddddddddddddeeddddddeeeeccddccddddddddddddeeccddddddddddeeddddddddddddddddee
ddccddddeeddddddddddddddddddeeeeddddddccddccddccddddddddddddddddeeddddddeeeeccddccddddddddddddeeccddddddddddeeddddddddddddddddee
ccccddccddddddccddddddddddddddddddddddccddccddccddccccddddddddddddddddddddddccddccddccddddccddddccddccddddddddccddddddddddccccdd
ccccddccddddddccddddddddddddddddddddddccddccddccddccccddddddddddddddddddddddccddccddccddddccddddccddccddddddddccddddddddddccccdd
ccccccccddccddccccccccddddccccddccddddccddccddccccccccddddccccddddccccddddddccddccddccddccccccddccddccccddccccccccccddddccccccdd
ccccccccddccddccccccccddddccccddccddddccddccddccccccccddddccccddddccccddddddccddccddccddccccccddccddccccddccccccccccddddccccccdd
ccbbccccddccddccccccccccccccccddccccddbbccbbccbbccccccccddccccccddccccddccddccddbbddccddccccccddccccccccccccccccccccccddccbbcccc
ccbbccccddccddccccccccccccccccddccccddbbccbbccbbccccccccddccccccddccccddccddccddbbddccddccccccddccccccccccccccccccccccddccbbcccc
bbbbccccddbbccccccccccccccccccccccccccbbccbbccbbccbbbbccccccccccddccccccccddbbccbbccccccccccccccbbbbccccccccccbbccccccccccbbbbcc
bbbbccccddbbccccccccccccccccccccccccccbbccbbccbbccbbbbccccccccccddccccccccddbbccbbccccccccccccccbbbbccccccccccbbccccccccccbbbbcc
bbbbccbbccbbccbbccccbbccccccbbccbbbbccbbccbbbbbbbbbbbbccccbbccccccbbbbccccccbbbbbbccbbccbbbbbbccbbbbbbbbccccbbbbccbbbbccccbbbbcc
bbbbccbbccbbccbbccccbbccccccbbccbbbbccbbccbbbbbbbbbbbbccccbbccccccbbbbccccccbbbbbbccbbccbbbbbbccbbbbbbbbccccbbbbccbbbbccccbbbbcc
bbaabbbbccbbccbbbbbbbbbbccbbbbccbbbbccaaccaabbbbbbbbbbbbccbbbbbbccbbbbccccccbbbbaaccbbccbbbbbbccbbbbbbbbccbbbbaabbbbbbbbbbaabbcc
bbaabbbbccbbccbbbbbbbbbbccbbbbccbbbbccaaccaabbbbbbbbbbbbccbbbbbbccbbbbccccccbbbbaaccbbccbbbbbbccbbbbbbbbccbbbbaabbbbbbbbbbaabbcc
aaaabbbbccbbccbbbbbbaabbbbbbbbccaabbbbaabbaabbaabbbbaabbccbbbbbbbbbbbbbbbbccbbbbaaccbbbbbbbbbbccaabbbbbbbbbbbbaabbbbaabbbbaabbbb
aaaabbbbccbbccbbbbbbaabbbbbbbbccaabbbbaabbaabbaabbbbaabbccbbbbbbbbbbbbbbbbccbbbbaaccbbbbbbbbbbccaabbbbbbbbbbbbaabbbbaabbbbaabbbb
aaaabbbbbbaabbaabbbbaabbbbbbaabbaabbbbaabbaaaaaaaaaaaabbbbaaaabbbbaaaabbbbccaabbaabbaabbaaaabbbbaaaabbaabbbbbbaabbaaaabbaaaaaabb
aaaabbbbbbaabbaabbbbaabbbbbbaabbaabbbbaabbaaaaaaaaaaaabbbbaaaabbbbaaaabbbbccaabbaabbaabbaaaabbbbaaaabbaabbbbbbaabbaaaabbaaaaaabb
aaaabbaabbaabbaaaaaaaabbbbbbaabbaaaabbaabbaaaaaaaaaaaaaabbaaaaaabbaaaabbbbbbaaaa99bbaabbaaaaaabbaaaaaaaabbbbaa99bbaa99bbaa99aaaa
aaaabbaabbaabbaaaaaaaabbbbbbaabbaaaabbaabbaaaaaaaaaaaaaabbaaaaaabbaaaabbbbbbaaaa99bbaabbaaaaaabbaaaaaaaabbbbaa99bbaa99bbaa99aaaa
9999aaaabbaabbaaaaaa99aaaaaaaabbaaaaaa99aa99aa99aaaa99aabbaaaaaaaa99aaaaaabbaaaa99bbaaaaaaaaaabb99aaaa99aaaaaa99aa9999aaaa99aaaa
9999aaaabbaabbaaaaaa99aaaaaaaabbaaaaaa99aa99aa99aaaa99aabbaaaaaaaa99aaaaaabbaaaa99bbaaaaaaaaaabb99aaaa99aaaaaa99aa9999aaaa99aaaa
9999aaaabbaaaaaa99aa99aaaaaaaabb99aaaa99aa99aa9999aa99aaaa9999aaaa9999aaaabbaaaa99bbaaaaaaaa99bb9999aa99aaaaaa99aa9999aaaa9999aa
9999aaaabbaaaaaa99aa99aaaaaaaabb99aaaa99aa99aa9999aa99aaaa9999aaaa9999aaaabbaaaa99bbaaaaaaaa99bb9999aa99aaaaaa99aa9999aaaa9999aa
9999aa99aa99aa99999988aaaa9999aa99aaaa99aa999999999999aaaa999999aa9999aaaabb99aa99aa9999999999aa9999aa9999aaaa88aa9988aa99999999
9999aa99aa99aa99999988aaaa9999aa99aaaa99aa999999999999aaaa999999aa9999aaaabb99aa99aa9999999999aa9999aa9999aaaa88aa9988aa99999999
8888aa99aa99aa99999988aaaa9999aa88999988999999999999999999889999998899aaaaaa999988aa9999999999aa8899999999aa9988aa8888aa99888899
8888aa99aa99aa99999988aaaa9999aa88999988999999999999999999889999998899aaaaaa999988aa9999999999aa8899999999aa9988aa8888aa99888899
88889999aa99aa9988998899999999aa889999889988998899998888998888999988889999aa889988aa9999999988aa88889988999999889988889999888899
88889999aa99aa9988998899999999aa889999889988998899998888998888999988889999aa889988aa9999999988aa88889988999999889988889999888899
888899999988999988888899998899aaee9999889988888888998888998888889988889999aa888888999999889988aa88889988889999889988ee9988888899
888899999988999988888899998899aaee9999889988888888998888998888889988889999aa888888999999889988aa88889988889999889988ee9988888899
ee889988998899888888ee9988888899ee999988888888888888888899ee888899eeee9999aa88888899888888888899ee889988889999ee99eeee9988eeee88
ee889988998899888888ee9988888899ee999988888888888888888899ee888899eeee9999aa88888899888888888899ee889988889999ee99eeee9988eeee88
eeee888899889988ee88ee9988888899ee8888ee88eeeeee8888ee8888ee888888eeee9999998888ee998888ee88ee99ee8888ee888888ee88eedd8888eeee88
eeee888899889988ee88ee9988888899ee8888ee88eeeeee8888ee8888ee888888eeee9999998888ee998888ee88ee99ee8888ee888888ee88eedd8888eeee88
eeee888888889988eeeedd8888888888ee8888ee88eeeeeeee88eeee88ddeeee88eeee888899eeeeee998888ee88ee99eeee88eeee8888ee88dddd88eeeeee88
eeee888888889988eeeedd8888888888ee8888ee88eeeeeeee88eeee88ddeeee88eeee888899eeeeee998888ee88ee99eeee88eeee8888ee88dddd88eeeeee88
ddee88ee88ee88eeeeeeddee88eeee88dd8888eeeeeeeeeeeeeeeeeeeeddddee88ddee888888eeeedd888888eeeeee99ddeeeeddee8888ee88dddd88eeddee88
ddee88ee88ee88eeeeeeddee88eeee88dd8888eeeeeeeeeeeeeeeeeeeeddddee88ddee888888eeeedd888888eeeeee99ddeeeeddee8888ee88dddd88eeddee88
ddeeeeee88ee88eeeeeecceeeeee000000000000000000000000000000ddddeeee0000000000000000000000000000000000eeddee8888ddeedddd88ddddddee
ddeeeeee88ee88eeeeeecceeeeee000000000000000000000000000000ddddeeee0000000000000000000000000000000000eeddee8888ddeedddd88ddddddee
ddddeeee88ee88eeddddccddee0000777700777777007777000077770000ddeeee0077777700777777007777770077777700eeddeeeeeeddeecccceeccddddee
ddddeeee88ee88eeddddccddee0000777700777777007777000077770000ddeeee0077777700777777007777770077777700eeddeeeeeeddeecccceeccddddee
ddddeeddeeddeeeeddddccddee0077000000770077007700770077007700ccddee0000770000770077007700770077007700eeddddeeeecceecccceeaaddddee
ddddeeddeeddeeeeddddccddee0077000000770077007700770077007700ccddee0000770000770077007700770077007700eeddddeeeecceecccceeaaddddee
ccddddddeeddeeddddddccdddd0077777700777777007700770077007700ccddeecc00770000777700007777770077777700ddccddeeeeccddcccceeaaccccdd
ccddddddeeddeeddddddccdddd0077777700777777007700770077007700ccddeecc00770000777700007777770077777700ddccddeeeeccddcccceeaaccccdd
ccddddddeeddddddddccbbccdd0000007700770077007700770077007700ccddddcc00770000770077007700770077000000ddccddeeddbbddbbbbddaaccccdd
ccddddddeeddddddddccbbccdd0000007700770077007700770077007700ccddddcc00770000770077007700770077000000ddccddeeddbbddbbbbddaaccccdd
ccccddddddddddddccccbbccdd0077770000770077007700770077777700ccccddcc0077000077007700770077007700bbddddbbccddddbbddbbbbdd99ccccdd
ccccddddddddddddccccbbccdd0077770000770077007700770077777700ccccddcc0077000077007700770077007700bbddddbbccddddbbddbbbbdd99ccccdd
ccccddccddccddddccccbbccdd0000000000000000000000000000000000bbccddbb0000000000000000000000000000bbccccbbccddddaaccbbbbdd99bbccdd
ccccddccddccddddccccbbccdd0000000000000000000000000000000000bbccddbb0000000000000000000000000000bbccccbbccddddaaccbbbbdd99bbccdd
bbccccbbddccddccccbbbbbbccccbbddbbbbccbbccccbbbbccccccbbbbaabbccccbbbbddccddccccbbccccbbbbbbbbddbbccccbbccddccaaccbbaacc99bbbbcc
bbccccbbddccddccccbbbbbbccccbbddbbbbccbbccccbbbbccccccbbbbaabbccccbbbbddccddccccbbccccbbbbbbbbddbbccccbbccddccaaccbbaacc99bbbbcc
bbccccbbddccccccbbbbaabbccccaaddbbbbccbbccbbaabbbbbbbbbbbbaabbccccbbbbddbbddccbbaaccccbbbbbbaaddaaccccbbbbddccaaccaaaacc99bbbbcc
bbccccbbddccccccbbbbaabbccccaaddbbbbccbbccbbaabbbbbbbbbbbbaabbccccbbbbddbbddccbbaaccccbbbbbbaaddaaccccbbbbddccaaccaaaacc99bbbbcc
bbbbccbbccccccccbbbbaabbccccaaccaabbccaaccbbaabbbbbbbbbbaa99aabbccbbbbccbbddccbbaabbbbbbbbbbaaddaaccccaabbccccaaccaaaacc88bbbbcc
bbbbccbbccccccccbbbbaabbccccaaccaabbccaaccbbaabbbbbbbbbbaa99aabbccbbbbccbbddccbbaabbbbbbbbbbaaddaaccccaabbccccaaccaaaacc88bbbbcc
aabbbbbbccbbccccbbaaaabbbbbbaaccaaaaccaabbbbaabbbbbbbbaaaa99aabbbbaaaaccbbccbbbbaabbbbbbbbbbaaccaabbbbaabbcccc99bbaa99bb88aaaabb
aabbbbbbccbbccccbbaaaabbbbbbaaccaaaaccaabbbbaabbbbbbbbaaaa99aabbbbaaaaccbbccbbbbaabbbbbbbbbbaaccaabbbbaabbcccc99bbaa99bb88aaaabb
aabbbbaaccbbccbbaaaaaaaabbbb99ccaaaabb99bbaa99aabbbbbbaaaa99aabbbbaaaaccbbccbbaa99bbbbaaaaaa99ccaabbbb99aaccbb99bb9999bb88aaaabb
aabbbbaaccbbccbbaaaaaaaabbbb99ccaaaabb99bbaa99aabbbbbbaaaa99aabbbbaaaaccbbccbbaa99bbbbaaaaaa99ccaabbbb99aaccbb99bb9999bb88aaaabb
aabbbbaabbbbbbbbaaaa99aaaabb99cc99aabb99bbaa99aaaaaaaa99aa88aabbbbaaaabbaaccbbaa99aaaaaaaaaa88cc99bbbb99aaccbb99aa9999bb88aaaabb
aabbbbaabbbbbbbbaaaa99aaaabb99cc99aabb99bbaa99aaaaaaaa99aa88aabbbbaaaabbaaccbbaa99aaaaaaaaaa88cc99bbbb99aaccbb99aa9999bb88aaaabb
99aabbaabbbbbbbbaa9999aaaabb99bb99aabb99bbaa88aaaaaaaa99998899aaaaaa99bbaabbaaaa99aaaa99aaaa88cc99aabb99aabbaa88aa9999bb0099aabb
99aabbaabbbbbbbbaa9999aaaabb99bb99aabb99bbaa88aaaaaaaa99998899aaaaaa99bbaabbaaaa99aaaa99aaaa88cc99aabb99aabbaa88aa9999bb0099aabb
99aaaaaabbaabbbbaa9999aaaaaa88bb8899bb99aaaa88aaaaaaaa99998899aaaa9999bbaabbaaaa88aaaa9999aa00bb99aaaa99aabbaa88aa9988aa009999aa
99aaaaaabbaabbbbaa9999aaaaaa88bb8899bb99aaaa88aaaaaaaa99998899aaaa9999bbaabbaaaa88aaaa9999aa00bb99aaaa99aabbaa88aa9988aa009999aa
88aaaa99bbaaaaaa99999999aaaa88bb8899aa88aa99889999aaaa99998888aaaa9999bb99bb999988aaaa99999900bb99aaaa8899bbaa88aa8888aa008899aa
88aaaa99bbaaaaaa99999999aaaa88bb8899aa88aa99889999aaaa99998888aaaa9999bb99bb999988aaaa99999900bb99aaaa8899bbaa88aa8888aa008899aa
88aaaa99aaaaaaaa9988889999aa88bb8899aa88aa99889999999988990088aaaa9999aa99bb998888999999999900bb88aaaa8899aaaa88998888aa008899aa
88aaaa99aaaaaaaa9988889999aa88bb8899aa88aa99889999999988990088aaaa9999aa99bb998888999999999900bb88aaaa8899aaaa88998888aa008899aa
8899aa88aaaaaaaa99888899999988aa88999988999900999999998888008899998888aa99aa990000999988888800bb8899998899aa990099880099008888aa
8899aa88aaaaaaaa99888899999988aa88999988999900999999998888008899998888aa99aa990000999988888800bb8899998899aa990099880099008888aa
88999988aa99aaaa88888888999900aa00889900998800999999998888000099998888aa99aa990000999988888800aa8899998899aa99009900009900888899
88999988aa99aaaa88888888999900aa00889900998800999999998888000099998888aa99aa990000999988888800aa8899998899aa99009900009900888899
00889988aa99999988880088889900aa00888800998800888899998800000088888888aa88aa880000889988888800aa8899990088aa99009900009900008899
00889988aa99999988880088889900aa00888800998800888899998800000088888888aa88aa880000889988888800aa8899990088aa99009900009900008899
008899889999999900000088888800aa008800009988008888888800000000888888009988998800008888000000009900889900889999008800009900008888
008899889999999900000088888800aa008800009988008888888800000000888888009988998800008888000000009900889900889999008800009900008888
00889900999999990000000088880099000000008800008888888800000000888800009988998800008888000000009900888800889988008800008800000088
00889900999999990000000088880099000000008800008888888800000000888800009988998800008888000000009900888800889988008800008800000088
00008800888899880000000000000099000000008800000088888800000000000000009900990000008888000000009900888800889988008800008800000000
00008800888899880000000000000099000000008800000088888800000000000000009900990000008888000000009900888800889988008800008800000000
00008800888888880000000000000088000000008800000000880000000000000000009900880000000088000000008800008800008800000000008800000000
00008800888888880000000000000088000000008800000000880000000000000000009900880000000088000000008800008800008800000000008800000000
00008800880088880000000000000088000000008800000000000000000000000000008800880000000000000000008800000000008800000000000000000000
00008800880088880000000000000088000000008800000000000000000000000000008800880000000000000000008800000000008800000000000000000000
00000000880088880000000000000088000000000000000000000000000000000000008800880000000000000000008800000000008800000000000000000000
00000000880088880000000000000088000000000000000000000000000000000000008800880000000000000000008800000000008800000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000008800880000000000000000008800000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000008800880000000000000000008800000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000008800000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000008800000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__sfx__
000300000e0300f030100301103011030120301303014030150301503016030170301803018030190301a0301a0301a0301b0301b0301c0301d0301d0301e0301f03020030210302203023030250302603026030
000400002822024220222201f2201d2201b2201a2201822016220142201322012220102200f2200e2200d2200c2200b2200b2200a2200a2200922008220082200722007220072200622005220052200522004220
000300000132003320033200332004320043200432005320053200632007320073200832008320093200a3200b3200b3200c3200c3200d3200d3200e3200f3200f3200f320103201032011320123201332013310
000300000032001320023200232003320043200432005320053200632006320073200832009320093200a3200b3200c3200d3200e3200f320103201132013320143201432015320163201732018320193201a320
000300002332022320203201d3201d3201c3201b320193201732014320113200e3200a320063200332000320003202130024300363000c30008300023001230020300133000f3001d30019300163001930002300
000300001c0501c0501c0501200012000130501305013050170000e0000905009050090500f0001000012050120501205016000180001c0501c0501c05021000230001c0001c0001c0002b0001a0001a0001a000
00030000280502705026050240502205021050200501f0501e0501c0501a050080500805008050090500905008050080500805008050080500805008050080500705007050070500705007050070500805008050
00030000280502705026050240502205021050200501f0501e0501c0501a050080500805008050090500905008050080500805008050080500805008050080500705007050070500705007050070500805008050
