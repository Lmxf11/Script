-- Variáveis globais necessárias
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Configurações globais
local Settings = {
    multiplier = 1,
    maxspeed = 50,
    darkTheme = true
}

-- GUI principal
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local TopBar = Instance.new("Frame")
local Title = Instance.new("TextLabel")
local CloseButton = Instance.new("TextButton")

-- Configuração da GUI principal
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false

MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
MainFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
MainFrame.Size = UDim2.new(0, 400, 0, 300)
MainFrame.Active = true
MainFrame.Draggable = true
TopBar.Name = "TopBar"
TopBar.Parent = MainFrame
TopBar.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
TopBar.Size = UDim2.new(1, 0, 0, 30)

-- Sistemas principais
local Systems = {
    Animations = {},
    Sound = {},
    History = {},
    Connections = {} -- Para armazenar todas as conexões
}

-- Sistema de notificações melhorado
local function Notify(title, text, duration)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 3
        })
    end)
end


-- Sistema de limpeza de conexões
local function DisconnectAll()
    for _, connection in pairs(Systems.Connections) do
        if typeof(connection) == "RBXScriptConnection" then
            connection:Disconnect()
        end
    end
    Systems.Connections = {}
end

-- Adicionar após a declaração do TopBar e antes de criar os botões (aproximadamente linha 40):

-- Função para criar botões
local function CreateButton(name, pos, text)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Parent = MainFrame
    button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    button.Position = pos
    button.Size = UDim2.new(0, 180, 0, 40)
    button.Font = Enum.Font.SourceSans
    button.Text = text
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 16
    
    -- Efeito hover
    button.MouseEnter:Connect(function()
        button.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    end)
    
    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    end)
    
    return button
end

-- Então criar os botões:
local SpeedButton = CreateButton("SpeedButton", UDim2.new(0.05, 0, 0.2, 0), "Speed (Q)")
local FlyButton = CreateButton("FlyButton", UDim2.new(0.05, 0, 0.4, 0), "Fly (E)")
local NoclipButton = CreateButton("NoclipButton", UDim2.new(0.05, 0, 0.6, 0), "Noclip (R)")
local FlingButton = CreateButton("FlingButton", UDim2.new(0.55, 0, 0.2, 0), "Fling")

-- Adicionar após a criação dos outros botões:

-- Botão de fechar
local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Parent = TopBar
CloseButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
CloseButton.Position = UDim2.new(1, -25, 0.48, -10)
CloseButton.Size = UDim2.new(0, 20, 0, 20)
CloseButton.Font = Enum.Font.SourceSansBold
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.TextSize = 14

CloseButton.MouseButton1Click:Connect(function()
    DisconnectAll()
    ScreenGui:Destroy()
end)


-- Função de Speed corrigida
local function InitializeSpeed()
    local speedActive = false
    local speedConnection
    
    local function StartSpeed()
        if speedConnection then return end
        
        speedActive = true
        speedConnection = RunService.Heartbeat:Connect(function()
            if not speedActive then return end
            
            local character = LocalPlayer.Character
            local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
            
            if humanoidRootPart then
                humanoidRootPart.CFrame = humanoidRootPart.CFrame + 
                    humanoidRootPart.CFrame.lookVector * Settings.multiplier
            end
        end)
        
        Systems.Connections.Speed = speedConnection
    end
    
    local function StopSpeed()
        speedActive = false
        if speedConnection then
            speedConnection:Disconnect()
            speedConnection = nil
        end
    end
    
    -- Conectar controles
    local speedInputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.Q then
            StartSpeed()
        end
    end)
    
    local speedInputEndConnection = UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.Q then
            StopSpeed()
        end
    end)
    
    Systems.Connections.SpeedInput = speedInputConnection
    Systems.Connections.SpeedInputEnd = speedInputEndConnection
    
    Notify("Speed", "Press Q to use speed", 3)
end

-- Função de Fly corrigida
local function InitializeFly()
    local flying = false
    local ctrl = {f = 0, b = 0, l = 0, r = 0}
    local lastctrl = {f = 0, b = 0, l = 0, r = 0}
    local speed = 0
    local bg, bv
    
    local function Fly()
        local character = LocalPlayer.Character
        local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
        if not humanoidRootPart then return end
        
        -- Limpar instâncias anteriores
        if bg then bg:Destroy() end
        if bv then bv:Destroy() end
        
        bg = Instance.new("BodyGyro", humanoidRootPart)
        bg.P = 9e4
        bg.maxTorque = Vector3.new(9e9, 9e9, 9e9)
        bg.cframe = humanoidRootPart.CFrame
        
        bv = Instance.new("BodyVelocity", humanoidRootPart)
        bv.velocity = Vector3.new(0, 0.1, 0)
        bv.maxForce = Vector3.new(9e9, 9e9, 9e9)
        
        while flying and character:FindFirstChild("Humanoid") do
            if not RunService.Heartbeat:Wait() then break end
            
            character.Humanoid.PlatformStand = true
            
            -- Controle de velocidade
            if ctrl.l + ctrl.r ~= 0 or ctrl.f + ctrl.b ~= 0 then
                speed = speed + .5 + (speed / Settings.maxspeed)
                if speed > Settings.maxspeed then speed = Settings.maxspeed end
            else
                speed = speed - 1
                if speed < 0 then speed = 0 end
            end
            
            -- Movimento
            if (ctrl.l + ctrl.r) ~= 0 or (ctrl.f + ctrl.b) ~= 0 then
                bv.velocity = ((workspace.CurrentCamera.CoordinateFrame.lookVector * (ctrl.f + ctrl.b)) + 
                    ((workspace.CurrentCamera.CoordinateFrame * CFrame.new(ctrl.l + ctrl.r, (ctrl.f + ctrl.b) * .2, 0).p) - 
                    workspace.CurrentCamera.CoordinateFrame.p)) * speed
                lastctrl = {f = ctrl.f, b = ctrl.b, l = ctrl.l, r = ctrl.r}
            else
                bv.velocity = Vector3.new(0, 0.1, 0)
            end
            
            bg.cframe = workspace.CurrentCamera.CoordinateFrame * 
                CFrame.Angles(-math.rad((ctrl.f + ctrl.b) * 50 * speed / Settings.maxspeed), 0, 0)
        end
        
        -- Limpeza
        ctrl = {f = 0, b = 0, l = 0, r = 0}
        lastctrl = {f = 0, b = 0, l = 0, r = 0}
        speed = 0
        bg:Destroy()
        bv:Destroy()
        character.Humanoid.PlatformStand = false
    end
    
    -- Conectar controles do Fly
    local function HandleFlyInput(input, state)
        if input:lower() == "e" then
            if state then
                flying = not flying
                if flying then Fly() end
            end
        elseif input:lower() == "w" then
            ctrl.f = state and 1 or 0
        elseif input:lower() == "s" then
            ctrl.b = state and -1 or 0
        elseif input:lower() == "a" then
            ctrl.l = state and -1 or 0
        elseif input:lower() == "d" then
            ctrl.r = state and 1 or 0
        end
    end
    
    local mouse = LocalPlayer:GetMouse()
    
    Systems.Connections.FlyKeyDown = mouse.KeyDown:Connect(function(key)
        HandleFlyInput(key, true)
    end)
    
    Systems.Connections.FlyKeyUp = mouse.KeyUp:Connect(function(key)
        HandleFlyInput(key, false)
    end)
    
    Notify("Fly", "Press E to toggle fly", 3)
end

-- Sistema de Noclip melhorado
local function InitializeNoclip()
    local noclipActive = false
    local noclipConnection
    
    local function UpdateNoclip()
        local character = LocalPlayer.Character
        if not character then return end
        
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = not noclipActive
            end
        end
    end
    
    local function StartNoclip()
        if noclipConnection then return end
        
        noclipActive = true
        noclipConnection = RunService.Stepped:Connect(UpdateNoclip)
        Systems.Connections.Noclip = noclipConnection
        
        -- Reconectar quando o personagem respawnar
        Systems.Connections.NoclipCharacter = LocalPlayer.CharacterAdded:Connect(function()
            if noclipActive then
                wait(0.5) -- Esperar o personagem carregar
                UpdateNoclip()
            end
        end)
    end
    
    local function StopNoclip()
        noclipActive = false
        if noclipConnection then
            noclipConnection:Disconnect()
            noclipConnection = nil
        end
        UpdateNoclip()
    end
    
    return {
        Start = StartNoclip,
        Stop = StopNoclip,
        Toggle = function()
            if noclipActive then
                StopNoclip()
            else
                StartNoclip()
            end
        end
    }
end

-- Sistema de Fling melhorado
local function InitializeFling()
    local flingActive = false
    local originalPos
    local originalGravity
    local bv
    local flingConnection
    
    local function CleanupFling()
        if bv then bv:Destroy() end
        workspace.Gravity = originalGravity or 196.2
        flingActive = false
        
        if flingConnection then
            flingConnection:Disconnect()
            flingConnection = nil
        end
        
        local character = LocalPlayer.Character
        local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
        if humanoidRootPart and originalPos then
            humanoidRootPart.CFrame = originalPos
        end
    end
    
    local function FlingPlayer(targetName)
        local target = Players:FindFirstChild(targetName)
        if not target then
            Notify("Error", "Player not found!", 3)
            return
        end
        
        if target == LocalPlayer then
            Notify("Error", "Cannot fling yourself!", 3)
            return
        end
        
        local character = LocalPlayer.Character
        local humanoid = character and character:FindFirstChild("Humanoid")
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        
        if not (character and humanoid and rootPart) then
            Notify("Error", "Character not found!", 3)
            return
        end
        
        -- Salvar estado original
        originalPos = rootPart.CFrame
        originalGravity = workspace.Gravity
        workspace.Gravity = 0
        
        -- Configurar fling
        flingActive = true
        bv = Instance.new("BodyVelocity")
        bv.Parent = rootPart
        bv.Velocity = Vector3.new(9999999, 9999999, 9999999)
        bv.MaxForce = Vector3.new(9999999, 9999999, 9999999)
        
        -- Timeout de segurança
        local startTime = tick()
        local timeout = 5 -- 5 segundos máximo
        
        flingConnection = RunService.Heartbeat:Connect(function()
            if not flingActive or tick() - startTime > timeout then
                CleanupFling()
                return
            end
            
            local targetChar = target.Character
            local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
            
            if targetRoot then
                rootPart.CFrame = targetRoot.CFrame
            end
        end)
        
        -- Cleanup automático após timeout
        delay(timeout, CleanupFling)
    end
    
    -- Interface do Fling
    local FlingFrame = Instance.new("Frame")
    FlingFrame.Name = "FlingFrame"
    FlingFrame.Parent = MainFrame
    FlingFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    FlingFrame.Position = UDim2.new(0.5, -150, 0.5, -100)
    FlingFrame.Size = UDim2.new(0, 300, 0, 200)
    FlingFrame.Visible = false
    
    local PlayerInput = Instance.new("TextBox")
    PlayerInput.Name = "PlayerInput"
    PlayerInput.Parent = FlingFrame
    PlayerInput.Position = UDim2.new(0.1, 0, 0.2, 0)
    PlayerInput.Size = UDim2.new(0.8, 0, 0, 30)
    PlayerInput.Font = Enum.Font.SourceSans
    PlayerInput.PlaceholderText = "Enter player name"
    PlayerInput.Text = ""
    PlayerInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    PlayerInput.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    
    local ExecuteFling = Instance.new("TextButton")
    ExecuteFling.Name = "ExecuteFling"
    ExecuteFling.Parent = FlingFrame
    ExecuteFling.Position = UDim2.new(0.1, 0, 0.5, 0)
    ExecuteFling.Size = UDim2.new(0.8, 0, 0, 40)
    ExecuteFling.Font = Enum.Font.SourceSansBold
    ExecuteFling.Text = "FLING PLAYER"
    ExecuteFling.TextColor3 = Color3.fromRGB(255, 255, 255)
    ExecuteFling.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    
    local CloseFling = Instance.new("TextButton")
    CloseFling.Name = "CloseFling"
    CloseFling.Parent = FlingFrame
    CloseFling.Position = UDim2.new(0.1, 0, 0.8, 0)
    CloseFling.Size = UDim2.new(0.8, 0, 0, 30)
    CloseFling.Font = Enum.Font.SourceSans
    CloseFling.Text = "Close"
    CloseFling.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseFling.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    
    -- Conectar eventos
    ExecuteFling.MouseButton1Click:Connect(function()
        FlingPlayer(PlayerInput.Text)
    end)
    
    CloseFling.MouseButton1Click:Connect(function()
        FlingFrame.Visible = false
        CleanupFling()
    end)
    
    return {
        Frame = FlingFrame,
        Fling = FlingPlayer,
        Cleanup = CleanupFling
    }
end

-- Sistema de configurações melhorado
local function CreateSettingsSystem()
    local SettingsSystem = {
        currentSettings = {
            speed = 1,
            flySpeed = 50,
            flingPower = 50,
            darkTheme = true
        },
        callbacks = {},
        sliders = {}
    }
    
    -- Frame principal das configurações
    local SettingsFrame = Instance.new("Frame")
    SettingsFrame.Name = "SettingsFrame"
    SettingsFrame.Parent = MainFrame
    SettingsFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    SettingsFrame.Position = UDim2.new(1.02, 0, 0, 0)
    SettingsFrame.Size = UDim2.new(0, 200, 1, 0)
    SettingsFrame.Visible = false
    
    -- Título
    local SettingsTitle = Instance.new("TextLabel")
    SettingsTitle.Name = "SettingsTitle"
    SettingsTitle.Parent = SettingsFrame
    SettingsTitle.BackgroundTransparency = 1
    SettingsTitle.Position = UDim2.new(0, 10, 0, 10)
    SettingsTitle.Size = UDim2.new(1, -20, 0, 30)
    SettingsTitle.Font = Enum.Font.SourceSansBold
    SettingsTitle.Text = "Settings"
    SettingsTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    SettingsTitle.TextSize = 20
    
    -- Função melhorada para criar sliders
    local function CreateSlider(name, min, max, default, position)
        local SliderFrame = Instance.new("Frame")
        SliderFrame.Name = name .. "Frame"
        SliderFrame.Parent = SettingsFrame
        SliderFrame.BackgroundTransparency = 1
        SliderFrame.Position = position
        SliderFrame.Size = UDim2.new(1, -20, 0, 50)
        
        local SliderLabel = Instance.new("TextLabel")
        SliderLabel.Parent = SliderFrame
        SliderLabel.BackgroundTransparency = 1
        SliderLabel.Size = UDim2.new(1, 0, 0, 20)
        SliderLabel.Font = Enum.Font.SourceSans
        SliderLabel.Text = name
        SliderLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        SliderLabel.TextSize = 14
        
        local SliderBar = Instance.new("Frame")
        SliderBar.Name = "Bar"
        SliderBar.Parent = SliderFrame
        SliderBar.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        SliderBar.Position = UDim2.new(0, 0, 0.6, 0)
        SliderBar.Size = UDim2.new(1, 0, 0, 5)
        
        local SliderButton = Instance.new("TextButton")
        SliderButton.Name = "Button"
        SliderButton.Parent = SliderBar
        SliderButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        SliderButton.Position = UDim2.new((default - min)/(max - min), -6, 0, -5)
        SliderButton.Size = UDim2.new(0, 12, 0, 15)
        SliderButton.Text = ""
        
        local ValueLabel = Instance.new("TextLabel")
        ValueLabel.Parent = SliderFrame
        ValueLabel.BackgroundTransparency = 1
        ValueLabel.Position = UDim2.new(0, 0, 0.8, 0)
        ValueLabel.Size = UDim2.new(1, 0, 0, 20)
        ValueLabel.Font = Enum.Font.SourceSans
        ValueLabel.Text = tostring(default)
        ValueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        ValueLabel.TextSize = 14
        
        -- Sistema de drag melhorado
        local dragging = false
        local dragConnection
        local dragEndConnection
        
        local function UpdateSlider(input)
            if not dragging then return end
            
            local pos = math.clamp((input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
            local value = math.floor(min + (pos * (max - min)))
            
            SliderButton.Position = UDim2.new(pos, -6, 0, -5)
            ValueLabel.Text = tostring(value)
            
            -- Atualizar configurações
            SettingsSystem.currentSettings[string.lower(name):gsub(" ", "")] = value
            
            -- Chamar callback se existir
            if SettingsSystem.callbacks[name] then
                SettingsSystem.callbacks[name](value)
            end
            
            return value
        end
        
        SliderButton.MouseButton1Down:Connect(function()
            dragging = true
            
            -- Limpar conexões antigas
            if dragConnection then dragConnection:Disconnect() end
            if dragEndConnection then dragEndConnection:Disconnect() end
            
            -- Criar novas conexões
            dragConnection = UserInputService.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseMovement then
                    UpdateSlider(input)
                end
            end)
            
            dragEndConnection = UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                    dragConnection:Disconnect()
                    dragEndConnection:Disconnect()
                end
            end)
        end)
        
        -- Armazenar referência do slider
        SettingsSystem.sliders[name] = {
            frame = SliderFrame,
            button = SliderButton,
            value = ValueLabel,
            update = UpdateSlider
        }
        
        return UpdateSlider
    end
    
    -- Sistema de presets melhorado
    local presets = {
        default = {
            speed = 1,
            flySpeed = 50,
            flingPower = 50
        },
        fast = {
            speed = 5,
            flySpeed = 75,
            flingPower = 75
        },
        extreme = {
            speed = 10,
            flySpeed = 100,
            flingPower = 100
        }
    }
    
    local function ApplyPreset(presetName)
        local preset = presets[presetName]
        if not preset then return end
        
        for setting, value in pairs(preset) do
            SettingsSystem.currentSettings[setting] = value
            
            -- Atualizar slider visual
            local sliderName = setting:gsub("^%l", string.upper):gsub("(%l)(%u)", "%1 %2")
            if SettingsSystem.sliders[sliderName] then
                local slider = SettingsSystem.sliders[sliderName]
                slider.value.Text = tostring(value)
                slider.button.Position = UDim2.new((value - 1)/(100 - 1), -6, 0, -5)
            end
            
            -- Chamar callback
            if SettingsSystem.callbacks[sliderName] then
                SettingsSystem.callbacks[sliderName](value)
            end
        end
        
        Notify("Preset Applied", presetName .. " settings loaded!", 3)
    end
    
    -- Criar presets buttons
    local PresetFrame = Instance.new("Frame")
    PresetFrame.Name = "PresetFrame"
    PresetFrame.Parent = SettingsFrame
    PresetFrame.BackgroundTransparency = 1
    PresetFrame.Position = UDim2.new(0, 10, 0.65, 0)
    PresetFrame.Size = UDim2.new(1, -20, 0, 100)
    
    local function CreatePresetButton(name, position)
        local button = Instance.new("TextButton")
        button.Parent = PresetFrame
        button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        button.Position = position
        button.Size = UDim2.new(0.3, -5, 0, 25)
        button.Font = Enum.Font.SourceSans
        button.Text = name
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.TextSize = 14
        
        button.MouseButton1Click:Connect(function()
            ApplyPreset(string.lower(name))
        end)
        
        return button
    end
    
    -- Criar sliders
    CreateSlider("Speed", 1, 10, SettingsSystem.currentSettings.speed, UDim2.new(0, 10, 0, 50))
    CreateSlider("Fly Speed", 1, 100, SettingsSystem.currentSettings.flySpeed, UDim2.new(0, 10, 0, 120))
    CreateSlider("Fling Power", 1, 100, SettingsSystem.currentSettings.flingPower, UDim2.new(0, 10, 0, 190))
    
    -- Criar preset buttons
    CreatePresetButton("Default", UDim2.new(0, 0, 0.5, 0))
    CreatePresetButton("Fast", UDim2.new(0.35, 0, 0.5, 0))
    CreatePresetButton("Extreme", UDim2.new(0.7, 0, 0.5, 0))
    
    return SettingsSystem
end


-- Sistema de histórico melhorado
local function CreateHistorySystem()
    local HistorySystem = {
        actions = {},
        maxHistory = 50,
        frame = nil,
        list = nil
    }
    
    -- Criar interface do histórico
    local HistoryFrame = Instance.new("Frame")
    HistoryFrame.Name = "HistoryFrame"
    HistoryFrame.Parent = MainFrame
    HistoryFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    HistoryFrame.Position = UDim2.new(1.02, 0, 0, 0)
    HistoryFrame.Size = UDim2.new(0, 200, 1, 0)
    HistoryFrame.Visible = false
    
    local HistoryTitle = Instance.new("TextLabel")
    HistoryTitle.Name = "HistoryTitle"
    HistoryTitle.Parent = HistoryFrame
    HistoryTitle.BackgroundTransparency = 1
    HistoryTitle.Position = UDim2.new(0, 10, 0, 10)
    HistoryTitle.Size = UDim2.new(1, -20, 0, 30)
    HistoryTitle.Font = Enum.Font.SourceSansBold
    HistoryTitle.Text = "Action History"
    HistoryTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    HistoryTitle.TextSize = 20
    
    local HistoryList = Instance.new("ScrollingFrame")
    HistoryList.Name = "HistoryList"
    HistoryList.Parent = HistoryFrame
    HistoryList.BackgroundTransparency = 1
    HistoryList.Position = UDim2.new(0, 10, 0, 50)
    HistoryList.Size = UDim2.new(1, -20, 1, -60)
    HistoryList.ScrollBarThickness = 6
    HistoryList.ScrollingEnabled = true
    HistoryList.CanvasSize = UDim2.new(0, 0, 0, 0)
    
    -- Função para adicionar ação ao histórico
    function HistorySystem:AddAction(action)
        -- Adicionar timestamp
        local actionData = {
            text = action,
            timestamp = os.date("%H:%M:%S"),
            id = #self.actions + 1
        }
        
        -- Adicionar ao início da lista
        table.insert(self.actions, 1, actionData)
        
        -- Limitar tamanho do histórico
        if #self.actions > self.maxHistory then
            table.remove(self.actions, #self.actions)
        end
        
        self:UpdateDisplay()
    end
    
    -- Função para atualizar a exibição do histórico
    function HistorySystem:UpdateDisplay()
        -- Limpar lista atual
        for _, child in pairs(HistoryList:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end
        
        -- Adicionar novas entradas
        local yOffset = 0
        for i, action in ipairs(self.actions) do
            local actionEntry = Instance.new("Frame")
            actionEntry.Name = "Action_" .. action.id
            actionEntry.Parent = HistoryList
            actionEntry.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            actionEntry.BackgroundTransparency = 0.5
            actionEntry.Position = UDim2.new(0, 0, 0, yOffset)
            actionEntry.Size = UDim2.new(1, -10, 0, 40)
            
            local timeLabel = Instance.new("TextLabel")
            timeLabel.Parent = actionEntry
            timeLabel.BackgroundTransparency = 1
            timeLabel.Position = UDim2.new(0, 5, 0, 0)
            timeLabel.Size = UDim2.new(0, 50, 1, 0)
            timeLabel.Font = Enum.Font.SourceSans
            timeLabel.Text = action.timestamp
            timeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
            timeLabel.TextSize = 12
            timeLabel.TextXAlignment = Enum.TextXAlignment.Left
            
            local actionLabel = Instance.new("TextLabel")
            actionLabel.Parent = actionEntry
            actionLabel.BackgroundTransparency = 1
            actionLabel.Position = UDim2.new(0, 60, 0, 0)
            actionLabel.Size = UDim2.new(1, -65, 1, 0)
            actionLabel.Font = Enum.Font.SourceSans
            actionLabel.Text = action.text
            actionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            actionLabel.TextSize = 14
            actionLabel.TextXAlignment = Enum.TextXAlignment.Left
            actionLabel.TextWrapped = true
            
            yOffset = yOffset + 45
        end
        
        HistoryList.CanvasSize = UDim2.new(0, 0, 0, yOffset)
    end
    
    HistorySystem.frame = HistoryFrame
    HistorySystem.list = HistoryList
    
    return HistorySystem
end

-- Sistema de animações melhorado
local function CreateAnimationSystem()
    local AnimationSystem = {}
    
    -- Easing functions
    local function lerp(a, b, t)
        return a + (b - a) * t
    end
    
    local function easeOutQuad(t)
        return t * (2 - t)
    end
    
    local function easeInOutQuad(t)
        return t < 0.5 and 2 * t * t or -1 + (4 - 2 * t) * t
    end
    
    -- Animações básicas
    function AnimationSystem:SlideIn(frame, direction, duration)
        direction = direction or "right"
        duration = duration or 0.5
        
        local startPos = frame.Position
        local endPos
        
        if direction == "right" then
            endPos = UDim2.new(0.5, -frame.Size.X.Offset/2, startPos.Y.Scale, startPos.Y.Offset)
            frame.Position = UDim2.new(1, 0, startPos.Y.Scale, startPos.Y.Offset)
        elseif direction == "left" then
            endPos = UDim2.new(0.5, -frame.Size.X.Offset/2, startPos.Y.Scale, startPos.Y.Offset)
            frame.Position = UDim2.new(-1, 0, startPos.Y.Scale, startPos.Y.Offset)
        end
        
        frame.Visible = true
        
        local startTime = tick()
        local connection
        
        connection = RunService.RenderStepped:Connect(function()
            local elapsed = tick() - startTime
            local alpha = math.min(elapsed / duration, 1)
            
            local easedAlpha = easeOutQuad(alpha)
            
            frame.Position = UDim2.new(
                lerp(frame.Position.X.Scale, endPos.X.Scale, easedAlpha),
                lerp(frame.Position.X.Offset, endPos.X.Offset, easedAlpha),
                frame.Position.Y.Scale,
                frame.Position.Y.Offset
            )
            
            if alpha >= 1 then
                connection:Disconnect()
            end
        end)
    end
    
    function AnimationSystem:SlideOut(frame, direction, duration)
        direction = direction or "right"
        duration = duration or 0.5
        
        local startPos = frame.Position
        local endPos
        
        if direction == "right" then
            endPos = UDim2.new(1, 0, startPos.Y.Scale, startPos.Y.Offset)
        elseif direction == "left" then
            endPos = UDim2.new(-1, 0, startPos.Y.Scale, startPos.Y.Offset)
        end
        
        local startTime = tick()
        local connection
        
        connection = RunService.RenderStepped:Connect(function()
            local elapsed = tick() - startTime
            local alpha = math.min(elapsed / duration, 1)
            
            local easedAlpha = easeInOutQuad(alpha)
            
            frame.Position = UDim2.new(
                lerp(startPos.X.Scale, endPos.X.Scale, easedAlpha),
                lerp(startPos.X.Offset, endPos.X.Offset, easedAlpha),
                frame.Position.Y.Scale,
                frame.Position.Y.Offset
            )
            
            if alpha >= 1 then
                connection:Disconnect()
                frame.Visible = false
            end
        end)
    end
    
    function AnimationSystem:Pulse(button, scale, duration)
        scale = scale or 1.1
        duration = duration or 0.2
        
        local originalSize = button.Size
        local originalPosition = button.Position
        
        local startTime = tick()
        local connection
        
        connection = RunService.RenderStepped:Connect(function()
            local elapsed = tick() - startTime
            local alpha = math.min(elapsed / duration, 1)
            
            local easedAlpha = alpha < 0.5 
                and easeOutQuad(alpha * 2) * 0.5 
                or 1 - easeOutQuad((alpha - 0.5) * 2) * 0.5
            
            local currentScale = lerp(1, scale, easedAlpha)
            
            button.Size = UDim2.new(
                originalSize.X.Scale * currentScale,
                originalSize.X.Offset * currentScale,
                originalSize.Y.Scale * currentScale,
                originalSize.Y.Offset * currentScale
            )
            
            button.Position = UDim2.new(
                originalPosition.X.Scale,
                originalPosition.X.Offset - (button.AbsoluteSize.X - originalSize.X.Offset) * 0.5,
                originalPosition.Y.Scale,
                originalPosition.Y.Offset - (button.AbsoluteSize.Y - originalSize.Y.Offset) * 0.5
            )
            
            if alpha >= 1 then
                connection:Disconnect()
                button.Size = originalSize
                button.Position = originalPosition
            end
        end)
    end
    
    return AnimationSystem
end

-- Adicionar título
Title.Name = "Title"
Title.Parent = TopBar
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 10, 0, 0)
Title.Size = UDim2.new(1, -40, 1, 0)
Title.Font = Enum.Font.SourceSansBold
Title.Text = "Super Script GUI"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 18
Title.TextXAlignment = Enum.TextXAlignment.Left

-- Inicializar sistemas
local AnimationSystem = CreateAnimationSystem()
local HistorySystem = CreateHistorySystem()
local SettingsSystem = CreateSettingsSystem()
local NoclipSystem = InitializeNoclip()
local FlingSystem = InitializeFling()

-- Conectar botões às funções
SpeedButton.MouseButton1Click:Connect(function()
    InitializeSpeed()
    HistorySystem:AddAction("Speed activated")
    AnimationSystem:Pulse(SpeedButton)
end)

FlyButton.MouseButton1Click:Connect(function()
    InitializeFly()
    HistorySystem:AddAction("Fly activated")
    AnimationSystem:Pulse(FlyButton)
end)

NoclipButton.MouseButton1Click:Connect(function()
    NoclipSystem.Toggle()
    HistorySystem:AddAction("Noclip toggled")
    AnimationSystem:Pulse(NoclipButton)
end)

FlingButton.MouseButton1Click:Connect(function()
    FlingSystem.Frame.Visible = true
    HistorySystem:AddAction("Fling menu opened")
    AnimationSystem:Pulse(FlingButton)
end)

-- Adicionar botão de configurações
local SettingsButton = Instance.new("TextButton")
SettingsButton.Name = "SettingsButton"
SettingsButton.Parent = TopBar
SettingsButton.BackgroundTransparency = 1
SettingsButton.Position = UDim2.new(1, -90, 0, 0)
SettingsButton.Size = UDim2.new(0, 30, 1, 0)
SettingsButton.Font = Enum.Font.SourceSansBold
SettingsButton.Text = "⚙️"
SettingsButton.TextColor3 = Color3.fromRGB(255, 255, 255)
SettingsButton.TextSize = 20

-- Adicionar botão de histórico
local HistoryButton = Instance.new("TextButton")
HistoryButton.Name = "HistoryButton"
HistoryButton.Parent = TopBar
HistoryButton.BackgroundTransparency = 1
HistoryButton.Position = UDim2.new(1, -60, 0, 0)
HistoryButton.Size = UDim2.new(0, 30, 1, 0)
HistoryButton.Font = Enum.Font.SourceSansBold
HistoryButton.Text = "📋"
HistoryButton.TextColor3 = Color3.fromRGB(255, 255, 255)
HistoryButton.TextSize = 20

-- Conectar botões de menu
local settingsOpen = false
SettingsButton.MouseButton1Click:Connect(function()
    settingsOpen = not settingsOpen
    if settingsOpen then
        AnimationSystem:SlideIn(SettingsSystem.frame)
    else
        AnimationSystem:SlideOut(SettingsSystem.frame)
    end
    AnimationSystem:Pulse(SettingsButton)
end)

local historyOpen = false
HistoryButton.MouseButton1Click:Connect(function()
    historyOpen = not historyOpen
    if historyOpen then
        AnimationSystem:SlideIn(HistorySystem.frame)
    else
        AnimationSystem:SlideOut(HistorySystem.frame)
    end
    AnimationSystem:Pulse(HistoryButton)
end)

-- Notificação inicial
Notify("Script Loaded", "All features are ready to use!", 5)

-- Conectar tecla R para Noclip
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.R then
        NoclipSystem.Toggle()
        HistorySystem:AddAction("Noclip toggled via hotkey")
    end
end)

-- Atualizar configurações quando os sliders mudarem
SettingsSystem.callbacks["Speed"] = function(value)
    Settings.multiplier = value
end

SettingsSystem.callbacks["Fly Speed"] = function(value)
    Settings.maxspeed = value
end

-- Adicionar cantos arredondados aos frames
local function AddCorners(frame)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
end

AddCorners(MainFrame)
AddCorners(TopBar)
AddCorners(FlingSystem.Frame)
AddCorners(SettingsSystem.frame)
AddCorners(HistorySystem.frame)

-- Adicionar sombras
local function AddShadow(frame)
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.BackgroundTransparency = 1
    shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
    shadow.Size = UDim2.new(1, 30, 1, 30)
    shadow.ZIndex = frame.ZIndex - 1
    shadow.Image = "rbxassetid://5554236805"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.6
    shadow.Parent = frame
end

AddShadow(MainFrame)

-- Sistema de salvamento de posição
local function SavePosition()
    local pos = MainFrame.Position
    if writefile then
        writefile("GUIPosition.txt", string.format("%f,%f", pos.X.Scale, pos.Y.Scale))
    end
end

local function LoadPosition()
    if readfile and isfile and isfile("GUIPosition.txt") then
        local data = readfile("GUIPosition.txt")
        local x, y = data:match("([^,]+),([^,]+)")
        if x and y then
            MainFrame.Position = UDim2.new(tonumber(x), 0, tonumber(y), 0)
        end
    end
end

-- Carregar posição salva
pcall(LoadPosition)

-- Salvar posição ao fechar
CloseButton.MouseButton1Click:Connect(function()
    pcall(SavePosition)
    DisconnectAll()
    ScreenGui:Destroy()
end)

-- Proteção contra erros
local success, error = pcall(function()
    -- Verificar se o jogador tem personagem
    if not LocalPlayer.Character then
        LocalPlayer.CharacterAdded:Wait()
    end
end)

if not success then
    warn("Error initializing script:", error)
end

-- Otimizações finais
local function OptimizePerformance()
    -- Reduzir atualizações desnecessárias
    RunService:Set3dRenderingEnabled(true)
    settings().Physics.PhysicsEnvironmentalThrottle = Enum.EnviromentalPhysicsThrottle.DefaultAuto
    
    -- Limpar conexões não utilizadas periodicamente
    spawn(function()
        while wait(30) do
            for name, connection in pairs(Systems.Connections) do
                if not connection.Connected then
                    Systems.Connections[name] = nil
                end
            end
        end
    end)
end

-- Atalhos de teclado adicionais
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.RightControl then
        MainFrame.Visible = not MainFrame.Visible
    elseif input.KeyCode == Enum.KeyCode.End then
        DisconnectAll()
        ScreenGui:Destroy()
    end
end)

-- Melhorar feedback visual
local function AddButtonFeedback(button)
    button.MouseEnter:Connect(function()
        game:GetService("TweenService"):Create(button, TweenInfo.new(0.2), {
            BackgroundColor3 = button.BackgroundColor3:Lerp(Color3.fromRGB(255, 255, 255), 0.2)
        }):Play()
    end)
    
    button.MouseLeave:Connect(function()
        game:GetService("TweenService"):Create(button, TweenInfo.new(0.2), {
            BackgroundColor3 = button.BackgroundColor3:Lerp(Color3.fromRGB(60, 60, 60), 0.2)
        }):Play()
    end)
end

-- Aplicar feedback a todos os botões
for _, button in pairs(MainFrame:GetDescendants()) do
    if button:IsA("TextButton") then
        AddButtonFeedback(button)
    end
end

-- Inicializar otimizações
OptimizePerformance()

-- Notificação de atalhos
Notify("Keyboard Shortcuts", "RightControl - Toggle GUI\nEnd - Close GUI", 5)
