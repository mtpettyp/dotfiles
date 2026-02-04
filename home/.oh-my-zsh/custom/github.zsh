function staging() {
  echo "You are about to deploy to STAGING"
  read "confirm?Are you sure? (y/n) "
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    gh workflow run "Promote to staging"
  else
    echo "Deployment cancelled."
  fi
}

function production() {
  echo "You are about to deploy to PRODUCTION"
  read "confirm?Are you sure? (y/n) "
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    gh workflow run "Promote to production"
  else
    echo "Deployment cancelled."
  fi
}
