Usage:
1. Put CsUninstallTool.exe to the target machine and save the path of the file.
2. Run the script via RTR using this command and adjust the script file name, maintenance token, and path.
   ```
   runscript -CloudFile="UninstallCrowdstrikeWIN"  -CommandLine=```'{"maintenance-token":"maintenance token","cs-uninstall-tool-location":"path"}'```
   ```
3. The script will run in the background. You can check the host status through host management, when the host status is Unknown or Offline, it means the agent has been successfully uninstalled.
