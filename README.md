# New-User
Rescan HBA function.

The goal of this function is to speed up the process of rescanning the HBAs on a VMware cluster.
Traditionally you would use one of the clients (C#, web or H5) to perform the rescans.

Using PowerCLI it was already possible to perform the rescan but this was in a serial fashion. Using Get-VMHost | Get-VMHostStorage -Refresh will get you the same result, but a whole lot slower.

## Future 
Now that the working baseline is done, the next step is to add some more error checking.

## Contributing
Create a fork of the project into your own reposity. Make all your necessary changes and create a pull request with a description on what was added or removed and details explaining the changes in lines of code. If approved, project owners will merge it.
 