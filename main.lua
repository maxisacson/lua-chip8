cpu = require('cpu'):new()
bit = require('bit')

function love.load()
    cpu:read_rom("roms/INVADERS")
end

local dt2 = 0

function love.update(dt)
    local opcode = cpu:read_instruction()
    --print("0x" .. bit.tohex(cpu.program_counter-2, 3) .. " opcode: 0x" .. bit.tohex(opcode, 4))
    cpu:run_instruction(opcode)
    --cpu:print_state()
    --cpu:dump_screen()
    --cpu:print_keys()

    --print("fps", 1/dt)
    -- The cpu and delay timers should decrease by 1 at a rate of 60Hz
    dt2 = dt2 + dt
    if dt2 > 1/60 then
        dt2 = 0
        if cpu.delay_timer > 0 then
            cpu.delay_timer = cpu.delay_timer - 1
        end
    
        if cpu.sound_timer > 0 then
          cpu.sound_timer = cpu.sound_timer - 1
        end
    end

end

function love.draw()
    local scale_x = 16
    local scale_y = 16

    for i=1,#cpu.screen_buffer do
        local x = (i-1) % 64
        local y = math.floor((i-1)/64)
        local pixel = cpu.screen_buffer[i]

        if pixel == 1 then
            love.graphics.setColor(255,255,255)
        else
            love.graphics.setColor(0,0,0)
        end
        love.graphics.rectangle('fill', x*scale_x, y*scale_y, scale_x, scale_y)
    end
end

function love.keypressed(key, scancode, isrepeat)
    --print("--- Keypressed: ", key, scancode)
    if key == '0' then
        cpu:key_pressed(0x0)
    elseif key == '1' then
        cpu:key_pressed(0x1)
    elseif key == '2' then
        cpu:key_pressed(0x2)
    elseif key == '3' then
        cpu:key_pressed(0x3)
    elseif key == '4' then
        cpu:key_pressed(0x4)
    elseif key == '5' then
        cpu:key_pressed(0x5)
    elseif key == '6' then
        cpu:key_pressed(0x6)
    elseif key == '7' then
        cpu:key_pressed(0x7)
    elseif key == '8' then
        cpu:key_pressed(0x8)
    elseif key == '9' then
        cpu:key_pressed(0x9)
    elseif key == 'a' then
        cpu:key_pressed(0xa)
    elseif key == 'b' then
        cpu:key_pressed(0xb)
    elseif key == 'c' then
        cpu:key_pressed(0xc)
    elseif key == 'd' then
        cpu:key_pressed(0xd)
    elseif key == 'e' then
        cpu:key_pressed(0xe)
    elseif key == 'f' then
        cpu:key_pressed(0xf)
    end
end

function love.keyreleased(key, scancode, isrepeat)
    --print("--- Keyreleased: ", key, scancode)
    if key == '0' then
        cpu:key_released(0x0)
    elseif key == '1' then
        cpu:key_released(0x1)
    elseif key == '2' then
        cpu:key_released(0x2)
    elseif key == '3' then
        cpu:key_released(0x3)
    elseif key == '4' then
        cpu:key_released(0x4)
    elseif key == '5' then
        cpu:key_released(0x5)
    elseif key == '6' then
        cpu:key_released(0x6)
    elseif key == '7' then
        cpu:key_released(0x7)
    elseif key == '8' then
        cpu:key_released(0x8)
    elseif key == '9' then
        cpu:key_released(0x9)
    elseif key == 'a' then
        cpu:key_released(0xa)
    elseif key == 'b' then
        cpu:key_released(0xb)
    elseif key == 'c' then
        cpu:key_released(0xc)
    elseif key == 'd' then
        cpu:key_released(0xd)
    elseif key == 'e' then
        cpu:key_released(0xe)
    elseif key == 'f' then
        cpu:key_released(0xf)
    end  
end
