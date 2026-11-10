# Azure Private Endpoints

There is an issue with Azure Private Endpoints and McKesson's DNS infrastructure.
Sometimes the DNS servers would wrongly return the public IP of a resource that has a private endpoint configured.
This would lead to errors (403, etc) when the resource is accessed over the public IP instead of the private IP.

The proposed workaround is to create manual DNS entries for every private endpoint.
The scripts in this folder are used to:
- Extract the list of private endpoints and the corresponding IP.
  This list would serve to open requests to add or remove DNS entries.
  The lists are committed in git to facilitate tracking of changes in the future.

- Check that the private endpoints have an A records, which would indicate that a manual 'workaround' record has been created.