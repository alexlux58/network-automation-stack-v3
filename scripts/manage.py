#!/usr/bin/env python3
"""
Management script for NetBox + Nautobot stack
Provides convenient commands for managing the Docker Compose stack
"""

import os
import sys
import subprocess
import argparse
from pathlib import Path

# Change to script directory
script_dir = Path(__file__).parent
os.chdir(script_dir.parent)

def run_command(cmd, capture_output=False):
    """Run a command and return the result"""
    try:
        if capture_output:
            result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
            return result.returncode, result.stdout, result.stderr
        else:
            return subprocess.run(cmd, shell=True).returncode
    except Exception as e:
        print(f"Error running command '{cmd}': {e}")
        return 1

def check_env_file():
    """Check if .env file exists"""
    if not os.path.exists('.env'):
        print("❌ .env file not found. Run 'make init' first.")
        return False
    return True

def load_env():
    """Load environment variables from .env file"""
    if not check_env_file():
        return False
    
    with open('.env', 'r') as f:
        for line in f:
            if line.strip() and not line.startswith('#'):
                key, value = line.strip().split('=', 1)
                os.environ[key] = value
    return True

def up():
    """Start the stack"""
    print("🚀 Starting NetBox + Nautobot stack...")
    return run_command("docker compose up -d")

def down():
    """Stop the stack"""
    print("🛑 Stopping NetBox + Nautobot stack...")
    return run_command("docker compose down")

def restart():
    """Restart the applications"""
    print("🔄 Restarting applications...")
    return run_command("docker compose restart netbox nautobot")

def logs():
    """Show logs"""
    print("📋 Showing logs (Ctrl+C to exit)...")
    return run_command("docker compose logs -f --tail=200")

def status():
    """Show status of containers"""
    print("📊 Container status:")
    return run_command("docker ps --format 'table {{.Names}}\\t{{.Ports}}\\t{{.Status}}'")

def nb_create_superuser():
    """Create NetBox superuser interactively"""
    print("👤 Creating NetBox superuser...")
    return run_command("docker compose exec netbox python manage.py createsuperuser")

def nb_shell():
    """Open NetBox Django shell"""
    print("🐍 Opening NetBox Django shell...")
    return run_command("docker compose exec netbox python manage.py shell")

def nb_collectstatic():
    """Collect NetBox static files"""
    print("📦 Collecting NetBox static files...")
    return run_command("docker compose exec netbox python manage.py collectstatic --noinput")

def na_create_superuser():
    """Create Nautobot superuser non-interactively"""
    if not load_env():
        return 1
    
    print("👤 Creating Nautobot superuser...")
    cmd = f"""docker compose exec -e DJANGO_SUPERUSER_USERNAME={os.environ.get('NAUTOBOT_SUPERUSER_NAME')} \
                    -e DJANGO_SUPERUSER_EMAIL={os.environ.get('NAUTOBOT_SUPERUSER_EMAIL')} \
                    -e DJANGO_SUPERUSER_PASSWORD={os.environ.get('NAUTOBOT_SUPERUSER_PASSWORD')} \
                    nautobot nautobot-server createsuperuser --noinput"""
    return run_command(cmd)

def na_shell():
    """Open Nautobot Django shell"""
    print("🐍 Opening Nautobot Django shell...")
    return run_command("docker compose exec nautobot nautobot-server shell")

def backup():
    """Create backup of databases and media files"""
    print("💾 Creating backup...")
    return run_command("./scripts/backup.sh")

def restore():
    """Restore from backup"""
    if len(sys.argv) < 3:
        print("Usage: python manage.py restore <backup_date>")
        return 1
    backup_date = sys.argv[2]
    print(f"📥 Restoring from backup {backup_date}...")
    return run_command(f"./scripts/restore.sh {backup_date}")

def main():
    """Main function"""
    parser = argparse.ArgumentParser(description='NetBox + Nautobot Stack Manager')
    parser.add_argument('command', help='Command to run')
    
    if len(sys.argv) < 2:
        print("Available commands:")
        print("  up                    - Start the stack")
        print("  down                  - Stop the stack")
        print("  restart               - Restart applications")
        print("  logs                  - Show logs")
        print("  status                - Show container status")
        print("  nb-create-superuser   - Create NetBox superuser")
        print("  nb-shell              - Open NetBox Django shell")
        print("  nb-collectstatic      - Collect NetBox static files")
        print("  na-create-superuser   - Create Nautobot superuser")
        print("  na-shell              - Open Nautobot Django shell")
        print("  backup                - Create backup")
        print("  restore <date>        - Restore from backup")
        return 1
    
    command = sys.argv[1]
    
    # Command mapping
    commands = {
        'up': up,
        'down': down,
        'restart': restart,
        'logs': logs,
        'status': status,
        'nb-create-superuser': nb_create_superuser,
        'nb-shell': nb_shell,
        'nb-collectstatic': nb_collectstatic,
        'na-create-superuser': na_create_superuser,
        'na-shell': na_shell,
        'backup': backup,
        'restore': restore,
    }
    
    if command not in commands:
        print(f"❌ Unknown command: {command}")
        return 1
    
    return commands[command]()

if __name__ == '__main__':
    sys.exit(main())
