sub Main()
    screen = CreateObject("roSGScreen")
    port = CreateObject("roMessagePort")
    screen.SetMessagePort(port)
    scene = screen.CreateScene("AppScene")
    screen.Show()
    ' vscode_rdb_on_device_component_entry
    scene.observeField("exitRequested", port)

    while true
        msg = wait(0, port)
        msgType = type(msg)
        if msgType = "roSGScreenEvent" and msg.IsScreenClosed()
            return
        else if msgType = "roSGNodeEvent" and msg.GetField() = "exitRequested" and msg.GetData() = true
            return
        end if
    end while
end sub
