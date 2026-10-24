-- ECProbe : outils d'exploration de l'API du jeu (WoW 1.12 / Lua 5.0)
--   /ecprobe mot     -> liste les noms globaux contenant le mot
--   /ecdump nom      -> affiche le contenu d'une table globale, ou le resultat
--   /ecframe nom    -> decrit un cadre de l interface (taille, ancres, enfants)
--                       d'une fonction AZS_Get*/AZS_Is* appelee sans argument
-- Le resultat s'affiche dans une fenetre copiable (Ctrl+A puis Ctrl+C)
-- et est sauvegarde dans ECProbeDB (ecrit a la fermeture du jeu).

ECProbeDB = ECProbeDB or {}

local frame = CreateFrame("Frame", "ECProbeFrame", UIParent)
frame:SetWidth(520)
frame:SetHeight(420)
frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
frame:SetFrameStrata("DIALOG")
frame:SetBackdrop({
  bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
  edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
  tile = true, tileSize = 32, edgeSize = 32,
  insets = { left = 11, right = 12, top = 12, bottom = 11 }
})
frame:EnableMouse(true)
frame:SetMovable(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", function() this:StartMoving() end)
frame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
frame:Hide()
tinsert(UISpecialFrames, "ECProbeFrame")

local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
title:SetPoint("TOP", frame, "TOP", 0, -16)
title:SetText("ECProbe - clique dans le texte, Ctrl+A puis Ctrl+C")

local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)

local scroll = CreateFrame("ScrollFrame", "ECProbeScroll", frame, "UIPanelScrollFrameTemplate")
scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -40)
scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -40, 20)

local edit = CreateFrame("EditBox", "ECProbeEdit", scroll)
edit:SetMultiLine(true)
edit:SetAutoFocus(false)
edit:SetMaxLetters(0)
edit:SetFontObject(ChatFontNormal)
edit:SetWidth(440)
edit:SetHeight(300)
edit:SetScript("OnEscapePressed", function() this:ClearFocus() end)
scroll:SetScrollChild(edit)

local function Show(key, lines)
  local n = table.getn(lines)
  local out = table.concat(lines, "\n")
  ECProbeDB.last = out
  ECProbeDB[key] = out
  edit:SetHeight(n * 14 + 60)
  edit:SetText(out)
  scroll:SetVerticalScroll(0)
  frame:Show()
end

-- /ecprobe mot
SLASH_ECPROBE1 = "/ecprobe"
SlashCmdList["ECPROBE"] = function(msg)
  msg = string.lower(msg or "")
  if msg == "" then
    DEFAULT_CHAT_FRAME:AddMessage("Usage : /ecprobe mot  (ex : /ecprobe azs)")
    return
  end
  local list = {}
  for k, v in pairs(getfenv(0)) do
    if type(k) == "string" and string.find(string.lower(k), msg, 1, true) then
      table.insert(list, k .. " (" .. type(v) .. ")")
    end
  end
  table.sort(list)
  table.insert(list, 1, "Recherche : " .. msg .. " - " .. table.getn(list) .. " resultat(s)")
  Show("probe_" .. msg, list)
end

-- /ecdump nom
local MAXLINES = 800

local function Dump(v, indent, depth, out)
  if type(v) ~= "table" then
    table.insert(out, indent .. tostring(v) .. " (" .. type(v) .. ")")
    return
  end
  local keys = {}
  for k in pairs(v) do table.insert(keys, k) end
  table.sort(keys, function(a, b) return tostring(a) < tostring(b) end)
  for i = 1, table.getn(keys) do
    local k = keys[i]
    local val = v[k]
    if type(val) == "table" then
      if depth < 3 then
        table.insert(out, indent .. tostring(k) .. " = {")
        Dump(val, indent .. "  ", depth + 1, out)
        table.insert(out, indent .. "}")
      else
        table.insert(out, indent .. tostring(k) .. " = {...}")
      end
    else
      table.insert(out, indent .. tostring(k) .. " = " .. tostring(val) .. " (" .. type(val) .. ")")
    end
    if table.getn(out) >= MAXLINES then
      table.insert(out, "... (tronque)")
      return
    end
  end
end

SLASH_ECDUMP1 = "/ecdump"
SlashCmdList["ECDUMP"] = function(msg)
  local name = msg or ""
  if name == "" then
    DEFAULT_CHAT_FRAME:AddMessage("Usage : /ecdump AZS_UNITS   ou   /ecdump AZS_GetLairs")
    return
  end
  local out = {}
  local v = getfenv(0)[name]
  if v == nil then
    table.insert(out, "Introuvable : " .. name)
  elseif type(v) == "function" then
    if string.find(name, "^AZS_Get") or string.find(name, "^AZS_Is") or name == "AZS_Gear" then
      local ok, a, b, c, d, e = pcall(v)
      table.insert(out, name .. "() -> " .. (ok and "ok" or "ERREUR"))
      local rets = { a, b, c, d, e }
      local any = false
      for i = 1, 5 do
        if rets[i] ~= nil then
          any = true
          table.insert(out, "retour " .. i .. " :")
          Dump(rets[i], "  ", 1, out)
        end
      end
      if not any then table.insert(out, "(aucun retour)") end
    else
      table.insert(out, "Refuse : seules les fonctions AZS_Get*, AZS_Is* et AZS_Gear sont appelees.")
    end
  else
    table.insert(out, name .. " (" .. type(v) .. ")")
    Dump(v, "  ", 1, out)
  end
  Show("dump_" .. name, out)
end

-- /ecframe nom : decrit un cadre (taille, parent, ancres, enfants, regions,
-- textures, polices, scripts, champs Lua)
local function NameOf(o)
  if type(o) == "table" and o.GetName then
    local n = o:GetName()
    if n then return n end
    return "(sans nom)"
  end
  return tostring(o)
end

local function Num(x)
  if type(x) == "number" then
    return tostring(math.floor(x * 1000 + 0.5) / 1000)
  end
  return tostring(x)
end

local function Color(r, g, b, a)
  return Num(r) .. "," .. Num(g) .. "," .. Num(b) .. "," .. Num(a)
end

-- infos visuelles d'une texture / d'un texte
local function VisInfo(o)
  local parts = {}
  if o.GetTexture then
    local ok, t = pcall(o.GetTexture, o)
    if ok then table.insert(parts, "texture=" .. tostring(t)) end
    local ok2, r, g, b, a = pcall(o.GetVertexColor, o)
    if ok2 and r then table.insert(parts, "teinte=" .. Color(r, g, b, a)) end
    if o.GetDrawLayer then
      local ok3, l = pcall(o.GetDrawLayer, o)
      if ok3 then table.insert(parts, "couche=" .. tostring(l)) end
    end
  end
  if o.GetFont then
    local ok, path, size, flags = pcall(o.GetFont, o)
    if ok then table.insert(parts, "police=" .. tostring(path) .. "," .. Num(size) .. "," .. tostring(flags)) end
  end
  if o.GetTextColor then
    local ok, r, g, b, a = pcall(o.GetTextColor, o)
    if ok and r then table.insert(parts, "couleurTexte=" .. Color(r, g, b, a)) end
  end
  if o.GetAlpha then
    local ok, a = pcall(o.GetAlpha, o)
    if ok then table.insert(parts, "alpha=" .. Num(a)) end
  end
  return table.concat(parts, " | ")
end

SLASH_ECFRAME1 = "/ecframe"
SlashCmdList["ECFRAME"] = function(msg)
  local name = msg or ""
  local fr = getfenv(0)[name]
  local out = {}
  if type(fr) ~= "table" or not fr.GetObjectType then
    table.insert(out, "Introuvable (ou pas un cadre) : " .. name)
    Show("frame_" .. name, out)
    return
  end

  table.insert(out, name .. " : " .. fr:GetObjectType())

  if fr.GetWidth then
    local line = "taille " .. Num(fr:GetWidth()) .. " x " .. Num(fr:GetHeight())
    if fr.GetScale then line = line .. " | echelle " .. Num(fr:GetScale()) end
    if fr.GetFrameStrata then line = line .. " | strate " .. tostring(fr:GetFrameStrata()) end
    if fr.GetFrameLevel then line = line .. " | niveau " .. tostring(fr:GetFrameLevel()) end
    if fr.IsShown then line = line .. " | visible " .. tostring(fr:IsShown()) end
    table.insert(out, line)
  end

  local vis = VisInfo(fr)
  if vis ~= "" then table.insert(out, vis) end

  if fr.GetParent then
    table.insert(out, "parent : " .. NameOf(fr:GetParent()))
  end

  if fr.GetPoint then
    for i = 1, 6 do
      local ok, point, relTo, relPoint, x, y = pcall(fr.GetPoint, fr, i)
      if not ok or point == nil then break end
      table.insert(out, "ancre " .. i .. " : " .. tostring(point) .. " sur " .. NameOf(relTo) ..
        " (" .. tostring(relPoint) .. ") decalage " .. Num(x) .. ", " .. Num(y))
    end
  end

  if fr.GetText then
    local ok, t = pcall(fr.GetText, fr)
    if ok and t then table.insert(out, "texte : " .. tostring(t)) end
  end

  -- scripts presents
  if fr.GetScript then
    local names = { "OnClick", "OnEnter", "OnLeave", "OnShow", "OnHide", "OnMouseUp", "OnMouseDown", "OnLoad", "OnUpdate" }
    local found = {}
    for i = 1, table.getn(names) do
      local ok, f = pcall(fr.GetScript, fr, names[i])
      if ok and f then table.insert(found, names[i]) end
    end
    if table.getn(found) > 0 then
      table.insert(out, "scripts : " .. table.concat(found, ", "))
    end
  end

  -- textures d'un bouton
  local texGetters = { "GetNormalTexture", "GetHighlightTexture", "GetPushedTexture", "GetDisabledTexture" }
  for i = 1, table.getn(texGetters) do
    local g = texGetters[i]
    if fr[g] then
      local ok, t = pcall(fr[g], fr)
      if ok and t then
        table.insert(out, g .. " : " .. NameOf(t) .. " " .. VisInfo(t))
      end
    end
  end

  -- champs Lua poses sur le cadre (key, id, ...)
  local fields = {}
  for k, v in pairs(fr) do
    if k ~= 0 then
      local d
      if type(v) == "table" then d = NameOf(v)
      elseif type(v) == "function" then d = "function"
      else d = tostring(v) end
      table.insert(fields, tostring(k) .. " = " .. d)
    end
  end
  table.sort(fields)
  if table.getn(fields) > 0 then
    table.insert(out, "champs Lua :")
    for i = 1, table.getn(fields) do
      table.insert(out, "  " .. fields[i])
    end
  end

  if fr.GetChildren then
    local kids = { fr:GetChildren() }
    table.insert(out, "enfants (" .. table.getn(kids) .. ") :")
    for i = 1, table.getn(kids) do
      if i > 60 then table.insert(out, "  ...") break end
      table.insert(out, "  " .. NameOf(kids[i]) .. " (" .. kids[i]:GetObjectType() .. ")")
    end
  end

  if fr.GetRegions then
    local regs = { fr:GetRegions() }
    table.insert(out, "regions (" .. table.getn(regs) .. ") :")
    for i = 1, table.getn(regs) do
      if i > 40 then table.insert(out, "  ...") break end
      local r = regs[i]
      local extra = ""
      if r.GetText then
        local ok, t = pcall(r.GetText, r)
        if ok and t then extra = " = " .. tostring(t) end
      end
      table.insert(out, "  " .. NameOf(r) .. " (" .. r:GetObjectType() .. ")" .. extra)
      local v = VisInfo(r)
      if v ~= "" then table.insert(out, "      " .. v) end
    end
  end

  Show("frame_" .. name, out)
end
