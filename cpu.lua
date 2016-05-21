-- cpu.lua
-- This table represents the Chip8 processor

local class = require('middleclass')
local bit = require('bit')

local Cpu = class('Cpu')

local MEMORY_BYTE_SIZE          = 0x1000
local NUMBER_OF_REGISTERS       = 16
local ADDRESS_REGISTER_BIT_SIZE = 16
local STACK_SIZE                = 16
local SCREEN_WIDTH              = 32
local SCREEN_HEIGHT             = 64

function Cpu:initialize()

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

    self.address_register = 0

    -- Instruction start at 0x200, 0 to 0x1ff are for interpreter (not used)
    self.program_counter = 0x200

    self.stack = {}

    -- The screen buffer. The display for the Chip 8 is 64x32 (HxW)
    self.screen_buffer = {}
    for y = 1,SCREEN_HEIGHT do
        self.screen_buffer[y] = {}
        for x = 1,SCREEN_WIDTH do
            self.screen_buffer[y][x] = 0
        end
    end
end

function Cpu:print_state()
    for i,register in ipairs(self.registers) do
        print("--- V" .. bit.tohex(i-1, 1) .. ": 0x" .. bit.tohex(register, 4))
    end
    print("--- I: 0x" .. bit.tohex(self.address_register, 4))
    print("--- PC: 0x" .. bit.tohex(self.program_counter, 3))
    print("--- Stack: ")
    for i = 1,#self.stack do
        print("---        0x" .. bit.tohex(self.stack[i], 4))
    end
end

function Cpu:run()
    while true do
        local opcode = self:read_instruction(self.program_counter)
        print("0x" .. bit.tohex(self.program_counter-2, 3) .. " opcode: 0x" .. bit.tohex(opcode, 4))
        self:run_instruction(opcode)
        self:print_state()
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

function Cpu:add_to_register(register, value)
    -- Add value to register
    -- lua starts indexing at 1
    local index = register + 1
    self.registers[index] = self.registers[index] + value
end

function Cpu:get_register(register)
    -- Returns the value stored in register
    -- lua starts indexing at 1
    return self.registers[register+1]
end

function Cpu:get_memory(addr)
    -- Returns the value stored in memory at addr
    -- lua starts indexing at 1
    return self.memory[addr+1]
end

function Cpu:draw_to_screen(register_x, register_y, n)
    local pos_x, pos_y = self:get_register(register_x), self:get_register(register_y)
    local sprite = self:get_memory(self.address_register)
    -- TODO: proper implementation
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
            for y = 1,SCREEN_HEIGHT do
                self.screen_buffer[y] = {}
                for x = 1,SCREEN_WIDTH do
                    self.screen_buffer[y][x] = 0
                end
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
            -- TODO: proper implementation
            error("Not implemented: 0x" .. bit.tohex(opcode, 4))
        elseif last_bits == 1 then
            -- Set VX to VX or VY
            -- TODO: proper implementation
            error("Not implemented: 0x" .. bit.tohex(opcode, 4))
        elseif last_bits == 2 then
            -- Set VX to VX and VY
            -- TODO: proper implementation
            error("Not implemented: 0x" .. bit.tohex(opcode, 4))
        elseif last_bits == 3 then
            -- Set VX to VX xor VY
            -- TODO: proper implementation
            error("Not implemented: 0x" .. bit.tohex(opcode, 4))
        elseif last_bits == 4 then
            -- Add VX to VY. VF is set to 1 if there's a carry, 0 otherwise
            -- TODO: proper implementation
            error("Not implemented: 0x" .. bit.tohex(opcode, 4))
        elseif last_bits == 5 then
            -- Subtract VY from VX. VF is set to 0 if there's a borrow, 1 otherwise
            -- TODO: proper implementation
            error("Not implemented: 0x" .. bit.tohex(opcode, 4))
        elseif last_bits == 6 then
            -- Shifts VX right by 1. VF is set to the least significant bit of VX before the shift.
            -- TODO: proper implementation
            error("Not implemented: 0x" .. bit.tohex(opcode, 4))
        elseif last_bits == 7 then
            -- Set VX to VY minus VX. VY is set to 0 if there's a borrow, 1 otherwise
            -- TODO: proper implementation
            error("Not implemented: 0x" .. bit.tohex(opcode, 4))
        elseif last_bits == 0xe then
            -- Shifts VX left by 1. VF is set to the most significant bit before the shift.
            -- TODO: proper implementation
            error("Not implemented: 0x" .. bit.tohex(opcode, 4))
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
        -- TODO: proper implementation
        error("Not implemented: 0x" .. bit.tohex(opcode, 4))
    elseif leading_bits == 0xd then
        -- Sprites stored in memory at location in index register (I), 8bits wide. Wraps around the screen.
        -- If when drawn, clears a pixel, register VF is set to 1 otherwise it is zero. All drawing is XOR 
        -- drawing (i.e. it toggles the screen pixels). Sprites are drawn starting at position VX, VY. N is 
        -- the number of 8bit rows that need to be drawn. If N is greater than 1, second line continues at 
        -- position VX, VY+1, and so on.
        -- TODO: proper implementation (?)
        self:draw_to_screen(register_x, register_y, n)
    elseif leading_bits == 0xe then
        local last_byte = bit.band(opcode, 0x00ff)
        if last_byte == 0x9e then
            -- Skips the next instruction if the key stored in VX is pressed
            -- TODO: proper implementation
            error("Not implemented: 0x" .. bit.tohex(opcode, 4))
        elseif last_byte == 0xa1 then
            -- Skips the next instruction if the key stored in VX is not pressed
            -- TODO: proper implementation
            error("Not implemented: 0x" .. bit.tohex(opcode, 4))
        end 
    elseif leading_bits == 0xf then
        local last_byte = bit.band(opcode, 0x00ff)
        if last_byte == 0x07 then
            -- Set VX to the value of the delay timer
            -- TODO: proper implementation
            error("Not implemented: 0x" .. bit.tohex(opcode, 4))
        elseif last_byte == 0x0a then
            -- A key press is awaited and then stored in VX
            -- TODO: proper implementation
            error("Not implemented: 0x" .. bit.tohex(opcode, 4))
        elseif last_byte == 0x15 then
            -- Set the delay timer to VX
            -- TODO: proper implementation
            error("Not implemented: 0x" .. bit.tohex(opcode, 4))
        elseif last_byte == 0x18 then
            -- Set the sound timer to VX
            -- TODO: proper implementation
            error("Not implemented: 0x" .. bit.tohex(opcode, 4))
        elseif last_byte == 0x1e then
            -- Add VX to I
            -- TODO: proper implementation
            error("Not implemented: 0x" .. bit.tohex(opcode, 4))
        elseif last_byte == 0x29 then
            -- Sets I to the location of the sprite for the character in VX. Characters 0-F (in hexadecimal) 
            -- are represented by a 4x5 font.
            -- TODO: proper implementation
            error("Not implemented: 0x" .. bit.tohex(opcode, 4))
        elseif last_byte == 33 then
            -- Stores the binary-coded decimal representation of VX, with the most significant of three 
            -- digits at the address in I, the middle digit at I plus 1, and the least significant digit at I
            -- plus 2. (In other words, take the decimal representation of VX, place the hundreds digit in 
            -- memory at location in I, the tens digit at location I+1, and the ones digit at location I+2.)
            -- TODO: proper implementation
            error("Not implemented: 0x" .. bit.tohex(opcode, 4))
        elseif last_byte == 55 then
            -- Stores V0 to VX (including VX) in memory starting at address I.
            -- TODO: proper implementation
            error("Not implemented: 0x" .. bit.tohex(opcode, 4))
        elseif last_byte == 65 then
            -- Fills V0 to VX (including VX) with values from memory starting at address I.
            -- TODO: proper implementation
            error("Not implemented: 0x" .. bit.tohex(opcode, 4))
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

return Cpu
