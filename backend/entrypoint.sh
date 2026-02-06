#!/bin/sh
set -e  # Exit immediately if any command fails

echo "🚀 [Startup] Starting deployment checks..."

# 1. Run Migrations
# We force the path to ensure Sequelize finds the files inside the container.
# If the table already exists, this does nothing (safe).
echo "📦 [Migration] Checking database schema..."
npx sequelize-cli db:migrate --config config/config.cjs --migrations-path migrations

# 2. Run Seeds
# Your seeder code is "idempotent" (it checks for duplicates), 
# so it is safe to run this on every single startup.
echo "🌱 [Seeding] Verifying default data..."
npx sequelize-cli db:seed:all --config config/config.cjs --seeders-path seeders

# 3. Start Application
echo "✅ [Ready] Starting Backend Server..."
npm run start:docker