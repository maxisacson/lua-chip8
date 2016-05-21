cpu = require('cpu'):new()
bit = require('bit')

cpu:read_rom("TETRIS")

--cpu:dump_memory()

cpu:run()
