export $(grep -v '^#' .env | xargs)

if [ $NITROX_ENVIRONMENT = 'development' ]; then
  bundle exec rerun -- rackup --server puma -o 0.0.0.0 -p $NITROX_PORT
else
  bundle exec rackup --server puma -o 0.0.0.0 -p $NITROX_PORT --env production
fi
