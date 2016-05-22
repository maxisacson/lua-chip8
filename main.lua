cpu = require('cpu'):new()
bit = require('bit')

function love.load()
    cpu:read_rom("roms/15PUZZLE")
end

function love.update(dt)
    local opcode = cpu:read_instruction()
    print("0x" .. bit.tohex(cpu.program_counter-2, 3) .. " opcode: 0x" .. bit.tohex(opcode, 4))
    cpu:run_instruction(opcode)
    cpu:print_state()
    --cpu:dump_screen()


    -- The cpu and delay timers should decrease by 1 at a rate of 6Hz
    -- TODO: ensure proper clock rate.
    if cpu.delay_timer > 0 then
        cpu.delay_timer = cpu.delay_timer - 1
    end

    if cpu.sound_timer > 0 then
      cpu.sound_timer = cpu.sound_timer - 1
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
