' Local (device-only) app preferences that have no KinoPub API counterpart.
' Includes the hide-anime filter and automatic next-episode prompt. Persisted
' via roRegistrySection, same pattern as TokenStore.brs/SearchHistoryStore.brs.
' Hide anime and the next-episode prompt both default to enabled.

function AppSettingsStore() as Object
    return {
        sectionName: "kinoappsettings"
        loadHideAnime: appSettingsLoadHideAnime
        saveHideAnime: appSettingsSaveHideAnime
        loadNextEpisodePromptEnabled: appSettingsLoadNextEpisodePromptEnabled
        saveNextEpisodePromptEnabled: appSettingsSaveNextEpisodePromptEnabled
    }
end function

function appSettingsLoadHideAnime() as Boolean
    section = CreateObject("roRegistrySection", m.sectionName)
    if section.Exists("hideAnime") <> true then return true
    return section.Read("hideAnime") = "1"
end function

sub appSettingsSaveHideAnime(value as Boolean)
    section = CreateObject("roRegistrySection", m.sectionName)
    text = "0"
    if value = true then text = "1"
    section.Write("hideAnime", text)
    section.Flush()
end sub

' Keep existing playback behavior for users who have not changed this setting.
function appSettingsLoadNextEpisodePromptEnabled() as Boolean
    section = CreateObject("roRegistrySection", m.sectionName)
    if section.Exists("nextEpisodePromptEnabled") <> true then return true
    return section.Read("nextEpisodePromptEnabled") = "1"
end function

sub appSettingsSaveNextEpisodePromptEnabled(value as Boolean)
    section = CreateObject("roRegistrySection", m.sectionName)
    text = "0"
    if value = true then text = "1"
    section.Write("nextEpisodePromptEnabled", text)
    section.Flush()
end sub
