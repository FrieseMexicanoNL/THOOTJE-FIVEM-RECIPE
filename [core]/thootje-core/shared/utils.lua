Thootje = Thootje or {}
Thootje.Functions = Thootje.Functions or {}

function Thootje.Debug(...)
    if Config.Debug then
        print('^3[THOOTJE-CORE]^7', ...)
    end
end

function Thootje.Trim(value)
    return (tostring(value or ''):gsub('^%s*(.-)%s*$', '%1'))
end
