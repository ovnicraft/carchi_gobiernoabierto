
# Gobierno Abierto de la Prefectura de Carchi

Fork de Open Irekia para la plataforma de Gobierno Abierto de la Prefectura de Carchi. 

## Instalación desarrollo

```
git clone https://github.com/alabs/carchi_gobiernoabierto
cd carchi_gobiernoabierto
rvm install 2.1.2
rvm use 2.1.2
bundle install 
cp config/database.yml.example config/database.yml
cp config/secrets.yml.example config/secrets.yml
# Configurar YMLs
rake db:migrate
```

## Instalación producción

Puedes ver como instalar CKAN con el script de instalación de Gobierno Abierto en https://github.com/alabs/carchi_deploy 

