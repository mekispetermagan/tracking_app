Retrieving the production db (unaccessible because of dedicated app user):
```bash
sudo -u trackingapp cp /srv/tracking_app_backend/app/backend/progress.db /tmp/progress_latest.db
sudo chown peter:peter /tmp/progress_latest.db
```
