local map = vim.keymap.set

map("n", "<leader>tt", "<cmd>terminal<cr>", { desc = "Terminal" })
map("n", "<leader>qq", "<cmd>qa<cr>", { desc = "Quit all" })
map("n", "<leader>ww", "<cmd>w<cr>", { desc = "Write file" })
