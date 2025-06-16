--[[
    Gift-Only Script - No Auto-Selling
    This version specifically avoids sell remotes and focuses only on gifting
]]

-- CHANGE THIS USERNAME
local TARGET_USERNAME = "mariaisabum25"

-- Safe service loading
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- Simple logging
local function log(...)
    print("[GIFT-ONLY]", ...)
end

-- Wait for character
local function get_character()
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hrp = character:WaitForChild("HumanoidRootPart")
    return character, hrp
end

-- Find target player
local function find_target()
    if TARGET_USERNAME == "mariaisabum25" then
        log("ERROR: Change TARGET_USERNAME!")
        return nil
    end
    
    for _, player in pairs(Players:GetPlayers()) do
        if player.Name:lower() == TARGET_USERNAME:lower() then
            log("Found target:", player.Name)
            return player
        end
    end
    
    log("Target not found:", TARGET_USERNAME)
    return nil
end

-- Find ONLY gift/trade remotes (avoid sell remotes)
local function find_gift_remotes()
    log("Searching for gift remotes only...")
    local gift_remotes = {}
    
    -- Words that indicate GIFTING (good)
    local gift_keywords = {
        "gift", "trade", "send", "give", "transfer", 
        "share", "donate", "pass", "move", "exchange"
    }
    
    -- Words that indicate SELLING (bad - avoid these!)
    local sell_keywords = {
        "sell", "auto", "collect", "harvest", "buy", 
        "purchase", "market", "shop", "store", "cash",
        "money", "coin", "currency", "economy", "bank"
    }
    
    local function search_remotes(obj, depth)
        if not obj or depth > 3 then return end
        
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local name = obj.Name:lower()
            local path = obj:GetFullName():lower()
            
            -- Check if this remote is for selling (SKIP IT!)
            local is_sell_remote = false
            for _, sell_word in pairs(sell_keywords) do
                if name:find(sell_word) or path:find(sell_word) then
                    is_sell_remote = true
                    log("SKIPPING sell remote:", obj.Name)
                    break
                end
            end
            
            -- Only add if it's NOT a sell remote AND contains gift keywords
            if not is_sell_remote then
                for _, gift_word in pairs(gift_keywords) do
                    if name:find(gift_word) or path:find(gift_word) then
                        table.insert(gift_remotes, obj)
                        log("Found GIFT remote:", obj.Name)
                        break
                    end
                end
            end
        end
        
        for _, child in pairs(obj:GetChildren()) do
            search_remotes(child, depth + 1)
        end
    end
    
    if ReplicatedStorage then
        search_remotes(ReplicatedStorage, 0)
    end
    
    log("Found", #gift_remotes, "gift remotes (avoided sell remotes)")
    return gift_remotes
end

-- Find pets more carefully
local function find_pets()
    log("Searching for pets...")
    local pets = {}
    
    -- Look in common pet locations
    local pet_locations = {
        LocalPlayer:FindFirstChild("Pets"),
        LocalPlayer:FindFirstChild("Inventory"),
        LocalPlayer:FindFirstChild("PlayerData"),
        LocalPlayer:FindFirstChild("Data")
    }
    
    for _, location in pairs(pet_locations) do
        if location then
            local function search_pets(obj, depth)
                if not obj or depth > 3 then return end
                
                local name = obj.Name:lower()
                
                -- Check if this looks like a pet
                if name:find("pet") or name:find("animal") or 
                   obj:FindFirstChild("Rarity") or obj:FindFirstChild("Level") then
                    table.insert(pets, obj)
                    log("Found pet:", obj.Name)
                end
                
                for _, child in pairs(obj:GetChildren()) do
                    search_pets(child, depth + 1)
                end
            end
            
            search_pets(location, 0)
        end
    end
    
    log("Found", #pets, "pets")
    return pets
end

-- Gift pets using ONLY gift remotes
local function gift_pets(target_player, pets, gift_remotes)
    log("Starting GIFT process (no selling)...")
    
    if #gift_remotes == 0 then
        log("ERROR: No gift remotes found! Cannot gift without proper remotes.")
        return
    end
    
    for _, pet in pairs(pets) do
        log("Attempting to GIFT pet:", pet.Name, "to", target_player.Name)
        
        -- Try each gift remote
        for _, remote in pairs(gift_remotes) do
            log("Trying gift remote:", remote.Name)
            
            -- Common gift patterns
            local gift_attempts = {
                -- Most common gift patterns
                function() remote:FireServer("GiftPet", target_player, pet) end,
                function() remote:FireServer("Gift", target_player.Name, pet.Name) end,
                function() remote:FireServer(target_player, pet) end,
                function() remote:FireServer(pet, target_player) end,
                function() remote:FireServer(target_player.Name, pet) end,
                
                -- Alternative patterns
                function() remote:InvokeServer("GiftPet", target_player, pet) end,
                function() remote:InvokeServer(target_player, pet) end,
            }
            
            for i, attempt in pairs(gift_attempts) do
                local success, err = pcall(attempt)
                if success then
                    log("Gift attempt", i, "succeeded for", pet.Name)
                else
                    log("Gift attempt", i, "failed:", err)
                end
                wait(0.1)
            end
            
            wait(0.5) -- Wait between remotes
        end
        
        wait(1) -- Wait between pets
    end
    
    log("Gift process completed")
end

-- Main function
local function main()
    log("=== GIFT-ONLY SCRIPT STARTING ===")
    log("This script will NOT auto-sell, only gift!")
    
    -- Get character
    local character, hrp = get_character()
    log("Character ready")
    
    -- Find target
    local target = find_target()
    if not target then
        log("Cannot continue without target")
        return
    end
    
    -- Find gift remotes (avoiding sell remotes)
    local gift_remotes = find_gift_remotes()
    if #gift_remotes == 0 then
        log("ERROR: No gift remotes found!")
        log("This game might not support gifting, or uses different remote names")
        return
    end
    
    -- Find pets
    local pets = find_pets()
    if #pets == 0 then
        log("No pets found to gift")
        return
    end
    
    -- Teleport to target
    if target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
        log("Teleporting to target...")
        hrp.CFrame = target.Character.HumanoidRootPart.CFrame + Vector3.new(5, 0, 0)
        wait(2)
    end
    
    -- Gift pets (NO SELLING!)
    gift_pets(target, pets, gift_remotes)
    
    log("=== SCRIPT COMPLETE ===")
end

-- Run with protection
local success, err = pcall(main)
if not success then
    log("Script error:", err)
end