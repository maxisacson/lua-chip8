cpu = require('cpu'):new()
bit = require('bit')

cpu:read_rom("roms/INVADERS")

--cpu:dump_memory()

--cpu:run()

function love.draw()
    local opcode = cpu:read_instruction()
    print("0x" .. bit.tohex(cpu.program_counter-2, 3) .. " opcode: 0x" .. bit.tohex(opcode, 4))
    cpu:run_instruction(opcode)
    cpu:print_state()
    --cpu:dump_screen()

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
