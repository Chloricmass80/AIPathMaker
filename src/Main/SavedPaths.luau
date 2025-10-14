local CollectionService = game:GetService("CollectionService")
local savedPathsFldr = CollectionService:GetTagged("SavedPathsFldr")[1]
if not savedPathsFldr then
    savedPathsFldr = Instance.new("Folder")
    savedPathsFldr.Name = "SavedPathsFldr"
    savedPathsFldr:AddTag("SavedPathsFldr")
    savedPathsFldr.Parent = workspace
end

local SavedPaths = {
    Paths = {};
    SavedPathsFldr = savedPathsFldr
}

function SavedPaths:ReconstructFromSavedPaths()
    if not self.SavedPathsFldr then return end
    local Paths = require(script.Parent.Path)
    if self.Paths[1] then
        warn("Reconstructing the PathsFolder with Paths already present, overriding")
    end
    local paths = {}

    for _, pathFldr:Folder in ipairs(self.SavedPathsFldr:GetChildren()) do
        local path = Paths.ReconstructFromInst(pathFldr)
        local pathNum = pathFldr:GetAttribute("PathNum")
        paths[pathNum] = path
    end

    print(paths)

    self.Paths = paths
end

return SavedPaths