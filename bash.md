# Check the Apache configuration syntax for errors
sudo apachectl configtest

# Reload Apache to apply configuration changes
sudo systemctl reload apache2

# View the last lines of the Apache error log in real-time
sudo tail -f /var/log/apache2/afterschoolgeekery_ssl_error.log

# Kill all Gunicorn processes forcefully
sudo pkill -9 gunicorn
# alias:
stop_tracking

# Start Gunicorn manually in the background with 4 workers
nohup gunicorn -w 4 -b 127.0.0.1:5000 app:app &
# alias:
start_tracking

# List all running processes
ps aux

# List all currently running Gunicorn processes
ps aux | grep gunicorn

# Send a GET request to test if a frontend file is served correctly (public URL)
curl -I https://afterschoolgeekery.org/index.html

# Send a GET request to test if a frontend file is served correctly (localhost)
curl -I http://127.0.0.1:5000/index.html

# Send a POST request to test if a backend endpoint is working (public URL)
curl -X POST https://afterschoolgeekery.org/api/auth/login \
-H "Content-Type: application/json" \
-d '{"email": "mekis.peter@example.com", "password": "adminpassword"}'

# Send a POST request to test if a backend endpoint is working (localhost)
curl -X POST http://127.0.0.1:5000/api/auth/login \
-H "Content-Type: application/json" \
-d '{"email": "mekis.peter@example.com", "password": "adminpassword"}'

# List all files, including hidden ones, in the current directory
ls -a

# Check permissions for a file or directory
ls -ld /var/www/afterschoolgeekery.org/root

# View the contents of an Apache site configuration file
sudo cat /etc/apache2/sites-available/afterschoolgeekery.org-le-ssl.conf

# Edit an Apache site configuration file
sudo nano /etc/apache2/sites-available/afterschoolgeekery.org-le-ssl.conf

# View the last lines of the Apache error log in real-time
sudo tail -f /var/log/apache2/afterschoolgeekery_ssl_error.log

# View the last lines of the Apache access log in real-time
sudo tail -f /var/log/apache2/afterschoolgeekery_ssl_access.log

# View Gunicorn logs if running with nohup (output is in nohup.out)
tail -f nohup.out

# Check system-wide logs (useful if Gunicorn doesn't log properly)
sudo journalctl -u gunicorn

# View Gunicorn output if started manually in the terminal
# (This only works if Gunicorn was started interactively, not as a daemon)

