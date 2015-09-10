
# Gobierno Abierto de la Prefectura de Carchi

Aplicación Ruby On Rails, fork de Open Irekia para la plataforma de Gobierno Abierto de la Prefectura de Carchi. 

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
rake db:schema:load
rake db:seed
```

## Instalación producción

Puedes ver como instalar CKAN con el script de instalación de Gobierno Abierto en https://github.com/alabs/carchi_deploy 


# Servidor de desarrollo

Para comprobar los cambios en local, hace falta ejecutar el comando: 

```
rails server
```

Podremos visitar la web en http://localhost:3000

# Ejecución de tests

Para comprobar que todos los tests se ejecutan correctamente se puede ver con el comando: 
```
rake test 
```

# Deploy 

Utilizamos capistrano para subir los cambios. Configurar en config/deploy.rb, config/deploy/staging.rb y config/deploy/production.rb. Subir cambios committeando a las ramas git production o staging y ejecutando:

``` 
cap staging deploy
cap production deploy
```
