Script.sh is used when the anti-temper protection is on, so it needs a maintenance token. Script Without Maintenance Token.sh is used when the anti-temper protection is off, so it does not need a maintenance token. 
When we run Script.sh using RTR, detection will appear. You can exclude the detection that appears so that the same detection will not appear again when you run this uninstall script to another host. Another alternative is that you can turn off detection on the host before you run the script.

Usage:
```
runscript -CloudFile="UninstallCrowdstrikeMac"  -CommandLine="maintenance-token"
```
