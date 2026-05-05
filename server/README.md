# Uzaapp Backend deployment Guide

This directory contains the PHP scripts for the Uzaapp backend API.

## Requirements
- Web server (Apache with mod_rewrite enabled is recommended)
- PHP 7.4+
- MySQL/MariaDB database

## Deployment Steps

1. **Upload Files**: Upload all files from this `server` directory to your web server (e.g., in a directory named `api` if you want the URL to be `https://uzaapp.com/api/`).
2. **Database Setup**:
   - Create a MySQL database (e.g., `uzaapp_db`).
   - Import the schema from the `database_schema.sql` artifact.
3. **Configuration**:
   - Edit `server/config.php` and provide your database host, name, username, and password.
4. **Permissions**:
   - Ensure the `server/uploads/` directory is writable by the web server (e.g., `chmod 777` or appropriate ownership).
5. **API Base URL**:
   - The Flutter application is already configured to use `https://uzaapp.com/api/`. Ensure your deployment matches this path.

## Endpoints
- `GET /shops`: Retrieve all shops (supports `?updated_since=YYYY-MM-DD HH:MM:SS`)
- `GET /products`: Retrieve all products (supports `?updated_since=YYYY-MM-DD HH:MM:SS`)
- `GET /stories`: Retrieve all stories (supports `?updated_since=YYYY-MM-DD HH:MM:SS`)
- `POST /sync`: Synchronize local changes to the server.
- `POST /upload`: Upload images (multipart/form-data with `file` and optional `folder`).

## Troubleshooting
- If you get 404 errors for the endpoints, ensure `mod_rewrite` is enabled in Apache and the `.htaccess` file is being processed.
- Check `config.php` if you get 500 errors related to database connection.
