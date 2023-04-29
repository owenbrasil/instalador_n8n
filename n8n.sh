# Configurações da instalação
read -p "Digite o nome da aplicação: " APP_NAME
read -p "Digite o domínio da aplicação: " DOMAIN_NAME
read -p "Digite a porta que deseja utilizar: " PORT

# Verifica se a porta está em uso
if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null ; then
    echo "A porta $PORT já está em uso. Por favor, escolha outra porta."
    exit 1
fi

# Verifica se o n8n já está instalado
if ! command -v n8n &> /dev/null
then
    # Instala as dependências
    sudo apt-get update
    sudo apt-get install -y curl gnupg git
    curl -sL https://deb.nodesource.com/setup_16.x | sudo -E bash -
    sudo apt-get install -y nodejs
    sudo npm install n8n -g
    sudo npm install pm2 -g
fi

# Configura o Nginx
sudo nano /etc/nginx/sites-available/$DOMAIN_NAME
echo "server {
  server_name $DOMAIN_NAME;

  location / {
    proxy_pass http://127.0.0.1:$PORT;

    proxy_http_version 1.1;

    proxy_set_header Upgrade \$http_upgrade;

    proxy_set_header Connection 'upgrade';

    proxy_set_header Host \$host;

    proxy_set_header X-Real-IP \$remote_addr;

    proxy_set_header X-Forwarded-Proto \$scheme;

    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;

    proxy_cache_bypass \$http_upgrade;

    proxy_buffering off;

    proxy_cache off;
  }
}" | sudo tee /etc/nginx/sites-available/$DOMAIN_NAME > /dev/null

sudo ln -s /etc/nginx/sites-available/$DOMAIN_NAME /etc/nginx/sites-enabled
sudo certbot --nginx
sudo service nginx restart

# Inicia o N8N com PM2
pm2 start n8n --name $APP_NAME --cron-restart="0 0 * * *" -- -p $PORT

echo "Instalação concluída! Acesse $DOMAIN_NAME para utilizar o N8N na porta $PORT."
