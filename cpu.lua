-- cpu.lua
-- This table represents the Chip8 processor

local class = require('middleclass')
local bit = require('bit')

local Cpu = class('Cpu')

local MEMORY_BYTE_SIZE          = 0x1000
local NUMBER_OF_REGISTERS       = 16
local ADDRESS_REGISTER_BIT_SIZE = 16
local STACK_SIZE                = 16
local SCREEN_WIDTH              = 64
local SCREEN_HEIGHT             = 32
local KEYPAD_SIZE               = 16

function Cpu:initialize()
    -- Set the random seed
    math.randomseed(os.time())

    -- RAM
    self.memory = {}
    for i = 1,MEMORY_BYTE_SIZE do
        self.memory[i] = 0
    end

    -- Data registers V0 to VF
    self.registers = {}
    for i = 1,NUMBER_OF_REGISTERS do
        self.registers[i] = 0
    end

    -- Font set. This is stored in the first section of memory. Each row represents a character
    self.fontset = {
	    0xF0, 0x90, 0x90, 0x90, 0xF0, -- 0
	    0x20, 0x60, 0x20, 0x20, 0x70, -- 1
	    0xF0, 0x10, 0xF0, 0x80, 0xF0, -- 2
	    0xF0, 0x10, 0xF0, 0x10, 0xF0, -- 3
	    0x90, 0x90, 0xF0, 0x10, 0x10, -- 4
	    0xF0, 0x80, 0xF0, 0x10, 0xF0, -- 5
	    0xF0, 0x80, 0xF0, 0x90, 0xF0, -- 6
	    0xF0, 0x10, 0x20, 0x40, 0x40, -- 7
	    0xF0, 0x90, 0xF0, 0x90, 0xF0, -- 8
	    0xF0, 0x90, 0xF0, 0x10, 0xF0, -- 9
	    0xF0, 0x90, 0xF0, 0x90, 0x90, -- A
	    0xE0, 0x90, 0xE0, 0x90, 0xE0, -- B
	    0xF0, 0x80, 0x80, 0x80, 0xF0, -- C
	    0xE0, 0x90, 0x90, 0x90, 0xE0, -- D
	    0xF0, 0x80, 0xF0, 0x80, 0xF0, -- E
	    0xF0, 0x80, 0xF0, 0x80, 0x80  -- F
    }

    for i = 1,#self.fontset do
        self.memory[i] = self.fontset[i]
    end

    self.address_register = 0

    -- Instruction start at 0x200, 0 to 0x1ff are for interpreter (not used)
    self.program_counter = 0x200

    self.stack = {}

    -- The screen buffer. The display for the Chip 8 is 64x32 (HxW)
    self.screen_buffer = {}
    for i = 1,SCREEN_WIDTH*SCREEN_HEIGHT do
        self.screen_buffer[i] = 0
    end

    -- The key pad
    -- A 16 bit hexadecimal keypad
    --
    --    1 2 3 c
    --    4 5 6 d
    --    7 8 9 e
    --    a 0 b f
    --
    -- The keypad table will store 1 when the key is pressed and 0 when it is released.
    self.keypad = {}
    for i = 1,KEYPAD_SIZE do
        self.keypad[i] = 0
    end

    -- Delay timer
    self.delay_timer = 0

    -- Sound timer
    self.sound_timer = 0
end

function Cpu:print_state()
    for i,register in ipairs(self.registers) do
        print("--- V" .. bit.tohex(i-1, 1) .. ": 0x" .. bit.tohex(register, 4))
    end
    print("--- I:  0x" .. bit.tohex(self.address_register, 4))
    print("--- PC: 0x" .. bit.tohex(self.program_counter, 3))
    print("--- DT: 0x" .. bit.tohex(self.delay_timer, 4))
    print("--- ST: 0x" .. bit.tohex(self.sound_timer, 4))
    print("--- Stack: ")
    for i = 1,#self.stack do
        print("---        0x" .. bit.tohex(self.stack[i], 4))
    end
end

function Cpu:run()
    while true do
        local opcode = self:read_instruction()
        print("0x" .. bit.tohex(self.program_counter-2, 3) .. " opcode: 0x" .. bit.tohex(opcode, 4))
        self:run_instruction(opcode)
        --self:print_state()
        --self:dump_screen()
    end
end

function Cpu:read_rom(rom_path)
    -- Start dumping memory in location 0x200, byte-for-byte
    -- lua starts indexing at 1
    local memory_index = 0x200 + 1
    local rom = assert(io.open(rom_path, "rb"))
    for byte in rom:read("*a"):gmatch(".") do
        self.memory[memory_index] = string.byte(byte)
        memory_index = memory_index + 1
    end
    rom:close()
end

function Cpu:read_instruction()
    -- Read the instruction in memory located at program_counter
    -- lua starts indexing at 1
    local index = self.program_counter + 1

    -- Since each opcode is 1 word (2 bytes) we read the byte at addr, shift it left by 8 bits, and take
    -- the bitwise or of this and the byte at the next memory location
    local first_byte = self.memory[index]
    local second_byte = self.memory[index+1]
    local opcode = bit.bor(bit.lshift(first_byte, 8), second_byte)
    self.program_counter = self.program_counter + 2
    return opcode 
end

function Cpu:set_register(register, value)
    -- Set register to value
    -- lua starts indexing at 1
    local index = register + 1
    self.registers[index] = value
end

function Cpu:get_register(register)
    -- Returns the value stored in register
    -- lua starts indexing at 1
    return self.registers[register+1]
end

function Cpu:add_to_register(register, value)
    -- Add value to register
    -- lua starts indexing at 1
    local index = register + 1
    self.registers[index] = self.registers[index] + value
end

function Cpu:set_memory(addr, value)
    -- Stores value in memory at addr
    -- lua starts indexing at 1
    self.memory[addr+1] = value

function Cpu:get_memory(addr)
    -- Returns the value stored in memory at addr
    -- lua starts indexing at 1
    return self.memory[addr+1]
end

function Cpu:key_pressed(key)
    self.keypad[key+1] = 1
end

function Cpu:key_released(key)
    self.keypad[key+1] = 0
end

function Cpu:key_state(key)
    return self.keypad[key+1]
end

function Cpu:get_key()
    for keycode=0,0xf do
        if self:key_state(keycode) == 1 then
            return keycode
        end
    end
    return -1    
end

function Cpu:print_keys()
    for i,key in ipairs(self.keypad) do
        io.write(key)
    end
    io.write("\n")
end

function Cpu:draw_to_screen(register_x, register_y, n)
    local pos_x, pos_y = self:get_register(register_x), self:get_register(register_y)
  
    self:set_register(0xf, 0)

    -- y index each line of the sprite. The sprite is stored as n bytes in memory starting at the address
    -- stored in I (the address register).
    for y = 0, n-1 do
        local byte = self:get_memory(self.address_register + y)

        -- x index the pixels in this y-slice of the sprite. All slices are 1 byte long.
        -- x_offset_bits stores how many bits we need to rshift the byte to get the value of the current
        -- pixel.
        local x_offset_bits = 7
        for x = 0, 7 do
            local pixel = bit.band(bit.rshift(byte, x_offset_bits), 0x1)
            local screen_x = (pos_x + x) % SCREEN_WIDTH
            local screen_y = (pos_y + y) % SCREEN_HEIGHT
            if pixel == 1 then
                local current_pixel = self.screen_buffer[screen_x + screen_y*SCREEN_WIDTH + 1]
                if current_pixel == 1 then
                    -- Collision detected
                    -- Set VF to 1
                    self:set_register(0xf, 1)
                end
                self.screen_buffer[screen_x + screen_y*SCREEN_WIDTH + 1] = bit.bxor(current_pixel, pixel)
            end
            x_offset_bits = x_offset_bits - 1
        end
    end
end

function Cpu:run_instruction(opcode)
    -- TODO: more efficient implementation then if-elseif statements
    local leading_bits = bit.rshift(bit.band(opcode, 0xf000), 12)
    local register_x   = bit.rshift(bit.band(opcode, 0x0f00), 8)
    local register_y   = bit.rshift(bit.band(opcode, 0x00f0), 4)
    local value_nnn    = bit.band(opcode, 0x0fff)
    local value_nn     = bit.band(opcode, 0x00ff)
    local value_n      = bit.band(opcode, 0x000f)

    if leading_bits == 0 then
        if opcode == 0x00e0 then
            -- Clear the screen
            for i = 1,SCREEN_WIDTH*SCREEN_HEIGHT do
                self.screen_buffer[i] = 0
            end
        elseif opcode == 0x00ee then
            -- Return from subroutine
            self.program_counter = table.remove(self.stack)
        end
    elseif leading_bits == 1 then
        -- Jump to address NNN
        self.program_counter = value_nnn
    elseif leading_bits == 2 then
        -- Call subrouting at NNN
        table.insert(self.stack, self.program_counter)
        self.program_counter = value_nnn
    elseif leading_bits == 3 then
        -- Skip next instruction if VX equals NN
        local value = self:get_register(register_x)
        if value == value_nn then
            self.program_counter = self.program_counter + 2
        end
    elseif leading_bits == 4 then
        -- Skip next instruction if VX does not equal NN
        local value = self:get_register(register_x)
        if value ~= value_nn then
            self.program_counter = self.program_counter + 2
        end
    elseif leading_bits == 5 then
        -- Skip next instruction if VX equals VY
        local value_x, value_y = self:get_register(register_x), self:get_register(register_y)
        if value_x == value_y then
            self.program_counter = self.program_counter + 2
        end
    elseif leading_bits == 6 then
        -- Set VX to NN
        self:set_register(register_x, value_nn)
    elseif leading_bits == 7 then
        -- Add NN to VX
        self:add_to_register(register_x, value_nn)
    elseif leading_bits == 8 then
        local last_bits = bit.band(opcode, 0x000f)
        if last_bits == 0 then
            -- Set VX to the value of VY
            self:set_register(register_x, self:get_register(register_y))
        elseif last_bits == 1 then
            -- Set VX to VX or VY
            local value_x = self:get_register(register_x)
            local value_y = self:get_register(register_y)
            self:set_register(register_x, bit.bor(value_x, value_y))
        elseif last_bits == 2 then
            -- Set VX to VX and VY
            local value_x = self:get_register(register_x)
            local value_y = self:get_register(register_y)
            self:set_register(register_x, bit.band(value_x, value_y))
        elseif last_bits == 3 then
            -- Set VX to VX xor VY
            local value_x = self:get_register(register_x)
            local value_y = self:get_register(register_y)
            self:set_register(register_x, bit.bxor(value_x, value_y))
        elseif last_bits == 4 then
            -- Add VY to VX. VF is set to 1 if there's a carry, 0 otherwise
            local value_x = self:get_register(register_x)
            local value_y = self:get_register(register_y)
            local value = value_x + value_y
            self:set_register(0xf, 0)
            if bit.rshift(value, 8) > 0 then
                self:set_register(0xf, 1)
            end
            self:set_register(register_x, bit.band(value, 0xff))
        elseif last_bits == 5 then
            -- Subtract VY from VX. VF is set to 0 if there's a borrow, 1 otherwise
            local value_x = self:get_register(register_x)
            local value_y = self:get_register(register_y)
            local value = value_x - value_y
            self:set_register(0xf, 1)
            if value < 0 then
                self:set_register(0xf, 0)
            end
            self:set_register(register_x, value)
        elseif last_bits == 6 then
            -- Shifts VX right by 1. VF is set to the least significant bit of VX before the shift.
            local value = self:get_register(register_x)
            self:set_register(0xf, bit.band(value, 0x1))
            self:set_register(register_x, bit.rshift(value, 1))
        elseif last_bits == 7 then
            -- Set VX to VY minus VX. VY is set to 0 if there's a borrow, 1 otherwise
            -- TODO: proper implementation
            error("Not implemented: 0x" .. bit.tohex(opcode, 4))
        elseif last_bits == 0xe then
            -- Shifts VX left by 1. VF is set to the most significant bit before the shift.
            local value = self:get_register(register_x)
            self:set_register(0xf, bit.band(value, 0x80))
            self:set_register(register_x, bit.lshift(value, 1))
        end
    elseif leading_bits == 9 then
        -- Skip the next instruction if VX neq VY
        -- TODO: proper implementation
        error("Not implemented: 0x" .. bit.tohex(opcode, 4))
    elseif leading_bits == 0xa then
        -- Set I to NNN
        self.address_register = value_nnn
    elseif leading_bits == 0xb then
        -- Jump to the address NNN plus V0
        -- TODO: proper implementation
        error("Not implemented: 0x" .. bit.tohex(opcode, 4))
    elseif leading_bits == 0xc then
        -- Set VX to the bitwise and between a random number and NN
        local rnd = math.random(0x0, 0xff)
        local value = bit.band(self:get_register(register_x, rnd))
        self:set_register(register_x, value)
    elseif leading_bits == 0xd then
        -- Sprites stored in memory at location in index register (I), 8bits wide. Wraps around the screen.
        -- If when drawn, clears a pixel, register VF is set to 1 otherwise it is zero. All drawing is XOR 
        -- drawing (i.e. it toggles the screen pixels). Sprites are drawn starting at position VX, VY. N is 
        -- the number of 8bit rows that need to be drawn. If N is greater than 1, second line continues at 
        -- position VX, VY+1, and so on.
        -- TODO: proper implementation (?)
        self:draw_to_screen(register_x, register_y, value_n)
    elseif leading_bits == 0xe then
        local last_byte = bit.band(opcode, 0x00ff)
        if last_byte == 0x9e then
            -- Skips the next instruction if the key stored in VX is pressed
            if self:key_state(self:get_register(register_x)) == 1 then
                self.program_counter = self.program_counter + 2
            end
        elseif last_byte == 0xa1 then
            -- Skips the next instruction if the key stored in VX is not pressed
            if self:key_state(self:get_register(register_x)) ~= 1 then
                self.program_counter = self.program_counter + 2
            end
        end 
    elseif leading_bits == 0xf then
        local last_byte = bit.band(opcode, 0x00ff)
        if last_byte == 0x07 then
            -- Set VX to the value of the delay timer
            self:set_register(register_x, self.delay_timer)
        elseif last_byte == 0x0a then
            -- A key press is awaited and then stored in VX
            local key = self:get_key()
            if key == -1 then
                self.program_counter = self.program_counter - 2
            else
                self:set_register(register_x, key)
            end
        elseif last_byte == 0x15 then
            -- Set the delay timer to VX
            self.delay_timer = self:get_register(register_x)
        elseif last_byte == 0x18 then
            -- Set the sound timer to VX
            self.sound_timer = self:get_register(register_x)
        elseif last_byte == 0x1e then
            -- Add VX to I
            self.address_register = self.address_register + self:get_register(register_x)
        elseif last_byte == 0x29 then
            -- Sets I to the location of the sprite for the character in VX. Characters 0-F (in hexadecimal) 
            -- are represented by a 4x5 font.
            local value = self:get_register(register_x)
            self.address_register = value * 0x5
        elseif last_byte == 33 then
            -- Stores the binary-coded decimal representation of VX, with the most significant of three 
            -- digits at the address in I, the middle digit at I plus 1, and the least significant digit at I
            -- plus 2. (In other words, take the decimal representation of VX, place the hundreds digit in 
            -- memory at location in I, the tens digit at location I+1, and the ones digit at location I+2.)
            -- TODO: proper implementation
            error("Not implemented: 0x" .. bit.tohex(opcode, 4))
        elseif last_byte == 55 then
            -- Stores V0 to VX (including VX) in memory starting at address I.
            for i=0, register_x do
                self:set_memory(self.address_register + i, self:get_register(i))
            end
        elseif last_byte == 65 then
            -- Fills V0 to VX (including VX) with values from memory starting at address I.
            for i=0, register_x do
                self:set_register(i, self:get_memory(self.address_register + i))
            end
        end
    else
        -- Unrecoqnized instruction
        error("Unrecognized instruction: 0x" .. bit.tohex(opcode, 4))
    end
end

function Cpu:dump_memory()
    for i = 1,MEMORY_BYTE_SIZE do
        io.write(bit.tohex(self.memory[i], 2))
    end
    io.write("\n")
end

function Cpu:dump_screen()
    for y = 1,SCREEN_HEIGHT do
        for x = 1,SCREEN_WIDTH do
            if self.screen_buffer[x + (y-1)*SCREEN_WIDTH] == 1 then
                io.write("@")
            else
                io.write(" ")
            end
        end
        io.write("\n")
    end
end

return Cpu
