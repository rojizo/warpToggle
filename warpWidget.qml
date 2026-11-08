
import QtQuick
import Quickshell
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    property bool connected: false
    property bool busy: false
    property string statusText: "Consultando..."

    // Consultar el estado real de WARP
    function refreshStatus() {
        Proc.runCommand(
            "warpToggle.status",
            [
                "bash", "-c",
                "if ! systemctl is-active --quiet warp-svc.service; then echo 'Status update: Disconnected'; exit 0; fi; warp-cli status"
            ],
            (output, exitCode) => {
                if (exitCode !== 0) {
                    connected = false
                    statusText = "Desconectado"
                    return
                }

                const match = output.match(
                    /Status update: (Connected|Disconnected)/
                )

                if (match) {
                    connected = match[1] === "Connected"
                    statusText = connected
                        ? "Conectado"
                        : "Desconectado"
                }
            },
            100
        )
    }

    // Alternar conexión
    function toggleWarp() {
        if (busy)
            return

        busy = true
        statusText = "Cambiando..."

        const script = connected ? "warp-off" : "warp-on"

        Proc.runCommand(
            "warpToggle.action",
            [
                "bash", "-c",
                'exec "$HOME/.config/dms/plugins/warpToggle/scripts/' + script + '"'
            ],
            (output, exitCode) => {
                busy = false

                if (exitCode !== 0) {
                    console.warn("WARP: error ejecutando", script, output)
                }

                refreshStatus()
            },
            100
        )
    }

    // Propiedades del botón de DMS
    ccWidgetIcon: "shield"

    ccWidgetPrimaryText: "Cloudflare WARP"

    ccWidgetSecondaryText: busy
        ? "Cambiando..."
        : statusText

    ccWidgetIsActive: connected

    ccWidgetIsToggle: true

    onCcWidgetToggled: root.toggleWarp()

    // Consultar al iniciar
    Component.onCompleted: refreshStatus()

    // Actualizar periódicamente por si cambia desde terminal
    Timer {
        interval: 8000
        running: true
        repeat: true

        onTriggered: {
            if (!root.busy)
                root.refreshStatus()
        }
    }
}
