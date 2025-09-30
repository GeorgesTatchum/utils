# INSTALLATION DE LA VM DEBIAN 13 AVEC VAGRANT

## Prérequis

- [VirtualBox](https://www.virtualbox.org/wiki/Downloads) ou un autre provider compatible
- [Vagrant](https://developer.hashicorp.com/vagrant/install)
- Git (optionnel, pour cloner des dépôts)

## Étapes d'installation

1. **Cloner le dépot**
    ```bash
    git clone https://github.com/GeorgesTatchum/utils.git
    cd utils && mkdir linux_data
    ```

2. **Démarrer la VM :**
    ```bash
    vagrant up
    ```

3. **Accéder à la VM :**
    ```bash
    vagrant ssh linux_formation
    ```

4. **Mise à jour de paquets**
    ```bash
    sudo apt update
    sudo apt upgrade
    ```

## Commandes utiles

- Arrêter la VM : `vagrant halt`
- Recharger la configuration : `vagrant reload`
- Détruire la VM : `vagrant destroy`

## Ressources

- [Documentation Vagrant](https://developer.hashicorp.com/vagrant/docs)
- [Images Debian Vagrant](https://portal.cloud.hashicorp.com/vagrant/discover/boxen/debian-13)
