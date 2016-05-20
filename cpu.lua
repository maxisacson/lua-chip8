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

    return cpu
end

function Cpu:run()
    while true do
        local opcode = self:read_instruction(self.program_counter)
        self.program_counter = self.program_counter + 2
        print("opcode: " .. bit.tohex(opcode, 4))
    end
end

function Cpu:read_rom(rom_path)
    -- Start dumping memory in location 0x200, byte-for-byte
    local memory_index = memory_address_to_index(0x200)
    local rom = assert(io.open(rom_path, "rb"))
    for byte in rom:read("*a"):gmatch(".") do
        self.memory[memory_index] = string.byte(byte)
        memory_index = memory_index + 1
    end
    rom:close()
end

function Cpu:read_instruction(addr)
    -- Read the instruction in memory located at addr
    
    local index = memory_address_to_index(addr)

    -- Since each opcode is 1 word (2 bytes) we read the byte at addr, shift it left by 8 bits, and take
    -- the bitwise or of this and the byte at the next memory location
    local first_byte = self.memory[index]
    local second_byte = self.memory[index+1]
    local opcode = bit.bor(bit.lshift(first_byte, 8), second_byte)
    return opcode 
end

function Cpu:dump_memory()
    for i = 1,MEMORY_BYTE_SIZE do
        io.write(bit.tohex(self.memory[i], 2))
    end
    io.write("\n")
end

function memory_address_to_index(mem_addr)
    -- Since arrays in lua begin at 1, we have to add 1 to all memory addresses to find the
    -- right place in the memory array
    return mem_addr + 1 
end

return Cpu
