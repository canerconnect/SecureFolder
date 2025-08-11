#!/bin/bash

# Online-Terminbuchung Setup Script
# This script helps set up the development environment

echo "🚀 Online-Terminbuchung Setup Script"
echo "====================================="

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js 18+ first."
    exit 1
fi

# Check Node.js version
NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 18 ]; then
    echo "❌ Node.js version 18+ is required. Current version: $(node -v)"
    exit 1
fi

echo "✅ Node.js version: $(node -v)"

# Check if PostgreSQL is installed
if ! command -v psql &> /dev/null; then
    echo "❌ PostgreSQL is not installed. Please install PostgreSQL 12+ first."
    echo "   Ubuntu/Debian: sudo apt-get install postgresql postgresql-contrib"
    echo "   macOS: brew install postgresql"
    echo "   Windows: Download from https://www.postgresql.org/download/"
    exit 1
fi

echo "✅ PostgreSQL is installed"

# Check if .env file exists
if [ ! -f .env ]; then
    echo "📝 Creating .env file from template..."
    cp .env.example .env
    echo "⚠️  Please edit .env file with your configuration values"
    echo "   - Database credentials"
    echo "   - JWT secret"
    echo "   - Email/SMS settings"
else
    echo "✅ .env file already exists"
fi

# Install dependencies
echo "📦 Installing Node.js dependencies..."
npm install

# Check if database exists
DB_NAME="terminbuchung"
DB_EXISTS=$(psql -lqt | cut -d \| -f 1 | grep -qw "$DB_NAME")

if [ "$DB_EXISTS" ]; then
    echo "✅ Database '$DB_NAME' already exists"
else
    echo "🗄️  Creating database '$DB_NAME'..."
    createdb "$DB_NAME"
    
    if [ $? -eq 0 ]; then
        echo "✅ Database created successfully"
    else
        echo "❌ Failed to create database. Please check PostgreSQL configuration."
        exit 1
    fi
fi

# Run database schema
echo "🔧 Setting up database schema..."
psql -d "$DB_NAME" -f db/schema.sql

if [ $? -eq 0 ]; then
    echo "✅ Database schema created successfully"
else
    echo "❌ Failed to create database schema"
    exit 1
fi

# Create logs directory
if [ ! -d "logs" ]; then
    echo "📁 Creating logs directory..."
    mkdir logs
fi

# Create uploads directory
if [ ! -d "uploads" ]; then
    echo "📁 Creating uploads directory..."
    mkdir uploads
fi

echo ""
echo "🎉 Setup completed successfully!"
echo ""
echo "Next steps:"
echo "1. Edit .env file with your configuration"
echo "2. Start the development server: npm run dev"
echo "3. The API will be available at http://localhost:5000"
echo ""
echo "Sample data has been created for:"
echo "- arztpraxis.meinetermine.de"
echo "- anwalt.meinetermine.de"
echo ""
echo "Happy coding! 🚀"