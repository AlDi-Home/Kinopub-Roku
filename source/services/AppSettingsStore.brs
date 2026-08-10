' Local (device-only) app preferences that have no KinoPub API counterpart —
' currently just the "hide anime" content filter (Settings screen). Persisted
' via roRegistrySection, same pattern as TokenStore.brs/SearchHistoryStore.brs.
' Defaults to hidden (true) since that's the requested out-of-the-box behavior.

function AppSettingsStore() as Object
    return {
        sectionName: "kinoappsettings"
        loadHideAnime: appSettingsLoadHideAnime
        saveHideAnime: appSettingsSaveHideAnime
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
