using System;
using System.Diagnostics;
using System.IO;
using System.Runtime.InteropServices;

internal static class PocketPaneLauncher
{
    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    private static extern int MessageBox(IntPtr hWnd, string text, string caption, uint type);

    [STAThread]
    private static int Main()
    {
        string appDirectory = AppDomain.CurrentDomain.BaseDirectory;
        string scriptPath = Path.Combine(appDirectory, "PocketPane.Windows.ps1");

        if (!File.Exists(scriptPath))
        {
            MessageBox(IntPtr.Zero,
                "PocketPane.Windows.ps1 was not found next to PocketPane.exe. Please extract the complete release archive before starting PocketPane.",
                "PocketPane", 0x10);
            return 1;
        }

        try
        {
            var startInfo = new ProcessStartInfo
            {
                FileName = "powershell.exe",
                Arguments = "-NoLogo -NoProfile -ExecutionPolicy Bypass -File \"" + scriptPath + "\"",
                WorkingDirectory = appDirectory,
                UseShellExecute = false,
                CreateNoWindow = true
            };

            Process process = Process.Start(startInfo);
            if (process == null)
                throw new InvalidOperationException("Windows PowerShell could not be started.");
            return 0;
        }
        catch (Exception exception)
        {
            MessageBox(IntPtr.Zero, "PocketPane could not be started.\n\n" + exception.Message,
                "PocketPane", 0x10);
            return 1;
        }
    }
}
