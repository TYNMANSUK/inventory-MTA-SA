-- Font management for Inventory System

function createFonts()
    Fonts.main = dxCreateFont("assets/fonts/Roboto-Regular.ttf", 10) or "default-bold"
    Fonts.tooltipTitle = dxCreateFont("assets/fonts/Roboto-Regular.ttf", 12) or "default-bold"
    Fonts.tooltipText = dxCreateFont("assets/fonts/Roboto-Regular.ttf", 10) or "default-bold"
    Fonts.sectionHeader = dxCreateFont("assets/fonts/Roboto-Regular.ttf", 9) or "default-bold"
    
    if not Fonts.main or not Fonts.tooltipTitle or not Fonts.tooltipText or not Fonts.sectionHeader then
        outputChatBox("DEBUG: Failed to load custom font. Falling back to default.")
    else
        outputChatBox("DEBUG: Custom fonts loaded successfully.")
    end
end
