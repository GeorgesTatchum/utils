# Télécharger l'installateur de l'agent AWS Discovery
powershell -command "& {
    iwr https://s3-us-west-2.amazonaws.com/aws-discovery-agent.us-west-2/windows/latest/AWSDiscoveryAgentInstaller.exe `
        -OutFile AWSDiscoveryAgentInstaller.exe
}"

# Exécuter l'installateur avec les paramètres nécessaires
.\AWSDiscoveryAgentInstaller.exe `
    REGION="eu-central-1" `
    KEY_ID="<AWS key ID>" `
    KEY_SECRET="<AWS key secret>" `
    /q

.\AwsReplicationWindowsInstaller.exe --region eu-central-1 --aws-access-key-id <AWS key ID> --aws-secret-access-key <AWS key secret> --no-prompt