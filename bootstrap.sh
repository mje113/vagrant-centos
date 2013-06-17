# centos default restricts sudo, manually fix.
sudo echo ''
if [ $? -ne 0 ]; then
  echo "Please remove 'Defaults requiretty' from /etc/sudoers then re-provision"
  exit 1
fi

# start clean
if command -v rvm >/dev/null; then
  echo 'RVM removed'
  sudo rm -rf $HOME/.rvm $HOME/.rvmrc /etc/rvmrc /etc/profile.d/rvm.sh /usr/local/rvm /usr/local/bin/rvm
  sudo /usr/sbin/groupdel rvm
fi

# sudo should never have rvm
if sudo bash -c 'command -v rvm >/dev/null'; then
  echo 'rvm deteced for sudo, something is wrong!'
  exit 1
fi

# curl-devel doesn't come in centos minimal, the others are just for hacking
yum install -y curl-devel vim sqlite-devel

# this is the rpm that rvm complains about, installing it directly surpresses errors
sudo rpm -iUv https://dl.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm

# never need local gem documentation
echo "gem: --no-ri --no-rdoc" > ~/.gemrc

curl -L https://get.rvm.io | bash -s stable --rails --ruby=2.0.0-p195
source ~/.bash_profile
rvm use ruby-2.0.0-p195 --default
gem install passenger

rvmsudo passenger-install-nginx-module --prefix=/etc/nginx --auto --auto-download --extra-configure-flags='--sbin-path=/usr/sbin/nginx --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --pid-path=/var/run/nginx.pid --lock-path=/var/run/nginx.lock --user=nginx --group=nginx --with-mail --with-mail_ssl_module --with-http_sub_module'

sudo cp /vagrant/nginx_init.sh /etc/init.d/nginx
sudo chown root:root /etc/init.d/nginx
sudo chmod +x /etc/init.d/nginx
sudo mkdir -p /etc/nginx
sudo cp /vagrant/nginx.conf /etc/nginx/nginx.conf

# Test app
rm -rf ~/test_app
rails new ~/test_app
sudo /etc/init.d/nginx start

