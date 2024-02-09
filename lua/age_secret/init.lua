local M = {}

-- Fetch configuration from environment variables
local config = {
    recipient = vim.fn.getenv("AGE_RECIPIENT") or "age1fht3gvntpeffl65jjhdlremkl8nqe2p0ml3e2zwf0n6jd7g7lsese4hscr",
    identity = vim.fn.getenv("AGE_IDENTITY") or "~/age-key.txt"
}

function M.setup(user_config)

    if user_config ~= nil then
        config.recipient = user_config.recipient or config.recipient
        config.identity = user_config.identity or config.identity
    end

    -- Ensure Neovim recognizes the .age file extension
    vim.cmd [[
      augroup AgeFileType
        autocmd!
        autocmd BufRead,BufNewFile *.age set filetype=age
      augroup END
    ]]

    -- Additional configuration specific to .age files
    vim.api.nvim_create_autocmd("FileType", {
        pattern = "age",
        callback = function()
            -- Add more settings as needed
            vim.o.backup = false
            vim.o.writebackup = false
            -- Set shada to empty to prevent storing any session information
            vim.opt.shada = ""
        end,
    })

    -- Create an autocmd for .age files
    vim.api.nvim_create_autocmd({"BufReadPre", "FileReadPre"}, {
        pattern = "*.age",
        callback = function()
            -- Set local buffer options for .age files
            vim.bo.swapfile = false  -- Equivalent to 'setlocal noswapfile'
            vim.bo.binary = true    -- Equivalent to 'setlocal bin'
            -- Optionally, set 'undofile' to false if you don't want undo history for these files
            vim.bo.undofile = false
        end,
    })

    vim.api.nvim_create_autocmd({"BufReadPost", "FileReadPost"}, {
        pattern = "*.age",
        callback = function()

            if config.identity == vim.NIL then
                error("Identity file not found. Please set the AGE_IDENTITY environment variable.")
            end

            -- Execute age decryption
            vim.cmd(string.format("silent '[,']!rage --decrypt -i %s", config.identity))

            -- Set local buffer options for .age files
            vim.bo.binary = false  -- Equivalent to 'setlocal nobin'

            -- Execute BufReadPost autocmd for the decrypted file
            local filename = vim.fn.expand("%:r")  -- Gets the file name without the .age extension
            vim.cmd(string.format("doautocmd BufReadPost %s", filename))
        end,
    })

    vim.api.nvim_create_autocmd({"BufWritePre", "FileWritePre"}, {
        pattern = "*.age",
        callback = function()
            -- Set local buffer options for .age files
            vim.bo.binary = true  -- Equivalent to 'setlocal bin'

            if config.recipient == vim.NIL then
                error("Recipient not specified. Please set the AGE_RECIPIENT environment variable.")
            end

            -- Execute age encryption
            vim.cmd(string.format("silent '[,']!rage --encrypt -r %s -a", config.recipient))
            vim.cmd("")
        end,
    })

    vim.api.nvim_create_autocmd({"BufWritePost", "FileWritePost"}, {
        pattern = "*.age",
        callback = function()
            -- Undo the last change (which is the encryption)
            vim.cmd("silent undo")

            -- Set local buffer options for .age files
            vim.bo.binary = false  -- Equivalent to 'setlocal nobin'
        end,
    })

    vim.api.nvim_create_user_command('SetAgeRecipient', function(args)
        M.set_recipient(args.args)
    end, { nargs = 1 }) 
    vim.api.nvim_create_user_command('SetAgeIdentity', function(args)
        M.set_identity(args.args)
    end, { nargs = 1 }) 
end

-- Function to change the recipient
function M.set_recipient(new_recipient)
    config.recipient = new_recipient
end

-- Function to change the identity
function M.set_identity(new_identity)
    config.identity = new_identity
end

return M
